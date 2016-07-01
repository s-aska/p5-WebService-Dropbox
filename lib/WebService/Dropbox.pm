package WebService::Dropbox;
use strict;
use warnings;
use Carp ();
use Fcntl qw(F_GETFL F_SETFL O_NONBLOCK SEEK_SET SEEK_END);
use JSON;
use URI;
use File::Temp;
use WebService::Dropbox::Auth;
use WebService::Dropbox::Files;
use WebService::Dropbox::Files::UploadSession;
use WebService::Dropbox::Users;

our $VERSION = '2.00';

__PACKAGE__->mk_accessors(qw/
    timeout
    key
    secret
    access_token

    error
    req
    res
/);

$WebService::Dropbox::USE_LWP = 0;
$WebService::Dropbox::DEBUG = 0;
$WebService::Dropbox::VERBOSE = 0;

my $JSON = JSON->new;
my $JSON_PRETTY = JSON->new->pretty->utf8->canonical;

sub import {
    eval {
        require Furl;
        require IO::Socket::SSL;
    };if ($@) {
        __PACKAGE__->use_lwp;
    }
}

sub use_lwp {
    require LWP::UserAgent;
    require HTTP::Request;
    require HTTP::Request::Common;
    $WebService::Dropbox::USE_LWP++;
}

sub debug {
    if (@_) {
        $WebService::Dropbox::DEBUG = $_[0];
    } else {
        $WebService::Dropbox::DEBUG = 1;
    }
}

sub verbose {
    if (@_) {
        $WebService::Dropbox::VERBOSE = $_[0];
    } else {
        $WebService::Dropbox::VERBOSE = 1;
    }
}

sub new {
    my ($class, $args) = @_;

    bless {
        timeout      => $args->{timeout}        || 86400,
        key          => $args->{key}            || '',
        secret       => $args->{secret}         || '',
        access_token => $args->{access_token}   || '',
        env_proxy    => $args->{env_proxy}      || 0,
    }, $class;
}








# sub metadata {
#     my ($self, $path, $params) = @_;

#     $self->api({
#         url => $self->url('https://api.dropbox.com/1/metadata/' . $self->root, $path),
#         extra_params => $params
#     });
# }

# sub delta {
#     my ($self, $params) = @_;

#     $self->api({
#         url => $self->url('https://api.dropbox.com/1/delta', ''),
#         extra_params => $params
#     });
# }

# sub revisions {
#     my ($self, $path, $params) = @_;

#     $self->api({
#         url => $self->url('https://api.dropbox.com/1/revisions/' . $self->root, $path),
#         extra_params => $params
#     });
# }

# sub restore {
#     my ($self, $path, $params) = @_;

#     $self->api({
#         url => $self->url('https://api.dropbox.com/1/restore/' . $self->root, $path),
#         extra_params => $params
#     });
# }

# sub search {
#     my ($self, $path, $params) = @_;

#     $self->api({
#         url => $self->url('https://api.dropbox.com/1/search/' . $self->root, $path),
#         extra_params => $params
#     });
# }

# sub shares {
#     my ($self, $path, $params) = @_;

#     $self->api({
#         url => $self->url('https://api.dropbox.com/1/shares/' . $self->root, $path),
#         extra_params => $params
#     });
# }

# sub media {
#     my ($self, $path, $params) = @_;

#     $self->api({
#         url => $self->url('https://api.dropbox.com/1/media/' . $self->root, $path),
#         extra_params => $params
#     });
# }

# sub copy_ref {
#     my ($self, $path, $params) = @_;

#     $self->api({
#         method => 'GET',
#         url => $self->url('https://api.dropbox.com/1/copy_ref/' . $self->root, $path),
#         extra_params => $params
#     });
# }

# sub thumbnails {
#     my ($self, $path, $output, $params, $opts) = @_;

#     $opts ||= {};
#     if (ref $output eq 'CODE') {
#         $opts->{write_code} = $output; # code ref
#     } elsif (ref $output) {
#         $opts->{write_file} = $output; # file handle
#         binmode $opts->{write_file};
#     } else {
#         open $opts->{write_file}, '>', $output; # file path
#         Carp::croak("invalid output, output must be code ref or filehandle or filepath.")
#             unless $opts->{write_file};
#         binmode $opts->{write_file};
#     }
#     $opts->{extra_params} = $params if $params;
#     $self->api({
#         url => $self->url('https://api-content.dropbox.com/1/thumbnails/' . $self->root, $path),
#         extra_params => $params,
#         %$opts,
#     });
#     return if $self->error;
#     return 1;
# }

