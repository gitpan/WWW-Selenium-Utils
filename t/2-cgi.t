#!/usr/bin/perl
use warnings;
use strict;
use Test::More qw(no_plan);
use lib "lib";
use WWW::Selenium::Utils::CGI qw(run cat);
use CGI;
use Cwd;

# cat tests
my $page = cat(MockCGI->new());
like $page, qr#Error!#, 'cat with no args';
like $page, qr#file is a mandatory#;

my $testfile = getcwd() . "/t/foo.conf";
open(my $fh, ">$testfile") or die "Can't open $testfile: $!";
print $fh "monkey poo\n";
close $fh or die "Can't write $testfile: $!";

$page = cat(MockCGI->new( file => $testfile ));
like $page, qr#Contents of $testfile#, 'cat with absolute args';
like $page, qr#<pre>monkey poo#;

$page = cat(MockCGI->new( file => $testfile, raw => 1 ));
like $page, qr#monkey poo#, 'raw cat';
unlike $page, qr#<pre>monkey#;


# run tests
$page = run(MockCGI->new());
like $page, qr#Error!#, 'run with no args';
like $page, qr#cmd is a mandatory#;

$page = run(MockCGI->new( cmd => "perl -e 'print q(Monkey)'" ));
like $page, qr#Output of "perl#, 'running a command';
like $page, qr#<pre>Monkey#;



package MockCGI;

sub new {
    my $class = shift;
    my %args = @_;
    my $self = \%args;
    bless $self, $class;
    return $self;
}

sub param { $_[0]->{$_[1]} }

1;
