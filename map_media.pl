use strict;
use warnings;
use utf8;
use JSON::PP;

open my $fh, "<:raw", "canva_clean.json" or die $!;
local $/;
my $raw = <$fh>;
close $fh;
$raw =~ s/^\xEF\xBB\xBF//;
my $data = JSON::PP->new->utf8->decode($raw);

my %media_to_uuid;
sub find_media {
    my ($el) = @_;
    return unless defined $el && ref $el;
    if (ref $el eq 'HASH') {
        # Check if it has media ID and uri
        # Canva often stores media in imageSets or media refs
        for my $k (keys %$el) {
            find_media($el->{$k});
        }
    } elsif (ref $el eq 'ARRAY') {
        for my $item (@$el) {
            find_media($item);
        }
    }
}

# Let's inspect imageSets in draft
my $imgSets = $data->{page}{Pm}{E}{draft}{imageSets};
if ($imgSets && ref $imgSets eq 'HASH') {
    print "imageSets keys count: " . scalar(keys %$imgSets) . "\n";
    for my $id (keys %$imgSets) {
        my $val = $imgSets->{$id};
        # check uri
        my $json = encode_json($val);
        if ($json =~ m{ifs%3A%2F%2FM%2F([a-f0-9\-]+)}) {
            print "$id => $1\n";
        } elsif ($json =~ m{/M/([a-f0-9\-]+)}) {
            print "$id => $1\n";
        }
    }
} else {
    print "No imageSets in draft\n";
}