# sub create_folder {
#     my ($self, $path, $params) = @_;

#     $params ||= {};
#     $params->{root} ||= $self->root;
#     $params->{path} = $self->path($path);

#     $self->api({
#         url => $self->url('https://api.dropbox.com/1/fileops/create_folder', ''),
#         extra_params => $params
#     });
# }

# sub copy {
#     my ($self, $from, $to_path, $params) = @_;

#     $params ||= {};
#     $params->{root} ||= $self->root;
#     $params->{to_path} = $self->path($to_path);
#     if (ref $from) {
#         $params->{from_copy_ref} = $from->{copy_ref};
#     } else {
#         $params->{from_path} = $self->path($from);
#     }

#     $self->api({
#         url => $self->url('https://api.dropbox.com/1/fileops/copy', ''),
#         extra_params => $params
#     });
# }

# sub move {
#     my ($self, $from_path, $to_path, $params) = @_;

#     $params ||= {};
#     $params->{root} ||= $self->root;
#     $params->{from_path} = $self->path($from_path);
#     $params->{to_path}   = $self->path($to_path);

#     $self->api({
#         url => $self->url('https://api.dropbox.com/1/fileops/move', ''),
#         extra_params => $params
#     });
# }

# sub delete {
#     my ($self, $path, $params) = @_;

#     $params ||= {};
#     $params->{root} ||= $self->root;
#     $params->{path} ||= $self->path($path);
#     $self->api({
#         url => $self->url('https://api.dropbox.com/1/fileops/delete', ''),
#         extra_params => $params
#     });
# }


