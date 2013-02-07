use strict;
use Data::Dumper;
use Encode;
use Test::More;
use File::Temp;
use IO::File;
use File::Basename qw(dirname);
use File::Spec;
use WebService::Dropbox;

if (!$ENV{'DROPBOX_APP_KEY'} or !$ENV{'DROPBOX_APP_SECRET'}) {
    plan skip_all => 'missing App Key or App Secret';
}

my $dropbox = WebService::Dropbox->new({
    key => $ENV{'DROPBOX_APP_KEY'},
    secret => $ENV{'DROPBOX_APP_SECRET'},
    env_proxy => 1,
});

if (!$ENV{'DROPBOX_ACCESS_TOKEN'} or !$ENV{'DROPBOX_ACCESS_SECRET'}) {
    my $url = $dropbox->login or die $dropbox->error;
    warn "Please Access URL and press Enter: $url";
    <STDIN>;
    $dropbox->auth or die $dropbox->error;
    warn "access_token: " . $dropbox->access_token;
    warn "access_secret: " . $dropbox->access_secret;
} else {
    $dropbox->access_token($ENV{'DROPBOX_ACCESS_TOKEN'});
    $dropbox->access_secret($ENV{'DROPBOX_ACCESS_SECRET'});
}

$dropbox->account_info or die $dropbox->error;

my $exists = $dropbox->metadata('make_test_folder');

my $exists2 = $dropbox->metadata('make_test_folder', { hash => $exists->{hash} });

ok !$exists2;
is $dropbox->code, 304;
