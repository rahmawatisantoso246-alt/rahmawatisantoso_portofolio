use strict;
use warnings;
use utf8;
use JSON::PP;

binmode(STDOUT, ":utf8");
local $/;
open my $fh, "<:encoding(UTF-8)", "canva_clean.json" or die $!;
my $raw = <$fh>; $raw =~ s/^\x{feff}//;
close $fh;

my $data = JSON::PP->new->decode($raw);
my $draft = $data->{draft}{content};
print "Title: " . ($draft->{D} // "No Title") . "\n";
my $pages = $draft->{A};
print "Total Pages: " . scalar(@$pages) . "\n\n";

sub inspect_elem {
    my ($el) = @_;
    return unless ref $el;
    if (ref $el eq "HASH") {
        if ($el->{a} && ref $el->{a} eq "HASH" && $el->{a}{C} && ref $el->{a}{C} eq "HASH" && $el->{a}{C}{A}) {
            for my $t (@{$el->{a}{C}{A}}) {
                $t =~ s/\r?\n/ /g;
                $t =~ s/^\s+|\s+$//g;
                print "  [TEXT] $t\n" if length($t);
            }
        }
        for my $k (keys %$el) {
            my $v = $el->{$k};
            if (defined $v && !ref($v)) {
                if ($v =~ /^https?:/) {
                    print "  [URL] $k: $v\n";
                }
            }
            inspect_elem($v);
        }
    } elsif (ref $el eq "ARRAY") {
        for my $item (@$el) {
            inspect_elem($item);
        }
    }
}

for my $i (0 .. $#$pages) {
    my $p = $pages->[$i];
    my $title = $p->{B} // ("Page " . ($i + 1));
    print "==================================================\n";
    print "PAGE " . ($i + 1) . ": $title\n";
    print "==================================================\n";
    inspect_elem($p);
    print "\n";
}
