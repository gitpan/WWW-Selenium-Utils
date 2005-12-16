package t::Regen;
use strict;
use warnings;
use base 'Exporter';
our @EXPORT_OK = qw(test_setup);
use File::Path;

sub test_setup {
    my $kind = shift || '';
    my $testdir = "t/tests";
    !-d $testdir or rmtree $testdir or die "Can't rmtree $testdir: $!";
    mkpath $testdir or die "Can't mkpath $testdir: $!";
    open(my $fh, ">$testdir/foo.wiki") or die "Can't open $testdir/foo.wiki: $!";
    my $invalid = '';
    $invalid = "nintendo | sony | xbox |" if $kind eq 'invalid line';
    print $fh <<EOT;
    some title
    | open | /foo |
    | verifyText | id=foo | bar |
# comment
$invalid
# next line has spaces at the end
    | verifyLocation | /bar |   
EOT
    close $fh or die "Can't write $testdir/foo.wiki: $!";

    if ($kind eq "with orphan") {
        open($fh, ">$testdir/orphan.html") or 
            die "Can't open $testdir/orphan.html: $!";
        print $fh "Auto-generated from $testdir/orphan.wiki at 23";
        close $fh or die "Can't write $testdir/orphan.wiki: $!";
    }

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

1;
