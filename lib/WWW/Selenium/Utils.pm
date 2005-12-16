package WWW::Selenium::Utils;

use 5.006;
use strict;
use warnings;
use Carp;
use File::Find;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(generate_suite cat);

our $VERSION = '0.06';

sub html_header;
sub html_footer;

sub generate_suite {
    my %opts = @_;

    my $testdir = $opts{test_dir} or croak("test_dir is mandatory!");
    croak("$testdir is not a directory!") unless -d $testdir;
    $testdir =~ s#/$##;
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

        my $f = $_;
        my $fp = "$testdir/$f";
        if ($f =~ /(.+)\.html$/) {
            my $basename = $1;
            # skip html files that we have or will generate
            next if -e "$testdir/$basename.wiki";
            # find orphaned html files
            my $html = cat($fp);
            if ($html =~ m#Auto-generated from $testdir/$basename\.wiki# and 
                        !-e "$testdir/$basename.wiki") {
                print "Deleting orphaned file $fp\n" if $verbose;
                unlink $fp or die "Can't unlink $fp: $!";
                next;
            }
        }

        print "Adding row for $f\n" if $verbose;
        if (/\.wiki$/) {
            $f = wiki2html($fp, 
                           verbose => $verbose,
                           base_href => $opts{base_href});
            $f =~ s/^$testdir\///;
            $fp = "$testdir/$f";
        }
        my $title = find_title($fp);
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
            $n =~ s#^$testdir/?##;
            $n =~ s#^.+/tests/##;
            push @tests, $n;
        }, $testdir);
    return \@tests;
}

sub wiki2html {
    my ($wiki, %opts) = @_;
    my $verbose = $opts{verbose};
    my $base_href = $opts{base_href};
    $base_href =~ s#/$## if $base_href;

    (my $html = $wiki) =~ s#\.wiki$#.html#;

    open(my $in, $wiki) or die "Can't open $wiki: $!";
    my $title = <$in>;
    chomp $title;
    $title =~ s#^\s*##;
    $title =~ s#^\|(.+)\|$#$1#;
    print "Generating html for ($title): $html\n" if $verbose;

    open(my $out, ">$html") or die "Can't open $html: $!";
    my $now = localtime;
    print $out html_header( title => $title,
                            text => "<b>Auto-generated from $wiki</b><br />");
    while(<$in>) {
        s/^\s*//;
        next if /^#/ or /^\s*$/;
        chomp;
        if (/^\s*\|\s*(.+?)\s*\|\s*$/) {
            my ($cmd, $opt1, $opt2) = split /\s*\|\s*/, $1, 3;
            die "No command found! ($_)" unless $cmd;
            $opt1 ||= '&nbsp;';
            $opt2 ||= '&nbsp;';
            if ($base_href and ($cmd eq "open" or 
                                $cmd =~ /(?:assert|verify)Location/)) {
                $opt1 =~ s#^/##;
                $opt1 = "$base_href/$opt1";
            }
            print $out "\n\t<tr><td>$cmd</td>"
                       . "\n\t<td>$opt1</td>"
                       . "\n\t<td>$opt2</td></tr>\n";
        }
        else {
            warn "Invalid line ($.) in file $wiki: $_\n";
        }
    }
    close $in or die "Can't close $wiki: $!";

    print $out html_footer("<hr />Auto-generated from $wiki at $now\n");
    close $out or die "Can't write $html: $!";
    return $html;
}

sub find_title {
    my $filename = shift;

    open(my $fh, $filename) or die "Can't open $filename: $!";
    my $contents;
    { 
        local $/;
        $contents = <$fh>;
    }
    close $fh or die "Can't close $filename: $!";

    return $filename unless $contents;
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
    my $text = shift || '';
    return <<EOT;
      </tbody>
    </table>
    $text
  </body>
</html>
EOT
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


1;
__END__

=head1 NAME

WWW::Selenium::Utils - helper functions for working with Selenium

=head1 SYNOPSIS

  use WWW::Selenium::Utils qw(generate_suite);

  # convert .wiki files to .html and create TestSuite.html
  generate_suite( test_dir => "/var/www/selenium/tests",
                  base_href => "/monkey",
                  verbose => 1,
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

Parameters:

=over 4

=item test_dir

The path to the 'tests' directory inside selenium.

=item verbose

If true, informative messages will be printed.

=item base_href

Will prepend the given location to all locations for the
open and assert/verifyLocation commands.

=back

=head1 DIAGNOSTICS

If you set the C<verbose> option to 1 when calling generate_suite, the function
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

