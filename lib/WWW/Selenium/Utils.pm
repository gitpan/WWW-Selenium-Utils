package WWW::Selenium::Utils;

use 5.006;
use strict;
use warnings;
use Carp;
use File::Find;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(generate_suite);

our $VERSION = '0.04';

sub html_header;
sub html_footer;

sub generate_suite {
    my %opts = @_;

    my $testdir = $opts{test_dir} or croak("test_dir is mandatory!");
    croak("$testdir is not a directory!") unless -d $testdir;
    my $files = $opts{files} || test_files($testdir);
    my $verbose = $opts{verbose};

    my $suite = "$testdir/TestSuite.html";
    my $date = localtime;

    open(my $fh, ">$suite.tmp") or die "Can't open $suite.tmp: $!";
    print $fh html_header(title => "Test Suite",
                          text  => "Generated at $date",
                         );

    for (sort {$a cmp $b} @$files) {
        next if /(?:\.tmp|TestSuite\.html)$/;
        # skip html files that we have or will generate
        next if /(.+)\.html$/ and -e "$testdir/$1.wiki";

        my $f = $_;
        print "Adding row for $f\n" if $verbose;
        if (/\.wiki$/) {
            $f = wiki2html("$testdir/$f");
        }
        my $title = find_title("$testdir/$f");
        print $fh qq(\t<tr><td><a href="./$f">$title</a></td></tr>\n);
    }
    #print the footer
    print $fh html_footer();

    # save and rename into place
    close $fh or die "Can't close $suite.tmp: $!";
    rename "$suite.tmp", $suite or die "can't rename $suite.tmp $suite: $!";
    print "Created new $suite\n" if $verbose;
}

sub test_files {
    my $testdir = shift;

    my @tests;
    find(sub {
            my $n = $File::Find::name;
            return if -d $n;
            return unless m#(?:wiki|html)$#;
            $n =~ s#^.+/tests/##;
            push @tests, $n;
        }, $testdir);
    return \@tests;
}

sub wiki2html {
    my ($wiki, $verbose) = @_;
    (my $html = $wiki) =~ s#\.wiki$#.html#;

    open(my $in, $wiki) or die "Can't open $wiki: $!";
    my $title = <$in>;
    chomp $title;
    $title =~ s#^\|(.+)\|$#$1#;
    print "Generating html for ($title): $html\n" if $verbose;

    open(my $out, ">$html") or die "Can't open $html: $!";
    print $out html_header( title => $title );
    while(<$in>) {
        next if /^#/ or /^\s*$/;
        chomp;
        if (/^\s*\|(.+)\|\s*$/) {
            my ($cmd, $opt1, $opt2) = split /\|/, $1, 3;
            die "No command found! ($_)" unless $cmd;
            $opt1 ||= '&nbsp;';
            $opt2 ||= '&nbsp;';
            print $out "\n\t<tr><td>$cmd</td>"
                       . "\n\t<td>$opt1</td>"
                       . "\n\t<td>$opt2</td></tr>\n";
        }
        else {
            warn "Invalid line: $_\n";
        }
    }
    close $in or die "Can't close $wiki: $!";

    print $out html_footer();
    close $out or die "Can't write $html: $!";
    return $1 if $html =~ m#.+/tests/(.+)$#;
}

sub find_title {
    my $filename = shift;

    local $/;
    open(my $fh, $filename) or die "Can't open $filename: $!";
    my $contents = <$fh>;
    close $fh or die "Can't close $filename: $!";

    return $1 if $contents =~ m#<title>\s*(.+)\s*</title>#;
    return $1 if $filename =~ m#^.+/(.+)\.html$#;
    return $filename;
}

sub html_header {
    my %opts = @_;
    my $title = $opts{title} || 'Generic Title';
    my $text = $opts{text} || '';

    my $header = <<EOT;
<html>
  <head>
    <meta content="text/html; charset=ISO-8859-1"
          http-equiv="content-type">
    <title>$title</title>
  </head>
  <body>
    $text
    <table cellpadding="1" cellspacing="1" border="1">
      <tbody>
        <tr>
          <td rowspan="1" colspan="3">$title</td>
        </tr>
EOT
    return $header;
}

sub html_footer {
    return <<EOT;
      </tbody>
    </table>
  </body>
</html>
EOT
}


1;
__END__

=head1 NAME

WWW::Selenium::Utils - helper functions for working with Selenium

=head1 SYNOPSIS

  use WWW::Selenium::Utils qw(generate_suite);

  # convert .wiki files to .html and create TestSuite.html
  generate_suite( test_dir => "/var/www/selenium/tests",
                  quiet => 0,
                );

=head1 DESCRIPTION

This package contains utility functions for working with Selenium.

=head1 SUBROUTINES

=head2 generate_suite

C<generate_suite()> will convert all .wiki files in selenium/tests to .html,
and then create a TestSuite.html file that contains links to all the .html 
files.

The .wiki files are much easier to read and write.  The format of .wiki files
is like this:

  title
  | cmd | opt1 | opt2 |
  | cmd | opt1 |
  # comment

  # empty lines are ignored
  # comments are ignored too

=head1 DIAGNOSTICS

If you set the C<quiet> option to 0 when calling generate_suite, the function
will print lines detailing what it is doing.

=head1 DEPENDENCIES

Uses CGI.

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.
Please report problums to Luke Closs (cpan@5thplane.com).
Patches are welcome.

=head1 AUTHOR

Luke Closs (cpan@5thplane.com)

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2005 Luke Closs (cpan@5thplane.com).  All rights reserved.

This module is free software; you can redstribute it and/or
modify it under the same terms as Perl itself.  See L<perlartistic>.

This program is distributed in the hope that it will be useful, 
but WITHOUT ANY WARRANTY; without even the implied warranty of 
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

