use strict;
use warnings;

use WebService::Dropbox::TokenFromOAuth1;

my $key = shift;
my $secret = shift;
my $access_token = shift;
my $access_secret = shift;

my $oauth2_access_token = WebService::Dropbox::TokenFromOAuth1->token_from_oauth1({
    consumer_key    => $key,
    consumer_secret => $secret,
    access_token    => $access_token,  # OAuth1 access_token
    access_secret   => $access_secret, # OAuth2 access_secret
});

warn $oauth2_access_token;
