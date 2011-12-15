use ExtUtils::MakeMaker;

my %http_module = (Furl => '0.38');
eval {
    require Furl::HTTP;
};if ($@) {
    %http_module = (
        'LWP::UserAgent' => '6.02',
        'LWP::Protocol::https' => '6.02'
    );
}

WriteMakefile(
    NAME          => 'WebService-Dropbox',
    AUTHOR        => 'Shinichiro Aska <s.aska.org@gmail.com>',
    VERSION_FROM  => 'lib/WebService/Dropbox.pm',
    PREREQ_PM     => {
        %http_module,
        'JSON' => '0',
        'Net::OAuth' => '0.27',
        'String::Random' => '0.22',
    },
    MIN_PERL_VERSION => '5.008001'
);
