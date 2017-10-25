#!/usr/bin/perl

use strict;
use warnings;
use utf8::all;


my $PM = qr{[A-ZÁÀÃÉÚÍÓÇ][a-záàãéúíóç]+};
my $de = qr{d[aoe]s?};
my $s = qr{[\n ]};
my $np = qr{$PM ($s $PM|$s $de $s $PM)*}x;            #nome proprio completo
my $rel = qr{pai|filh[oa]|sobrinh[oa]|net[oa]|irmão?|av[óô]|mae|ti[oa]|bisav[óô]|amig[oa]|prim[oa]|cunhad[oa]|sogr[oa]|nora|genro|amante|esposa|marido|padrasto|madrasta|bastardo};                              #relação de parentesco
my $all = qr{\s[\s\w]*};

#my $con = qr{[\s\w]+[\s\ws]+?};

while(<>) {
    s/(^\s?|[.!?":]([ \n]|$PM)|^-- )/$1_/g;
    while(/(\b$np)($all) ($rel)($all)($np)/g) {
      my $fPers = $1;                                 #first person
      my $rel2 = $4;                                   #relation
      my $sPers = $6;                                 #second person
      my $ver = $3;
      if ($ver =~ /$all ($rel) $all ($np) $all/x) {
        my $temp = $1;
        my $temp2 = $2;
        print "$fPers -> $temp -> $temp2\n";
        $fPers = $temp2;
      } else {
        if ($ver =~ /($np)/) {                                 #variável para verificação
          $fPers = $1;
        }
      }
      print "$fPers -> $rel2 -> $sPers\n";
    }
    s/_//g;
}
