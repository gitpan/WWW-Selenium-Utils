#!perl
use warnings;
use strict;
use Test::More;
use lib "lib";
use WWW::Selenium::Utils qw(generate_suite);
use t::Regen qw(test_setup);

BEGIN {
    eval "use Test::Warn";
    plan skip_all => "Test::Warn required to test warn" if $@;
    plan tests => 1;
}

Invalid_line: {
    my $testdir = test_setup("invalid line");
    warning_like {generate_suite(test_dir => $testdir)}
                 qr#Invalid line \(5\) in file t/tests/foo\.wiki: nintendo#;
}
