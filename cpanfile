requires 'ExtUtils::MakeMaker' => '6.17';
requires 'JSON' => '2.53';
requires 'Net::OAuth' => '0.28';
requires 'URI' => '1.60';

eval {
    require Furl::HTTP;
};if ($@) {
    requires 'LWP::UserAgent' => '6.04';
    requires 'LWP::Protocol::https' => '6.03';
} else {
    requires 'Furl' => '1.01';
    requires 'IO::Socket::SSL' => '1.77';
}
