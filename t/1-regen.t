#!/usr/bin/perl
use Test::More qw(no_plan);
use File::Path;
use lib "lib";
use WWW::Selenium::Utils qw(generate_suite);

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
| verifyLocation | /foo |   
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


generate_suite( test_dir => $testdir );
ok -e "$testdir/TestSuite.html", "TestSuite created";
ok -e "$testdir/foo.html", "foo.wiki converted to html";
my $suite = cat("$testdir/TestSuite.html");
like $suite, qr#>bar</a>#, "link is from filename";
like $suite, qr#foo\.html#, "suite contains link to foo.html";
like $suite, qr#>some title</a>#, "link is from wiki title";
like $suite, qr#bar\.html#, "suite contains link to bar.html";
my $foo = cat("$testdir/foo.html");
like $foo, qr#open#;
like $foo, qr#verifyText#;
like $foo, qr#verifyLocation#;
like $foo, qr#<td>&nbsp;</td></tr>#, '&nbsp in empty cell';
unlink $foo, qr#comment#, 'comment was stripped out';

sub cat {
    my $file = shift;
    my $contents;
    open(my $fh, $file) or die "Can't open $file: $!";
    { 
        $/ = undef;
        $contents = <$fh>;
    }
    close $fh or die "Can't close $file: $!";
    return $contents;
}

