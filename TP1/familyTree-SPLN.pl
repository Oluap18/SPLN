#!/usr/bin/perl

use strict;
use warnings;
use utf8::all;

my @pessoas;


my $PM = qr{[A-ZÁÀÃÉÚÍÓÇ][a-záàãéúíóç]+};
my $de = qr{d[aoe]s?};
my $s = qr{[\n ]};
my $np = qr{$PM ($s $PM|$s $de $s $PM)*}x;            #nome proprio completo
my $par = qr{pai|filh[oa]|sobrinh[oa]|net[oa]|irmão?|av[óô]|mae|ti[oa]|bisav[óô]|amig[oa]|prim[oa]|cunhad[oa]|sogr[oa]|nora|genro|amante|esposa|marido|padrasto|madrasta|bastardo};                              #relação de parentesco
my $pal = qr{\w+};
my $all = qr{(([^\n]$pal)|\.)(\W$pal?)*};
my $allP = qr{([^\n]$pal)(\W$pal?)*?};


while(<>){
  s/(^\s?|[.!?":]([ \n]|$PM)|^-- )/$1_/g;
  while(/(\b$np)($all)($np)/g){
    my $fPers = $1;
    my $sPers = $7;
    my $tudo = $3;
    my $tPers = "";
    my $temp = "";
    my $count = 0;
    $pessoas[$count++] = $fPers;  #guardar o primeiro nome no array
    $pessoas[$count++] = $sPers;  #guardar o ultimo nome no array
    print("$fPers relaciona-se com: $sPers\n");

    while($tudo =~ /($allP) ($np)($all)/){
      my $pessoa = $4;

      foreach $a (keys @pessoas){
        print("$pessoas[$a] relaciona-se com: $pessoa\n");
      }

      $pessoas[$count++] = $4;    #guardar os nomes próprios
      $tudo = $6;         #iterar o ciclo


      
    }

    #print("$fPers relaciona-se com $sPers\n");
  }
  s/_//g;
}