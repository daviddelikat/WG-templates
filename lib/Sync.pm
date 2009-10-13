package WGDev::Command::Sync;
use strict;
use warnings;
use 5.008008;

our $VERSION = '0.2.0';

use WGDev::Command::Edit;
BEGIN { our @ISA = qw(WGDev::Command::Edit) }

use WGDev ();

sub config_options {
    return qw(
    );
}

sub process {
    my $self = shift;
    my $wgd  = $self->wgd;

# TODO load status and config
# if state is running, then print message and exit
# set state to running nand save...

# TODO find the items to be saved to FS.

    my @files = $self->export_asset_data;

    for ( @files ) {
        # TODO move/copy files to the storage area
        # perhaps we shoudl make sure the asset itself was not alos editted?
    }

    # TODO find files that need to be loaded into WG Database

    my $output_format = "%-8s: %-30s (%22s) %s\n";

    my $version_tag;
    for my $file (@files) {
        open my $fh, '<:utf8', $file->{filename} or next;
        my $asset_text = do { local $/; <$fh> };
        close $fh or next;
        $version_tag ||= do {
            require WebGUI::VersionTag;
            my $vt = WebGUI::VersionTag->getWorking( $wgd->session );
            $vt->set( { name => 'WGDev Template Sync' } );
            $vt;
        };
        my $asset_data = $wgd->asset->deserialize($asset_text);
        my $asset;
        my $parent;
        if ( $asset_data->{parent} ) {
            $parent = eval { $wgd->asset->find( $asset_data->{parent} ) };
        }
        if ( $file->{asset_id} ) {
            $asset = $wgd->asset->by_id( $file->{asset_id}, undef,
                $file->{revision} );
            $asset = $asset->addRevision(
                $asset_data,
                undef,
                {
                    skipAutoCommitWorkflows => 1,
                    skipNotification        => 1,
                } );
            if ($parent) {
                $asset->setParent($parent);
            }
        }
        else {
            $parent ||= $wgd->asset->import_node;
            my $asset_id = $asset_data->{assetId};
            $asset = $parent->addChild(
                $asset_data,
                $asset_id,
                undef,
                {
                    skipAutoCommitWorkflows => 1,
                    skipNotification        => 1,
                } );
        }
        printf $output_format, ( $file->{asset_id} ? 'Updating' : 'Adding' ),
            $asset->get('url'), $asset->getId, $asset->get('title');
    }

    if ($version_tag) {
        $version_tag->commit;
    }
    return 1;
}


1;

__END__

=head1 NAME

WGDev::Command::Sync - Syncronize templates with filesystem

=head1 SYNOPSIS

    wgd sync

=head1 DESCRIPTION

copy Template data to and from filesystem based on last edit time vs last run time

=head1 OPTIONS

=head1 METHODS

=head1 AUTHOR

Graham Knop <haarg@haarg.org>
code re-aranged by
David Delikat <david-delikat@usa.net>
to make it do something else...

=head1 LICENSE

Copyright (c) 2009, Graham Knop

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5.10.0. For more details, see the
full text of the licenses in the directory LICENSES.

=cut

