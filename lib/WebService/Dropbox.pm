package WebService::Dropbox;
use strict;
use warnings;
use Carp ();
use Fcntl qw(F_GETFL F_SETFL O_NONBLOCK SEEK_SET SEEK_END);
use JSON;
use Net::OAuth;
use String::Random qw(random_regex);
use URI;
use URI::Escape;

our $VERSION = '1.00';

my $request_token_url = 'https://api.dropbox.com/1/oauth/request_token';
my $access_token_url = 'https://api.dropbox.com/1/oauth/access_token';
my $authorize_url = 'https://www.dropbox.com/1/oauth/authorize';

__PACKAGE__->mk_accessors(qw/
    key
    secret
    request_token
    request_secret
    access_token
    access_secret
    root

    no_decode_json
    no_uri_escape
    error
    code
    request_url
    request_method
    timeout
/);

my $use_lwp;

sub import {
    eval {
        require Furl::HTTP;
    };if ($@) {
        require LWP::UserAgent;
        require HTTP::Request;
        $use_lwp++;
    }
}

sub new {
    my ($class, $args) = @_;
    
    bless {
        key            => $args->{key}            || '',
        secret         => $args->{secret}         || '',
        request_token  => $args->{request_token}  || '',
        request_secret => $args->{request_secret} || '',
        access_token   => $args->{access_token}   || '',
        access_secret  => $args->{access_secret}  || '',
        root           => $args->{root}           || 'dropbox',
        timeout        => $args->{timeout}        || 10,
        no_docode_json => $args->{no_docode_json} || 0,
        no_uri_escape  => $args->{no_uri_escape}  || 0
    }, $class;
}

sub login {
    my ($self, $callback_url) = @_;

    my $body = $self->api({
        method => 'POST',
        url  => $request_token_url
    }) or return;

    my $response = Net::OAuth->response('request token')->from_post_body($body);
    $self->request_token($response->token);
    $self->request_secret($response->token_secret);

    my $url = URI->new($authorize_url);
    $url->query_form(
        oauth_token => $response->token,
        oauth_callback => $callback_url
    );
    $url->as_string;
}

sub auth {
    my $self = shift;

    my $body = $self->api({
        method => 'POST',
        url  => $access_token_url
    }) or return;

    my $response = Net::OAuth->response('access token')->from_post_body($body);
    $self->access_token($response->token);
    $self->access_secret($response->token_secret);
}

sub account_info {
    my $self = shift;

    $self->api_json({
        url => 'https://api.dropbox.com/1/account/info'
    });
}

sub files {
    my ($self, $path, $output, $params, $opts) = @_;

    $opts ||= {};
    if (ref $output eq 'CODE') {
        $opts->{write_code} = $output; # code ref
    } elsif (ref $output) {
        $opts->{write_file} = $output; # file handle
    } else {
        open $opts->{write_file}, '>', $output; # file path
        Carp::croak("invalid output, output must be code ref or filehandle or filepath.")
            unless $opts->{write_file};
    }
    $self->api({
        url => $self->url('https://api-content.dropbox.com/1/files/' . $self->root, $path, $params),
        %$opts
    });

    return if $self->error;
    return 1;
}

sub files_put {
    my ($self, $path, $content, $params, $opts) = @_;

    $opts ||= {};
    $self->api_json({
        method => 'PUT',
        url => $self->url('https://api-content.dropbox.com/1/files_put/' . $self->root, $path, $params),
        content => $content,
        %$opts
    });
}

sub files_post {
    my ($self, $path, $content, $params, $opts) = @_;

    $opts ||= {};
    $self->api_json({
        method => 'POST',
        url => $self->url('https://api-content.dropbox.com/1/files/' . $self->root, $path, $params),
        content => $content,
        %$opts
    });
}

sub metadata {
    my ($self, $path, $params) = @_;

    $self->api_json({
        url => $self->url('https://api.dropbox.com/1/metadata/' . $self->root, $path, $params)
    });
}

sub revisions {
    my ($self, $path, $params) = @_;

    $self->api_json({
        url => $self->url('https://api.dropbox.com/1/revisions/' . $self->root, $path, $params)
    });
}

sub restore {
    my ($self, $path, $params) = @_;

    $self->api_json({
        method => 'POST',
        url => $self->url('https://api.dropbox.com/1/restore/' . $self->root, $path, $params)
    });
}

sub search {
    my ($self, $path, $params) = @_;

    $self->api_json({
        url => $self->url('https://api.dropbox.com/1/search/' . $self->root, $path, $params)
    });
}

