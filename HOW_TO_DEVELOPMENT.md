
## 開発環境を作る

```sh
brew install plenv perl-build
echo 'if which plenv > /dev/null; then eval "$(plenv init - zsh)"; fi' >> ~/.zshrc
eval "$(plenv init - zsh)"
plenv rehash
plenv install -l
plenv install 5.24.0
plenv global 5.24.0
plenv rehash
plenv install-cpanm
cpanm carton
carton install
```

## バージョン番号の更新

lib/WebService/Dropbox.pm

```perl
our $VERSION = '2.00';
```

## README.md の更新

echo '[![Build Status](https://travis-ci.org/s-aska/p5-WebService-Dropbox.png?branch=master)](https://travis-ci.org/s-aska/p5-WebService-Dropbox)' > README_.md
perl -MPod::Markdown -e 'Pod::Markdown->new->filter(@ARGV)' lib/WebService/Dropbox.pm >> README_.md

## Test

```sh
carton exec -- prove -I lib t
```

## Release

```sh
$EDITOR ~/.pause
minil release --no-test
```
