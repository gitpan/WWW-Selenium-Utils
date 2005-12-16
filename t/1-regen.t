#!/usr/bin/perl
use Test::More qw(no_plan);
use Test::Exception;
use File::Path;
use t::Regen qw(test_setup);
use lib "lib";
use WWW::Selenium::Utils qw(generate_suite cat);
use Cwd qw(getcwd);
use Data::Dumper;

my $verbose = 1;

Basic_generation: {
    my $testdir = test_setup();
    gen_suite( test_dir => $testdir, verbose => $verbose );
    ok -e "$testdir/TestSuite.html", "TestSuite created";
    ok -e "$testdir/foo.html", "foo.wiki converted to html";
    my $suite = cat("$testdir/TestSuite.html");
    like $suite, qr#>bar</a>#, "link is from filename";
    like $suite, qr#foo\.html#, "suite contains link to foo.html";
    like $suite, qr#>some title</a>#, "link is from wiki title";
    like $suite, qr#bar\.html#, "suite contains link to bar.html";
    my $foo = cat("$testdir/foo.html");
    like $foo, qr#<title>some title</title>#, 'proper title';
    like $foo, qr#<b>Auto-generated from $testdir/foo\.wiki</b>#;
    like $foo, qr#<hr />Auto-generated from $testdir/foo\.wiki at #;
    like $foo, qr#open#;
    like $foo, qr#<td>/foo</td>#;
    like $foo, qr#verifyText#;
    like $foo, qr#verifyLocation#;
    like $foo, qr#<td>/bar</td>#;
    like $foo, qr#<td>&nbsp;</td></tr>#, '&nbsp in empty cell';
    unlink $foo, qr#comment#, 'comment was stripped out';
}

Generate_with_path: {
    my $testdir = test_setup();
    gen_suite( test_dir => $testdir, verbose => $verbose,
               base_href => "/peanut_butter/" );
    my $foo = cat("$testdir/foo.html");
    like $foo, qr#<title>some title</title>#, 'proper title';
    like $foo, qr#<td>/peanut_butter/foo</td>#;
    like $foo, qr#<td>/peanut_butter/bar</td>#;
}

Generate_from_cwd: {
    my $testdir = test_setup();
    my $cwd = getcwd;
    chdir $testdir or die "Can't chdir $testdir: $!";
    gen_suite( test_dir => '.', verbose => $verbose );
    my $suite = cat("./TestSuite.html");
    like $suite, qr#a href="\./foo\.html">some title<#, ;
    like $suite, qr#a href="\./bar\.html">bar<#, ;
    chdir $cwd;
}

Orphaned: {
    my $testdir = test_setup("with orphan");
    ok -e "$testdir/orphan.html";
    gen_suite( test_dir => $testdir);
    ok !-e "$testdir/orphan.html";
    ok -e "$testdir/bar.html";
}
 
sub gen_suite {
    my @opts = @_;
    lives_ok { generate_suite( @opts ) };
}


