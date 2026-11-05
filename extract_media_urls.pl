use strict;
use warnings;
use utf8;

open my $fh, "<:encoding(UTF-8)", "canva_page.html" or die $!;
local $/;
my $html = <$fh>;
close $fh;

my %urls;
while ($html =~ m{(https://media\.canva\.com/v2/image-resize/format:PNG/height:(\d+)/quality:100/uri:ifs%3A%2F%2FM%2F([a-f0-9\-]+)/watermark:F/width:(\d+)\?[^"'\s<>]+)}g) {
    my ($url, $h, $uuid, $w) = ($1, $2, $3, $4);
    # prefer width around 800 or 1600 (screen size)
    if ($w == 800 || (!exists $urls{$uuid} && $w >= 400)) {
        $urls{$uuid} = { url => $url, w => $w, h => $h };
    }
}

open my $out, ">", "canva_media_urls.txt" or die $!;
for my $uuid (sort keys %urls) {
    print $out "$uuid\t$urls{$uuid}{w}x$urls{$uuid}{h}\t$urls{$uuid}{url}\n";
}
close $out;

print "Found " . scalar(keys %urls) . " unique Canva image UUIDs with high-res download URLs!\n";