sub shares {
    my ($self, $path, $params) = @_;

    $self->api_json({
        method => 'POST',
        url => $self->url('https://api.dropbox.com/1/shares/' . $self->root, $path, $params)
    });
}

sub media {
    my ($self, $path, $params) = @_;

    $self->api_json({
        method => 'POST',
        url => $self->url('https://api.dropbox.com/1/media/' . $self->root, $path, $params)
    });
}

sub thumbnails {
    my ($self, $path, $output, $params, $opts) = @_;

    $opts ||= {};
    if (ref $output eq 'CODE') {
        $opts->{write_code} = $output; # code ref
    } elsif (ref $output) {
        $opts->{write_file} = $output; # file handle
    } else {
        open $opts->{write_file}, '>', $output; # file path
        Carp::croak("invalid output, output must be code ref or filehandle or filepath.")
            unless $opts->{write_file};
    }
    $self->api({
        url => $self->url('https://api-content.dropbox.com/1/thumbnails/' . $self->root, $path, $params),
        %$opts
    });
    return if $self->error;
    return 1;
}

sub create_folder {
    my ($self, $path, $params) = @_;

    $params ||= {};
    $params->{root} ||= $self->root;
    $params->{path} = $self->path($path);

    $self->api_json({
        method => 'POST',
        url => $self->url('https://api.dropbox.com/1/fileops/create_folder', '', $params)
    });
}

sub copy {
    my ($self, $from_path, $to_path, $params) = @_;

    $params ||= {};
    $params->{root} ||= $self->root;
    $params->{from_path} = $self->path($from_path);
    $params->{to_path}   = $self->path($to_path);

    $self->api_json({
        method => 'POST',
        url => $self->url('https://api.dropbox.com/1/fileops/copy', '', $params)
    });
}

sub move {
    my ($self, $from_path, $to_path, $params) = @_;

    $params ||= {};
    $params->{root} ||= $self->root;
    $params->{from_path} = $self->path($from_path);
    $params->{to_path}   = $self->path($to_path);

    $self->api_json({
        method => 'POST',
        url => $self->url('https://api.dropbox.com/1/fileops/move', '', $params)
    });
}

sub delete {
    my ($self, $path, $params) = @_;

    $params ||= {};
    $params->{root} ||= $self->root;
    $params->{path} = $self->path($path);

    $self->api_json({
        method => 'POST',
        url => $self->url('https://api.dropbox.com/1/fileops/delete', '', $params)
    });
}

# private

sub api {
    my ($self, $args) = @_;

    $args->{method} ||= 'GET';
    $args->{url} = $self->oauth_request_url($args);
    $self->request_url($args->{url});
    $self->request_method($args->{method});

    return $self->api_lwp($args) if $use_lwp;

    my ($minor_version, $code, $msg, $headers, $body) = $self->furl->request(%$args);

    $self->code($code);
    if ($code != 200) {
        $self->error($body);
        return;
    } else {
        $self->error(undef);
    }

    return $body;
}

sub api_lwp {
    my ($self, $args) = @_;

    my $headers = [];
    if ($args->{write_file}) {
        $args->{write_code} = sub {
            my $buf = shift;
            $args->{write_file}->print($buf);
        };
    }
    if ($args->{content}) {
        my $buf;
        my $content = delete $args->{content};
        $args->{content} = sub {
            read($content, $buf, 1024);
            return $buf;
        };
        my $assert = sub {
            $_[0] or Carp::croak(
                "Failed to $_[1] for Content-Length: $!",
            );
        };
        $assert->(defined(my $cur_pos = tell($content)), 'tell');
        $assert->(seek($content, 0, SEEK_END),           'seek');
        $assert->(defined(my $end_pos = tell($content)), 'tell');
        $assert->(seek($content, $cur_pos, SEEK_SET),    'seek');
        my $content_length = $end_pos - $cur_pos;
        push @$headers, 'Content-Length' => $content_length;
    }
    my $req = HTTP::Request->new($args->{method}, $args->{url}, $headers, $args->{content});
    my $ua = LWP::UserAgent->new;
    $ua->timeout($self->timeout);
    my $res = $ua->request($req, $args->{write_code});
    $self->code($res->code);
    if ($res->is_success) {
        $self->error(undef);
    } else {
        $self->error($res->decoded_content);
    }
    return $res->decoded_content;
}

