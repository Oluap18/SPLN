#!/usr/bin/perl

use strict;
use warnings;
use utf8::all;


my $PM = qr{[A-ZÁÀÃÉÚÍÓÇ][a-záàãéúíóç]+};
my $de = qr{d[aoe]s?};
my $s = qr{[\n ]};
my $np = qr{$PM ($s $PM|$s $de $s $PM)*}x;            #nome proprio completo
my $par = qr{pai|filh[oa]|sobrinh[oa]|net[oa]|irmão?|av[óô]|mae|ti[oa]|bisav[óô]|amig[oa]|prim[oa]|cunhad[oa]|sogr[oa]|nora|genro|amante|esposa|marido|padrasto|madrasta|bastardo};                              #relação de parentesco
my $all = qr{\s[\s\w]*};
my $pal = qr{\w+};
my $all2 = qr{([^\n]$pal| ){1,8}};

while(<>){
  s/(^\s?|[.!?":]([ \n]|$PM)|^-- )/$1_/g;
  s/($all2)/{$1}/g;
  s/_//g;
  print $_;
}