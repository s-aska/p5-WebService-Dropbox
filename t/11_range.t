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

if (!$exists or $exists->{is_deleted}) {
    $dropbox->create_folder('make_test_folder') or die $dropbox->error;
    is $dropbox->code, 200, "create_folder success";
}

my $file_mark = decode_utf8('\'!"#$%&(=~|@`{}[]+*;,<>_?-^ 日本語.txt');

# files_put
my $fh_put = File::Temp->new;
$fh_put->print('test.test.test.');
$fh_put->flush;
$fh_put->seek(0, 0);
$dropbox->files_put('make_test_folder/' . $file_mark, $fh_put) or die $dropbox->error;
$fh_put->close;

# files
my $fh_get = File::Temp->new;
$dropbox->files('make_test_folder/' . $file_mark, $fh_get) or die $dropbox->error;
$fh_get->flush;
$fh_get->seek(0, 0);
is $fh_get->getline, 'test.test.test.', 'download success.';
$fh_get->close;

$fh_get = File::Temp->new;
$dropbox->files('make_test_folder/' . $file_mark, $fh_get, undef, { headers => ['Range' => 'bytes=10-14'] }) or die $dropbox->error;
$fh_get->flush;
$fh_get->seek(0, 0);
is $fh_get->getline, 'test.', 'download range success.';
$fh_get->close;

$dropbox->use_lwp;

$fh_get = File::Temp->new;
$dropbox->files('make_test_folder/' . $file_mark, $fh_get, undef, { headers => ['Range' => 'bytes=10-14'] }) or die $dropbox->error;
$fh_get->flush;
$fh_get->seek(0, 0);
is $fh_get->getline, 'test.', 'download range success.';
$fh_get->close;

done_testing();
