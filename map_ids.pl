use strict;
use warnings;
use utf8;

open my $fh, "<:encoding(UTF-8)", "canva_clean.json" or die $!;
local $/;
my $raw = <$fh>;
close $fh;

my %map;
while ($raw =~ m{"type":"RASTER","id":"(M[A-Za-z0-9_\-]+)".*?ifs%3A%2F%2FM%2F([a-f0-9\-]{36})}gs) {
    $map{$1} = "$2.png";
}

open my $out, ">", "id_to_file.txt" or die $!;
for my $id (sort keys %map) {
    print $out "$id = $map{$id}\n";
}
close $out;
print "Mapped " . scalar(keys %map) . " IDs to files!\n";
