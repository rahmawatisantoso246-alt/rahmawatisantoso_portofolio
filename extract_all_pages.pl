use strict;
use warnings;
use utf8;
use JSON::PP;

binmode(STDOUT, ":utf8");
open my $fh, "<:raw", "canva_clean.json" or die $!;
local $/;
my $raw = <$fh>;
close $fh;
$raw =~ s/^\xEF\xBB\xBF//;
my $data = JSON::PP->new->utf8->decode($raw);
my $draft = $data->{page}{Pm}{E}{draft}{content};
my $pages = $draft->{A};

open my $out, ">:encoding(UTF-8)", "canva_47_pages_full.txt" or die $!;

print $out "TITLE: " . ($draft->{D} // "") . "\n";
print $out "TOTAL PAGES: " . scalar(@$pages) . "\n\n";

sub walk_page {
    my ($el, $texts, $urls, $media) = @_;
    return unless defined $el && ref $el;
    if (ref $el eq 'HASH') {
        # Check text
        if ($el->{a} && ref($el->{a}) eq 'HASH' && $el->{a}{C} && ref($el->{a}{C}) eq 'HASH' && $el->{a}{C}{A}) {
            for my $t (@{$el->{a}{C}{A}}) {
                $t =~ s/\r?\n/ /g;
                $t =~ s/^\s+|\s+$//g;
                push @$texts, $t if length($t);
            }
        }
        # Check URLs in properties
        for my $k (keys %$el) {
            my $v = $el->{$k};
            if (defined $v && !ref($v) && $v =~ /^https?:/) {
                push @$urls, "$k: $v";
            }
            if ($k eq 'A' && ref($v) eq 'HASH' && $v->{A} && !ref($v->{A})) {
                push @$media, $v->{A};
            }
            walk_page($v, $texts, $urls, $media);
        }
    } elsif (ref $el eq 'ARRAY') {
        for my $item (@$el) {
            walk_page($item, $texts, $urls, $media);
        }
    }
}

for my $i (0 .. $#$pages) {
    my $p = $pages->[$i];
    my $title = $p->{B} // "No Title";
    my @texts;
    my @urls;
    my @media;
    walk_page($p, \@texts, \@urls, \@media);

    print $out "================================================================================\n";
    print $out "PAGE " . ($i + 1) . ": $title\n";
    print $out "================================================================================\n";
    if (@texts) {
        print $out "--- TEXTS ---\n";
        for my $t (@texts) {
            print $out "  * $t\n";
        }
    }
    if (@urls) {
        print $out "--- URLS ---\n";
        for my $u (@urls) {
            print $out "  > $u\n";
        }
    }
    if (@media) {
        my %uniq = map { $_ => 1 } @media;
        print $out "--- MEDIA IDs ---\n";
        print $out "  " . join(", ", sort keys %uniq) . "\n";
    }
    print $out "\n";
}
close $out;
print "Extraction complete! Total pages: " . scalar(@$pages) . "\n";
