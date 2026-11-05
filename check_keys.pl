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
print "Keys: " . join(", ", sort keys %$data) . "\n";
for my $k (sort keys %$data) {
    if (ref($data->{$k}) eq 'HASH') {
        print "  $k: " . join(", ", sort keys %{$data->{$k}}) . "\n";
    } else {
        print "  $k: " . ref($data->{$k}) . "\n";
    }
}
