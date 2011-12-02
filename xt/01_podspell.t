use Test::More;
use Config;
use File::Spec;
use ExtUtils::MakeMaker;
eval q{ use Test::Spelling };
plan skip_all => "Test::Spelling is not installed." if $@;
my %cmd_map = (
    spell    => 'spell',
    aspell   => 'aspell list -l en',
    ispell   => 'ispell -l',
    hunspell => 'hunspell -d en_US -l',
);
my $spell_cmd;
for my $dir ((split /$Config::Config{path_sep}/, $ENV{PATH}), '.') {
    next if $dir eq '';
    ($spell_cmd) = map { $cmd_map{$_} } grep {
        my $abs = File::Spec->catfile($dir, $_);
        -x $abs or MM->maybe_command($abs);
    } keys %cmd_map;
    last if $spell_cmd;
}
$spell_cmd = $ENV{SPELL_CMD} if $ENV{SPELL_CMD};
plan skip_all => "spell command are not available." unless $spell_cmd;
set_spell_cmd($spell_cmd);
add_stopwords(map { split /[\s\:\-]/ } <DATA>);
$ENV{LANG} = 'C';
all_pod_files_spelling_ok('lib');
__DATA__
Shinichiro Aska
s.aska.org {at} gmail.com
WebService::Dropbox
API
URI
auth
metadata
params
utf