sub api_json {
    my ($self, $args) = @_;
    
    my $body = $self->api($args) or return;
    return $body if $self->no_decode_json;
    return decode_json($body);
}

sub oauth_request_url {
    my ($self, $args) = @_;

    Carp::croak("missing url.") unless $args->{url};
    Carp::croak("missing method.") unless $args->{method};

    my ($type, $token, $token_secret);
    if ($args->{url} eq $request_token_url) {
        $type = 'request token';
    } elsif ($args->{url} eq $access_token_url) {
        Carp::croak("missing request_token.") unless $self->request_token;
        Carp::croak("missing request_secret.") unless $self->request_secret;
        $type = 'access token';
        $token = $self->request_token;
        $token_secret = $self->request_secret;
    } else {
        Carp::croak("missing access_token, please `\$dropbox->auth;`.") unless $self->access_token;
        Carp::croak("missing access_secret, please `\$dropbox->auth;`.") unless $self->access_secret;
        $type = 'protected resource';
        $token = $self->access_token;
        $token_secret = $self->access_secret;
    }

    my $request = Net::OAuth->request($type)->new(
        consumer_key => $self->key,
        consumer_secret => $self->secret,
        request_url => $args->{url},
        request_method => uc($args->{method}),
        signature_method => 'HMAC-SHA1',
        timestamp => time,
        nonce => $self->nonce,
        token => $token,
        token_secret => $token_secret
    );
    $request->sign;
    $request->to_url;
}

sub furl {
    my $self = shift;
    unless ($self->{furl}) {
        $self->{furl} = Furl::HTTP->new(
            timeout => $self->timeout
        );
    }
    $self->{furl};
}

sub url {
    my ($self, $base, $path, $params) = @_;
    my $url = URI->new($base . $self->path($path));
    $url->query_form($params) if $params;
    $url->as_string;
}

sub path {
    my ($self, $path) = @_;
    return '' unless length $path;
    $path=~s|^/||;
    return '/' . $path if $self->no_uri_escape;
    return '/' . uri_escape_utf8($path, q{^a-zA-Z0-9_./-});
}

sub nonce { random_regex('\w{16}'); }

