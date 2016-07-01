package WebService::Dropbox::Files;
use strict;
use warnings;
use parent qw(Exporter);

our @EXPORT = do {
    no strict 'refs';
    grep { $_ =~ qr{ \A [a-z] }xms } keys %{ __PACKAGE__ . '::' };
};

# https://www.dropbox.com/developers/documentation/http/documentation#files-copy
sub copy {
    my ($self, $from_path, $to_path) = @_;

    my $params = {
        from_path => $from_path,
        to_path => $to_path,
    };

    $self->api({
        url => 'https://api.dropboxapi.com/2/files/copy',
        params => $params,
    });
}

# https://www.dropbox.com/developers/documentation/http/documentation#files-create_folder
sub create_folder {
    my ($self, $path) = @_;

    my $params = {
        path => $path,
    };

    $self->api({
        url => 'https://api.dropboxapi.com/2/files/create_folder',
        params => $params,
    });
}

# https://www.dropbox.com/developers/documentation/http/documentation#files-delete
sub delete {
    my ($self, $path) = @_;

    my $params = {
        path => $path,
    };

    $self->api({
        url => 'https://api.dropboxapi.com/2/files/delete',
        params => $params,
    });
}

# https://www.dropbox.com/developers/documentation/http/documentation#files-download
sub download {
    my ($self, $path, $output) = @_;

    $self->api({
        url => 'https://content.dropboxapi.com/2/files/download',
        params => { path => $path },
        output => $output,
    });
}

# https://www.dropbox.com/developers/documentation/http/documentation#files-get_metadata
sub get_metadata {
    my ($self, $path, $optional_params) = @_;

    my $params = {
        path => $path,
        %{ $optional_params // {} },
    };

    $self->api({
        url => 'https://api.dropboxapi.com/2/files/get_metadata',
        params => $params,
    });
}

# https://www.dropbox.com/developers/documentation/http/documentation#files-get_preview
sub get_preview {
    my ($self, $path, $output) = @_;

    my $params = {
        path => $path,
    };

    $self->api({
        url => 'https://content.dropboxapi.com/2/files/get_preview',
        params => $params,
        output => $output,
    });
}





# https://www.dropbox.com/developers/documentation/http/documentation#files-upload
sub upload {
    my ($self, $path, $content, $optional_params) = @_;

    my $params = {
        path => $path,
        %{ $optional_params // {} },
    };

    $self->api({
        url => 'https://content.dropboxapi.com/2/files/upload',
        params => $params,
        content => $content,
    });
}

1;