sub api {
    my ($self, $args) = @_;

    # Content-download endpoints
    if (my $output = delete $args->{output}) {
        if (ref $output eq 'CODE') {
            $args->{write_code} = $output; # code ref
        } elsif (ref $output) {
            $args->{write_file} = $output; # file handle
            binmode $args->{write_file};
        } else {
            open $args->{write_file}, '>', $output; # file path
            Carp::croak("invalid output, output must be code ref or filehandle or filepath.")
                unless $args->{write_file};
            binmode $args->{write_file};
        }
    }

    # Always HTTP POST. https://www.dropbox.com/developers/documentation/http/documentation#formats
    $args->{method}  = 'POST';

    $args->{headers} = [];

    if ($self->access_token) {
        push @{ $args->{headers} }, 'Authorization', 'Bearer ' . $self->access_token;
    }

    # Set PARAMETERS
    my $params = delete $args->{params};

    # Token
    # * PARAMETERS in to Request Body (application/x-www-form-urlencoded)
    # * RETURNS in to Response Body (application/json)
    if ($args->{url} eq 'https://api.dropboxapi.com/oauth2/token') {
        $args->{content} = $params;
    }

    # RPC endpoints
    # * PARAMETERS in to Request Body (application/json)
    # * RETURNS in to Response Body (application/json)
    elsif ($args->{url} =~ qr{ \A https://(?:api|notify).dropboxapi.com }xms) {
        if ($params) {
            push @{ $args->{headers} }, 'Content-Type', 'application/json';
            $args->{content} = $JSON->encode($params);
        }
    }

    # Content-upload endpoints or Content-download endpoints
    # * PARAMETERS in to Dropbox-API-Arg (JSON Format)
    # * RETURNS in to Dropbox-API-Result (JSON Format)
    elsif ($args->{url} =~ qr{ \A https://content.dropboxapi.com }xms) {
        if ($params) {
            push @{ $args->{headers} }, 'Dropbox-API-Arg', $JSON->encode($params);
        }
        if ($args->{content}) {
            push @{ $args->{headers} }, 'Content-Type', 'application/octet-stream';
        }
    }

    my ($req, $res);
    if ($WebService::Dropbox::USE_LWP) {
        ($req, $res) = $self->api_lwp($args);
    } else {
        ($req, $res) = $self->api_furl($args);
    }

    $self->req($req);
    $self->res($res);

    my $decoded_content = $res->decoded_content;

    my $res_data;
    my $res_json = $res->header('Dropbox-Api-Result');
    if (!$res_json && $res->header('Content-Type') =~ qr{ \A (?:application/json|text/javascript) }xms) {
        $res_json = $decoded_content;
    }

    if ($res_json && $res_json ne 'null') {
        $res_data = $JSON->decode($res_json);
    }

    if ($WebService::Dropbox::DEBUG || !$res->is_success) {
        my $level = $res->is_success ? 'DEBUG': 'ERROR';
        my $color = $res->is_success ? "\e[32m" : "\e[31m";
        my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);
        my $time = sprintf("%04d-%02d-%02dT%02d:%02d:%02d", $year + 1900, $mon + 1, $mday, $hour, $min, $sec);
        if ($WebService::Dropbox::VERBOSE) {
            warn sprintf(qq|%s [WebService::Dropbox] [%s] %s
\e[90m%s %s %s
%s
%s\e[0m
${color}%s %s\e[0m
\e[90m%s
%s\e[0m
|,
                $time,
                $level,
                $req->uri->as_string,
                $req->method,
                $req->uri->path,
                $req->protocol // '',
                $req->headers->as_string,
                ( ref $args->{content} ? '' : $args->{content} && $params ? $JSON_PRETTY->encode($params) : '' ),
                $res->protocol,
                $res->status_line,
                $res->headers->as_string,
                ( $res_data ? $JSON_PRETTY->encode($res_data) : $decoded_content . "\n" ),
            );
        } else {
            warn sprintf("%s [WebService::Dropbox] [%s] %s %s -> [%s] %s",
                $time,
                $level,
                $req->uri->as_string,
                ( $params ? $JSON->encode($params) : '-' ),
                $res->code,
                ( $res_json || $decoded_content ),
            );
        }
    }

    unless ($res->is_success) {
        unless ($self->error) {
            $self->error($decoded_content);
        }
        return;
    }

    $self->error(undef);

    return $res_data // +{};
}

sub api_lwp {
    my ($self, $args) = @_;

    my @headers = @{ $args->{headers} // +[] };

    if ($args->{write_file}) {
        $args->{write_code} = sub {
            my $buf = shift;
            $args->{write_file}->print($buf);
        };
    }

    if ($args->{content} && UNIVERSAL::can($args->{content}, 'read')) {
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
        push @headers, 'Content-Length' => $content_length;
    }

    my $req;
    if ($args->{content} && ref $args->{content} eq 'HASH') {
        # application/x-www-form-urlencoded
        $req = HTTP::Request::Common::request_type_with_data(
            $args->{method},
            $args->{url},
            @headers,
            Content => $args->{content}
        );
    } else {
        # application/json or application/octet-stream
        # $args->{content} is encodeed json or file handle
        $req = HTTP::Request->new(
            $args->{method},
            $args->{url},
            \@headers,
            $args->{content},
        );
    }

    $req->protocol('HTTP/1.1');

    my $res = $self->ua->request($req, $args->{write_code});
    ($req, $res);
}

sub api_furl {
    my ($self, $args) = @_;

    if (my $write_file = delete $args->{write_file}) {
        $args->{write_code} = sub {
            $write_file->print($_[3]);
        };
    }

    if (my $write_code = delete $args->{write_code}) {
        $args->{write_code} = sub {
            if ($_[0] =~ qr{ \A 2 }xms) {
                $write_code->(@_);
            } else {
                $self->error($_[3]);
            }
        };
    }

    my $res = $self->furl->request(%$args);
    ($res->request, $res);
}

sub ua {
    my $self = shift;
    my $ua = LWP::UserAgent->new;
    $ua->timeout($self->timeout);
    if ($self->{env_proxy}) {
        $ua->env_proxy;
    }
    $ua;
}

sub furl {
    my $self = shift;
    unless ($self->{furl}) {
        $self->{furl} = Furl->new(
            timeout => $self->timeout,
            ssl_opts => {
                SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_PEER(),
            },
        );
        $self->{furl}->env_proxy if $self->{env_proxy};
    }
    $self->{furl};
}

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

sub env_proxy { $_[0]->{env_proxy} = defined $_[1] ? $_[1] : 1 }

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

=head2 root - set access type

    # Access Type is App folder
    # Your app only needs access to a single folder within the user's Dropbox
    $dropbox->root('sandbox');

    # Access Type is Full Dropbox (default)
    # Your app needs access to the user's entire Dropbox
    $dropbox->root('dropbox');

L<https://www.dropbox.com/developers/start/core>

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

=head2 files(path, output, [params, opts]) - download (no file list, file list is metadata)

    # Current Rev
    my $fh_get = IO::File->new('some file', '>');
    $dropbox->files('folder/file.txt', $fh_get) or die $dropbox->error;
    $fh_get->close;

    # Specified Rev
    $dropbox->files('folder/file.txt', $fh_get, { rev => ... }) or die $dropbox->error;

    # Code ref
    $dropbox->files('folder/file.txt', sub {
        # compatible with LWP::UserAgent and Furl::HTTP
        my $chunk = @_ == 4 ? @_[3] : $_[0];
        print $chunk;
    }) or die $dropbox->error;

    # Range
    $dropbox->files('folder/file.txt', $fh_get) or die $dropbox->error;
    > "0123456789"
    $dropbox->files('folder/file.txt', $fh_get, undef, { headers => ['Range' => 'bytes=5-6'] }) or die $dropbox->error;
    > "56"

L<https://www.dropbox.com/developers/reference/api#files-GET>

=head2 files_put(path, input) - Uploads a files

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

=head2 files_put_chunked(path, input) - Uploads large files by chunked_upload and commit_chunked_upload.

    my $fh_put = IO::File->new('some large file');
    $dropbox->files_put('folder/test.txt', $fh_put) or die $dropbox->error;
    $fh_put->close;

L<https://www.dropbox.com/developers/reference/api#chunked_upload>

=head2 chunked_upload(input, [params]) - Uploads large files

    # large file 1/3
    my $fh_put = IO::File->new('large file part 1');
    my $data = $dropbox->chunked_upload($fh_put) or die $dropbox->error;
    $fh_put->close;

    # large file 2/3
    $fh_put = IO::File->new('large file part 2');
    $data = $dropbox->chunked_upload($fh_put, {
        upload_id => $data->{upload_id},
        offset => $data->{offset}
    }) or die $dropbox->error;
    $fh_put->close;

    # large file 3/3
    $fh_put = IO::File->new('large file part 3');
    $data = $dropbox->chunked_upload($fh_put, {
        upload_id => $data->{upload_id},
        offset => $data->{offset}
    }) or die $dropbox->error;
    $fh_put->close;

    # commit
    $dropbox->commit_chunked_upload('folder/test.txt', {
        upload_id => $data->{upload_id}
    }) or die $dropbox->error;

L<https://www.dropbox.com/developers/reference/api#chunked_upload>

=head2 commit_chunked_upload(path, params) - Completes an upload initiated by the chunked_upload method.

    $dropbox->commit_chunked_upload('folder/test.txt', {
        upload_id => $data->{upload_id}
    }) or die $dropbox->error;

L<https://www.dropbox.com/developers/reference/api#commit_chunked_upload>

=head2 copy(from_path or from_copy_ref, to_path)

    # from_path
    $dropbox->copy('folder/test.txt', 'folder/test_copy.txt') or die $dropbox->error;

    # from_copy_ref
    my $copy_ref = $dropbox->copy_ref('folder/test.txt') or die $dropbox->error;

    $dropbox->copy($copy_ref, 'folder/test_copy.txt') or die $dropbox->error;

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

=head2 delta([params]) - get file list

    my $data = $dropbox->delta() or die $dropbox->error;

L<https://www.dropbox.com/developers/reference/api#delta>

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

=head2 copy_ref(path)

    my $copy_ref = $dropbox->copy_ref('folder/test.txt') or die $dropbox->error;

    $dropbox->copy($copy_ref, 'folder/test_copy.txt') or die $dropbox->error;

L<https://www.dropbox.com/developers/reference/api#copy_ref>

=head2 thumbnails(path, output)

    my $fh_get = File::Temp->new;
    $dropbox->thumbnails('folder/file.txt', $fh_get) or die $dropbox->error;
    $fh_get->flush;
    $fh_get->seek(0, 0);

L<https://www.dropbox.com/developers/reference/api#thumbnails>

=head2 env_proxy

enable HTTP_PROXY, NO_PROXY

    $dropbox->env_proxy;

=head1 AUTHOR

Shinichiro Aska

=head1 SEE ALSO

- L<https://www.dropbox.com/developers/reference/api>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
