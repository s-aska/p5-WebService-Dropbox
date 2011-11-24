use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'WebService-Dropbox',
    AUTHOR        => 'Shinichiro Aska <s.aska.org@gmail.com>',
    VERSION_FROM  => 'lib/WebService/Dropbox.pm',
    PREREQ_PM     => {
        'Furl' => '0.38',
        'Net::OAuth' => '0.27',
        'String::Random' => '0.22',
    },
    MIN_PERL_VERSION => '5.008001',
    (-d 'xt' and $ENV{AUTOMATED_TESTING} || $ENV{RELEASE_TESTING}) ? (
        test => {
            TESTS => 't/*.t xt/*.t',
        },
    ) : (),
);
