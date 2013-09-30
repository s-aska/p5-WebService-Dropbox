# NAME

WebService::Dropbox - Perl interface to Dropbox API

# SYNOPSIS

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

# DESCRIPTION

WebService::Dropbox is Perl interface to Dropbox API

\- Support Dropbox v1 REST API

\- Support Furl (Fast!!!)

\- Streaming IO (Low Memory)

\- Default URI Escape (The specified path is utf8 decoded string)

# API

## login(callback\_url) - get request token and request secret

    my $callback_url = '...'; # optional
    my $url = $dropbox->login($callback_url) or die $dropbox->error;
    warn "Please Access URL and press Enter: $url";

## auth - get access token and access secret

    $dropbox->auth or die $dropbox->error;
    warn "access_token: " . $dropbox->access_token;
    warn "access_secret: " . $dropbox->access_secret;

## root - set access type

    # Access Type is App folder
    # Your app only needs access to a single folder within the user's Dropbox
    $dropbox->root('sandbox');

    # Access Type is Full Dropbox (default)
    # Your app needs access to the user's entire Dropbox
    $dropbox->root('dropbox');

[https://www.dropbox.com/developers/start/core](https://www.dropbox.com/developers/start/core)

## account\_info

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

[https://www.dropbox.com/developers/reference/api\#account-info](https://www.dropbox.com/developers/reference/api\#account-info)

## files(path, output, \[params, opts\]) - download (no file list, file list is metadata)

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

[https://www.dropbox.com/developers/reference/api\#files-GET](https://www.dropbox.com/developers/reference/api\#files-GET)

## files\_put(path, input) - Uploads a files

    my $fh_put = IO::File->new('some file');
    $dropbox->files_put('folder/test.txt', $fh_put) or die $dropbox->error;
    $fh_put->close;

    # no overwrite (default true)
    $dropbox->files_put('folder/test.txt', $fh_put, { overwrite => 0 }) or die $dropbox->error;
    # create 'folder/test (1).txt'

    # Specified Parent Rev
    $dropbox->files_put('folder/test.txt', $fh_put, { parent_rev => ... }) or die $dropbox->error;
    # conflict prevention

[https://www.dropbox.com/developers/reference/api\#files\_put](https://www.dropbox.com/developers/reference/api\#files\_put)

## files\_put\_chunked(path, input) - Uploads large files by chunked\_upload and commit\_chunked\_upload.

    my $fh_put = IO::File->new('some large file');
    $dropbox->files_put('folder/test.txt', $fh_put) or die $dropbox->error;
    $fh_put->close;

[https://www.dropbox.com/developers/reference/api\#chunked\_upload](https://www.dropbox.com/developers/reference/api\#chunked\_upload)

## chunked\_upload(input, \[params\]) - Uploads large files

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

[https://www.dropbox.com/developers/reference/api\#chunked\_upload](https://www.dropbox.com/developers/reference/api\#chunked\_upload)

## commit\_chunked\_upload(path, params) - Completes an upload initiated by the chunked\_upload method.

    $dropbox->commit_chunked_upload('folder/test.txt', {
        upload_id => $data->{upload_id}
    }) or die $dropbox->error;

[https://www.dropbox.com/developers/reference/api\#commit\_chunked\_upload](https://www.dropbox.com/developers/reference/api\#commit\_chunked\_upload)

## copy(from\_path or from\_copy\_ref, to\_path)

    # from_path
    $dropbox->copy('folder/test.txt', 'folder/test_copy.txt') or die $dropbox->error;

    # from_copy_ref
    my $copy_ref = $dropbox->copy_ref('folder/test.txt') or die $dropbox->error;

    $dropbox->copy($copy_ref, 'folder/test_copy.txt') or die $dropbox->error;

[https://www.dropbox.com/developers/reference/api\#fileops-copy](https://www.dropbox.com/developers/reference/api\#fileops-copy)

## move(from\_path, to\_path)

    $dropbox->move('folder/test.txt', 'folder/test_move.txt') or die $dropbox->error;

[https://www.dropbox.com/developers/reference/api\#fileops-move](https://www.dropbox.com/developers/reference/api\#fileops-move)

## delete(path)

    # folder delete
    $dropbox->delete('folder') or die $dropbox->error;

    # file delete
    $dropbox->delete('folder/test.txt') or die $dropbox->error;

[https://www.dropbox.com/developers/reference/api\#fileops-delete](https://www.dropbox.com/developers/reference/api\#fileops-delete)

## create\_folder(path)

    $dropbox->create_folder('some_folder') or die $dropbox->error;

[https://www.dropbox.com/developers/reference/api\#fileops-create-folder](https://www.dropbox.com/developers/reference/api\#fileops-create-folder)

## metadata(path, \[params\]) - get file list

    my $data = $dropbox->metadata('some_folder') or die $dropbox->error;

    my $data = $dropbox->metadata('some_file') or die $dropbox->error;

    # 304
    my $data = $dropbox->metadata('some_folder', { hash => ... });
    return if $dropbox->code == 304; # not modified
    die $dropbox->error if $dropbox->error;
    return $data;

[https://www.dropbox.com/developers/reference/api\#metadata](https://www.dropbox.com/developers/reference/api\#metadata)

## delta(\[params\]) - get file list

    my $data = $dropbox->delta() or die $dropbox->error;

[https://www.dropbox.com/developers/reference/api\#delta](https://www.dropbox.com/developers/reference/api\#delta)

## revisions(path, \[params\])

    my $data = $dropbox->revisions('some_file') or die $dropbox->error;

[https://www.dropbox.com/developers/reference/api\#revisions](https://www.dropbox.com/developers/reference/api\#revisions)

## restore(path, \[params\])

    # params rev is Required
    my $data = $dropbox->restore('some_file', { rev => $rev }) or die $dropbox->error;

[https://www.dropbox.com/developers/reference/api\#restore](https://www.dropbox.com/developers/reference/api\#restore)

## search(path, \[params\])

    # query rev is Required
    my $data = $dropbox->search('some_file', { query => $query }) or die $dropbox->error;

[https://www.dropbox.com/developers/reference/api\#search](https://www.dropbox.com/developers/reference/api\#search)

## shares(path, \[params\])

    my $data = $dropbox->shares('some_file') or die $dropbox->error;

[https://www.dropbox.com/developers/reference/api\#shares](https://www.dropbox.com/developers/reference/api\#shares)

## media(path, \[params\])

    my $data = $dropbox->media('some_file') or die $dropbox->error;

[https://www.dropbox.com/developers/reference/api\#media](https://www.dropbox.com/developers/reference/api\#media)

## copy\_ref(path)

    my $copy_ref = $dropbox->copy_ref('folder/test.txt') or die $dropbox->error;

    $dropbox->copy($copy_ref, 'folder/test_copy.txt') or die $dropbox->error;

[https://www.dropbox.com/developers/reference/api\#copy\_ref](https://www.dropbox.com/developers/reference/api\#copy\_ref)

## thumbnails(path, output)

    my $fh_get = File::Temp->new;
    $dropbox->thumbnails('folder/file.txt', $fh_get) or die $dropbox->error;
    $fh_get->flush;
    $fh_get->seek(0, 0);

[https://www.dropbox.com/developers/reference/api\#thumbnails](https://www.dropbox.com/developers/reference/api\#thumbnails)

## env\_proxy

enable HTTP\_PROXY, NO\_PROXY

    $dropbox->env_proxy;

# AUTHOR

Shinichiro Aska

# SEE ALSO

\- [https://www.dropbox.com/developers/reference/api](https://www.dropbox.com/developers/reference/api)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
