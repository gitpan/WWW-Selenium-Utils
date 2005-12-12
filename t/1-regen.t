#!/usr/bin/perl
use Test::More qw(no_plan);
use Test::Exception;
use File::Path;
use lib "lib";
use WWW::Selenium::Utils qw(generate_suite);
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

sub gen_suite {
    my @opts = @_;
    lives_ok { generate_suite( @opts ) };
}


sub test_setup {
    my $testdir = "t/tests";
    !-d $testdir or rmtree $testdir or die "Can't rmtree $testdir: $!";
    mkpath $testdir or die "Can't mkpath $testdir: $!";
    open(my $fh, ">$testdir/foo.wiki") or die "Can't open $testdir/foo.wiki: $!";
    print $fh <<EOT;
    some title
    | open | /foo |
    | verifyText | id=foo | bar |
# comment

# next line has spaces at the end
    | verifyLocation | /bar |   
EOT
    close $fh or die "Can't write $testdir/foo.wiki: $!";

    open($fh, ">$testdir/bar.html") or die "Can't open $testdir/bar.html: $!";
    print $fh <<EOT;
    <html>
      <body>
        <table>
          <tr>
            <td>Test title</td>
          </tr>
          <tr>
            <td>open</td><td>/foo</td><td></td>
          </tr>
        </table>
      </body>
    </html>
EOT
    close $fh or die "Can't write $testdir/bar.html: $!";
    return $testdir;
}

sub cat {
    my $file = shift;
    my $contents;
    eval {
        open(my $fh, $file) or die "Can't open $file: $!";
        { 
            local $/;
            $contents = <$fh>;
        }
        close $fh or die "Can't close $file: $!";
    };
    warn if $@;
    return $contents;
}

