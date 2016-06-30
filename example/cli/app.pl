use WebService::Dropbox;

my $key          = $ENV{DROPBOX_APP_KEY};
my $secret       = $ENV{DROPBOX_APP_SECRET};
my $access_token = $ENV{DROPBOX_ACCESS_TOKEN};

my $box = WebService::Dropbox->new({
    key    => $key,
    secret => $secret,
});

$box->debug;

if ($access_token) {
    $box->access_token($access_token);
} else {
    my $url = $box->login;

    print $url, "\n";
    print "Please Input Code: ";

    chomp( my $code = <STDIN> );

    unless ($box->auth($code)) {
        die $box->error;
    }
}

my $res = $box->account_info;
unless ($res) {
    die $box->error;
}

use Data::Dumper;
warn Dumper($res);

{
    my $res = $box->files('/aerith.json', './aerith.json');
    warn Dumper($res);
}

{
    open(my $fh, '<', './aerith.json');
    my $res = $box->files_put_chunked('/aerith-test.json', $fh, { commit => { mode => 'overwrite' } }, undef, 10000);
    warn Dumper($res);
}

