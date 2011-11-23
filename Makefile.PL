use inc::Module::Install;
name 'WebService-Dropbox';
all_from 'lib/WebService/Dropbox.pm';
githubmeta;

# requires '';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