sub mk_accessors {
    my $package = shift;
    no strict 'refs';
    foreach my $field ( @_ ) {
        *{ $package . '::' . $field } = sub {
            return $_[0]->{ $field } if scalar( @_ ) == 1;
            return $_[0]->{ $field }  = scalar( @_ ) == 2 ? $_[1] : [ @_[1..$#_] ];
        };
    }
}

1;
__END__

=head1 NAME

WebService::Dropbox - Perl interface to Dropbox API

=head1 SYNOPSIS

    use WebService::Dropbox;

    my $dropbox = WebService::Dropbox->new({
        key => '...', # App Key
        secret => '...' # App Secret
    });

    # get access token
    if (!$access_token or !$access_secret) {
        my $url = $dropbox->login or die $dropbox->error;
        warn "Please Access URL and press Enter: $url";
        <STDIN>;
        $dropbox->auth or die $dropbox->error;
        warn "access_token: " . $dropbox->access_token;
        warn "access_secret: " . $dropbox->access_secret;
    } else {
        $dropbox->access_token($access_token);
        $dropbox->access_secret($access_secret);
    }

    my $info = $dropbox->account_info or die $dropbox->error;

    # download
    # https://www.dropbox.com/developers/reference/api#files
    my $fh_get = IO::File->new('some file', '>');
    $dropbox->files('make_test_folder/test.txt', $fh_get) or die $dropbox->error;
    $fh_get->close;

    # upload
    # https://www.dropbox.com/developers/reference/api#files_put
    my $fh_put = IO::File->new('some file');
    $dropbox->files_put('make_test_folder/test.txt', $fh_put) or die $dropbox->error;
    $fh_put->close;

    # filelist(metadata)
    # https://www.dropbox.com/developers/reference/api#metadata
    my $data = $dropbox->metadata('folder_a');

=head1 DESCRIPTION

WebService::Dropbox is Perl interface to Dropbox API

- Support Dropbox v1 REST API

- Support Furl (Fast!!!)

- Streaming IO (Low Memory)

- Default URI Escape (The specified path is utf8 decoded string)

=head1 API

=head2 login(callback_url) - get request token and request secret

    my $callback_url = '...'; # optional
    my $url = $dropbox->login($callback_url) or die $dropbox->error;
    warn "Please Access URL and press Enter: $url";

=head2 auth - get access token and access secret

    $dropbox->auth or die $dropbox->error;
    warn "access_token: " . $dropbox->access_token;
    warn "access_secret: " . $dropbox->access_secret;

=head2 account_info

    my $info = $dropbox->account_info or die $dropbox->error;

    # {
    #     "referral_link": "https://www.dropbox.com/referrals/r1a2n3d4m5s6t7",
    #     "display_name": "John P. User",
    #     "uid": 12345678,
    #     "country": "US",
    #     "quota_info": {
    #         "shared": 253738410565,
    #         "quota": 107374182400000,
    #         "normal": 680031877871
    #     },
    #     "email": "john@example.com"
    # }

L<https://www.dropbox.com/developers/reference/api#account-info>

=head2 files(path, output, [params]) - download (no file list, file list is metadata)

    # Current Rev
    my $fh_get = IO::File->new('some file', '>');
    $dropbox->files('folder/file.txt', $fh_get) or die $dropbox->error;
    $fh_get->close;

    # Specified Rev
    $dropbox->files('folder/file.txt', $fh_get, { rev => ... }) or die $dropbox->error;

    # output is fh or code ref.

L<https://www.dropbox.com/developers/reference/api#files-GET>

=head2 files_put(path, input) - upload

    my $fh_put = IO::File->new('some file');
    $dropbox->files_put('folder/test.txt', $fh_put) or die $dropbox->error;
    $fh_put->close;

    # no overwrite (default true)
    $dropbox->files_put('folder/test.txt', $fh_put, { overwrite => 0 }) or die $dropbox->error;
    # create 'folder/test (1).txt'
    
    # Specified Parent Rev
    $dropbox->files_put('folder/test.txt', $fh_put, { parent_rev => ... }) or die $dropbox->error;
    # conflict prevention

L<https://www.dropbox.com/developers/reference/api#files_put>

=head2 copy(from_path, to_path)

    $dropbox->copy('folder/test.txt', 'folder/test_copy.txt') or die $dropbox->error;

L<https://www.dropbox.com/developers/reference/api#fileops-copy>

=head2 move(from_path, to_path)

    $dropbox->move('folder/test.txt', 'folder/test_move.txt') or die $dropbox->error;

L<https://www.dropbox.com/developers/reference/api#fileops-move>

=head2 delete(path)

    # folder delete
    $dropbox->delete('folder') or die $dropbox->error;

    # file delete
    $dropbox->delete('folder/test.txt') or die $dropbox->error;

L<https://www.dropbox.com/developers/reference/api#fileops-delete>

=head2 create_folder(path)

    $dropbox->create_folder('some_folder') or die $dropbox->error;

L<https://www.dropbox.com/developers/reference/api#fileops-create-folder>

=head2 metadata(path, [params]) - get file list

    my $data = $dropbox->metadata('some_folder') or die $dropbox->error;

    my $data = $dropbox->metadata('some_file') or die $dropbox->error;

    # 304
    my $data = $dropbox->metadata('some_folder', { hash => ... });
    return if $dropbox->code == 304; # not modified
    die $dropbox->error if $dropbox->error;
    return $data;

L<https://www.dropbox.com/developers/reference/api#metadata>

=head2 revisions(path, [params])

    my $data = $dropbox->revisions('some_file') or die $dropbox->error;

L<https://www.dropbox.com/developers/reference/api#revisions>

=head2 restore(path, [params])

    # params rev is Required
    my $data = $dropbox->restore('some_file', { rev => $rev }) or die $dropbox->error;

L<https://www.dropbox.com/developers/reference/api#restore>

=head2 search(path, [params])

    # query rev is Required
    my $data = $dropbox->search('some_file', { query => $query }) or die $dropbox->error;

L<https://www.dropbox.com/developers/reference/api#search>

=head2 shares(path, [params])

    my $data = $dropbox->shares('some_file') or die $dropbox->error;

L<https://www.dropbox.com/developers/reference/api#shares>

=head2 media(path, [params])

    my $data = $dropbox->media('some_file') or die $dropbox->error;

L<https://www.dropbox.com/developers/reference/api#media>

=head2 thumbnails(path, output)

    my $fh_get = File::Temp->new;
    $dropbox->thumbnails('folder/file.txt', $fh_get) or die $dropbox->error;
    $fh_get->flush;
    $fh_get->seek(0, 0);

L<https://www.dropbox.com/developers/reference/api#thumbnails>

=head1 AUTHOR

Shinichiro Aska

=head1 SEE ALSO

- L<https://www.dropbox.com/developers/reference/api>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
