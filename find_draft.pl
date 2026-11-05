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

sub find_draft {
    my ($x, $path) = @_;
    return unless defined $x && ref $x;
    if (ref $x eq 'HASH') {
        if (exists $x->{draft}) {
            print "Found draft at $path -> draft!\n";
            print "Keys in draft: " . join(", ", sort keys %{$x->{draft}}) . "\n";
            if ($x->{draft}{content}) {
                print "Keys in draft->content: " . join(", ", sort keys %{$x->{draft}{content}}) . "\n";
                print "draft->content->D = " . ($x->{draft}{content}{D} // "undef") . "\n";
                my $pages = $x->{draft}{content}{A};
                if ($pages && ref $pages eq 'ARRAY') {
                    print "Total pages in draft->content->A: " . scalar(@$pages) . "\n";
                }
            }
        }
        for my $k (sort keys %$x) {
            find_draft($x->{$k}, "$path->$k");
        }
    } elsif (ref $x eq 'ARRAY') {
        my $idx = 0;
        for my $item (@$x) {
            find_draft($item, "$path\[$idx\]");
            $idx++;
        }
    }
}

find_draft($data, "root");
