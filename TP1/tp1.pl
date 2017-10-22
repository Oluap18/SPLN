#!/usr/bin/perl

use strict;
$/ = ''; # processar paragrafo a paragrafo

my %names;
my @names_arr;

my $PM = qr{\b[A-Z][\w]*\w};
my $de = qr{d[aoe]s?};
my $s = qr{[\n ]};
my $np = qr{$PM (?: $s $PM | $s $de $s $PM )*}x;


while (<>) {
	s/(^|[.!?]($s)|^-- |— )/$1_/g;
	s/de /de _/g;
	s/($np)/{$1}/g;
	s/_//g;
	print $_;
}