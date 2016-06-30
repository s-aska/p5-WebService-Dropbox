use Amon2::Lite;
use WebService::Dropbox;
use JSON;

my $key    = $ENV{DROPBOX_APP_KEY};
my $secret = $ENV{DROPBOX_APP_SECRET};
my $box    = WebService::Dropbox->new({ key => $key, secret => $secret });

my $redirect_uri = 'http://localhost:5000/callback';

get '/' => sub {
    my ($c) = @_;

    my $url = $box->login($redirect_uri);

    return $c->redirect($url);
};

get '/callback' => sub {
    my ($c) = @_;

    my $code = $c->req->param('code');

    $box->auth($code, $redirect_uri);

    my $res = $box->account_info || { error => $box->error };

    return $c->render('index.tt', { res => encode_json($res) });
};

__PACKAGE__->to_app();

__DATA__

@@ index.tt
<!doctype html>
<html>
    <body>
        <h1>Hello</h1>
        [% res %]
    </body>
</html>
