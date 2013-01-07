use strict;
use Data::Dumper;
use Encode;
use Test::More;
use File::Temp;
use IO::File;
use File::Basename qw(dirname);
use File::Spec;
use WebService::Dropbox;

my $dropbox = WebService::Dropbox->new();

is $dropbox->{env_proxy}, 0;

$dropbox->lwp_env_proxy(1);

is $dropbox->{env_proxy}, 1;

$dropbox->lwp_env_proxy(0);

is $dropbox->{env_proxy}, 0;

$dropbox->env_proxy;

is $dropbox->{env_proxy}, 1;

$dropbox->env_proxy(0);

is $dropbox->{env_proxy}, 0;

$dropbox = WebService::Dropbox->new({ lwp_env_proxy => 1 });

is $dropbox->{env_proxy}, 1;

$dropbox = WebService::Dropbox->new({ env_proxy => 1 });

is $dropbox->{env_proxy}, 1;

done_testing();
