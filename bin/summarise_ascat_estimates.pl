#!/usr/bin/env perl

use strict;
use warnings;
use List::MoreUtils qw(uniq);

my $estimates_files = shift @ARGV or die "Input a list of ASCAT estimates files\n";

my %stats;
my @categories;

open E, "<$estimates_files" or die "Can't open $estimates_files\n";
while (<E>) {
	my $file = $_;
	chomp $file;
	open F, "<$file" or die "Can't open $file\n";
	while (<F>) {
		my $line = $_;
		chomp $line;
		#my ($category, $value) = ();
		if ($line =~ /^(\S+)\s+(\S+)/) {
			$stats{$file}{$1} = $2;
			push @categories, $1;
		} else {
			die "Error in file $file, line $line\n";
		}
	}
	close F;
}
close E;

# Print out results

print join("\t", "File", sort(uniq(@categories))) . "\n";

foreach my $f (sort keys %stats) {
	my @line;
	foreach my $cat (sort keys %{$stats{$f}}) {
		push @line, $stats{$f}{$cat};
	}
	print join("\t", $f, @line) . "\n";
}


