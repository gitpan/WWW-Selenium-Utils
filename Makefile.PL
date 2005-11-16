use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME		=> 'WWW::Selenium::Utils',
    VERSION_FROM	=> 'lib/WWW/Selenium/Utils.pm', # finds $VERSION
    PREREQ_PM		=> {}, 
    ABSTRACT            => 'Handy utilities for working with Selenium',
    AUTHOR              => 'Luke Closs <cpan@5thplane.com>',
    clean               => { FILES => 't/foo.conf t/selenium' }, 
);
