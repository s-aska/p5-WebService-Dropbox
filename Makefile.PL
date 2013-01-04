use ExtUtils::MakeMaker;

my %http_module = (Furl => '1.01');
eval {
    require Furl::HTTP;
};if ($@) {
    %http_module = (
        'LWP::UserAgent' => '6.04',
        'LWP::Protocol::https' => '6.03'
    );
} else {
    $http_module{'IO::Socket::SSL'} = '1.77';
}

WriteMakefile(
    NAME          => 'WebService-Dropbox',
    AUTHOR        => 'Shinichiro Aska <s.aska.org@gmail.com>',
    VERSION_FROM  => 'lib/WebService/Dropbox.pm',
    PREREQ_PM     => {
        %http_module,
        'JSON' => '2.53',
        'Net::OAuth' => '0.28',
        'URI' => '1.60',
    },
    MIN_PERL_VERSION => '5.008001'
);
