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
    secret => $ENV{'DROPBOX_APP_SECRET'}
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

if ($exists and !$exists->{is_deleted}) {
    $dropbox->delete('make_test_folder') or die $dropbox->error;
    is $dropbox->code, 200, "delete make_test_folder";
}

$dropbox->create_folder('make_test_folder') or die $dropbox->error;
is $dropbox->code, 200, "create_folder success";

$dropbox->create_folder('make_test_folder');
is $dropbox->code, 403, "create_folder error already exists.";

my $fh_put = File::Temp->new;
$fh_put->print('test.');
$fh_put->flush;
$fh_put->seek(0, 0);
$dropbox->files_put('make_test_folder/test.txt', $fh_put) or die $dropbox->error;
$fh_put->close;
is $dropbox->code, 200, 'upload success.';

my $fh_get = File::Temp->new;
$dropbox->files('make_test_folder/test.txt', $fh_get) or die $dropbox->error;
$fh_get->flush;
$fh_get->seek(0, 0);
is $fh_get->getline, 'test.', 'download success.';
$fh_get->close;

$fh_put = File::Temp->new;
$fh_put->print('test2.');
$fh_put->flush;
$fh_put->seek(0, 0);
$dropbox->files_put('make_test_folder/test.txt', $fh_put) or die $dropbox->error;
$fh_put->close;

$exists = $dropbox->metadata('make_test_folder/test (1).txt');

if (!$exists or $exists->{is_deleted}) {
    pass "upload overwrite";
}

$fh_get = File::Temp->new;
$dropbox->files('make_test_folder/test.txt', $fh_get) or die $dropbox->error;
$fh_get->flush;
$fh_get->seek(0, 0);
is $fh_get->getline, 'test2.', 'download success.';
$fh_get->close;

$fh_put = File::Temp->new;
$fh_put->print('test3.');
$fh_put->flush;
$fh_put->seek(0, 0);
$dropbox->files_put('make_test_folder/test.txt', $fh_put, { overwrite => 0 })
    or die $dropbox->error;
$fh_put->close;

$exists = $dropbox->metadata('make_test_folder/test (1).txt');

if ($exists and !$exists->{is_deleted}) {
    pass "upload no overwrite";
}

my $metadata = $dropbox->metadata('make_test_folder/test.txt')
    or die $dropbox->error;

my $delta = $dropbox->delta()
    or die $dropbox->error;

my $revisions = $dropbox->revisions('make_test_folder/test.txt')
    or die $dropbox->error;

my $restore = $dropbox->restore('make_test_folder/test.txt', { rev => $revisions->[1]->{rev} })
    or die $dropbox->error;

$fh_get = File::Temp->new;
$dropbox->files('make_test_folder/test.txt', $fh_get) or die $dropbox->error;
$fh_get->flush;
$fh_get->seek(0, 0);
is $fh_get->getline, 'test.', 'restore success.';
$fh_get->close;

my $search = $dropbox->search('make_test_folder/', { query => 'test' })
    or die $dropbox->error;
is scalar(@$search), 2, 'search';


my $shares = $dropbox->shares('make_test_folder/test.txt')
    or die $dropbox->error;

ok $shares->{url}, "shares";

my $media = $dropbox->media('make_test_folder/test.txt')
    or die $dropbox->error;

ok $shares->{url}, "media";

$fh_put = IO::File->new(File::Spec->catfile(dirname(__FILE__), 'sample.png'));
$dropbox->files_put('make_test_folder/sample.png', $fh_put) or die $dropbox->error;
$fh_put->close;

$fh_get = File::Temp->new;
$dropbox->thumbnails('make_test_folder/sample.png', $fh_get) or die $dropbox->error;
$fh_get->flush;
$fh_get->seek(0, 0);
ok -s $fh_get, 'thumbnails.';
$fh_get->close;

my $copy = $dropbox->copy('make_test_folder/test.txt', 'make_test_folder/test2.txt')
    or die $dropbox->error;

$exists = $dropbox->metadata('make_test_folder/test2.txt');

if ($exists and !$exists->{is_deleted}) {
    pass "copy.";
}

my $move = $dropbox->move('make_test_folder/test2.txt', 'make_test_folder/test2b.txt')
    or die $dropbox->error;

$exists = $dropbox->metadata('make_test_folder/test2b.txt');

if ($exists and !$exists->{is_deleted}) {
    pass "move.";
}

my $file_mark = '\'!"#$%&(=~|@`{}[]+*;,<>_?-^.txt';

$fh_put = File::Temp->new;
$fh_put->print('test4.');
$fh_put->flush;
$fh_put->seek(0, 0);
$dropbox->files_put('make_test_folder/' . $file_mark, $fh_put)
    or die $dropbox->error;
$fh_put->close;

$exists = $dropbox->metadata('make_test_folder/' . $file_mark);

if ($exists and !$exists->{is_deleted}) {
    pass "mark.";
}

my $file_utf8 = decode_utf8('日本語.txt');

$fh_put = File::Temp->new;
$fh_put->print('test5.');
$fh_put->flush;
$fh_put->seek(0, 0);
$dropbox->files_put('make_test_folder/' . $file_utf8, $fh_put)
    or die $dropbox->error;
$fh_put->close;

$exists = $dropbox->metadata('make_test_folder/' . $file_utf8);

if ($exists and !$exists->{is_deleted}) {
    pass "utf8.";
}

done_testing();
