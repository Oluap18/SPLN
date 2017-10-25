#!/usr/bin/perl

use strict;
use warnings;
use utf8::all;

my $pessoa;
my $fPers;
my $sPers;
my $tudo;
my $tPers;
my $temp;
my $countAux;
my $count;


my $PM = qr{[A-ZÁÀÃÉÚÍÓÇ][a-záàãéúíóç]+};
my $de = qr{d[aoe]s?};
my $s = qr{[\n ]};
my $np = qr{$PM ($s $PM|$s $de $s $PM)*}x;            #nome proprio completo
my $par = qr{pai|filh[oa]|sobrinh[oa]|net[oa]|irmão?|av[óô]|mae|ti[oa]|bisav[óô]|amig[oa]|prim[oa]|cunhad[oa]|sogr[oa]|nora|genro|amante|esposa|marido|padrasto|madrasta|bastardo};                              #relação de parentesco
my $pal = qr{\w+};
my $all = qr{(([^\n]$pal)|[.,;-?!])(\W$pal?)*};
my $allP = qr{([^\n]$pal)(\W$pal?)*?};


while(<>){
  s/(^\s?|[.!?":]([ \n]|$PM)|^-- )/$1_/g;
  while(/(\b$np)($all)($np)/g){
    my @pessoas;
    $fPers = $1;                  #guardar o primeiro nome do regex
    $sPers = $7;                  #guardar o último nome do regex
    $tudo = $3;                   #guardar todo o conteudo entre os nomes próprios

    $count = 0;
    $pessoas[$count++] = $fPers;  #guardar o primeiro nome no array
    
    if($tudo =~ /($np)/){         #se tiver mais do que 2 nomes

      while($tudo =~ /($allP) ($np)($all)/){    #Enquanto enquanto houver nomes próprios entre os dois nomes próprios do maior regex
        $pessoa = $4;
        $countAux = 0;


        foreach $a (keys @pessoas){

          if($1 =~ /($par)/){       #se tiver relações de parentesco
            
            if($countAux == $count-1){      #se a relação de parentesco pertencer ao nome próprio no indice do array
              print("$pessoas[$a] -> $1 -> $pessoa\n");
            }
            else{
              print("$pessoas[$a] relaciona-se com: $pessoa\n");
            
            }
          }
          else{
            print("$pessoas[$a] relaciona-se com: $pessoa\n");
          }

          $countAux++;
        }

        $pessoas[$count++] = $4;    #guardar os nomes próprios
        $tudo = $6;         #iterar o ciclo

      }
      my $countAux = 0;         #Estabelecer a relação entre os nomes do array e o último nome próprio
      foreach $a (keys @pessoas){

        if($tudo =~ /($par)/){        #Caso exista uma relação de parentesco entre o último e penúltimo nome próprio. 
          #$tudo neste caso é a relação entre o penúltimo e último nome próprio

          if($countAux == $count-1){    #se a relação de parentesco pertencer ao nome próprio no indice do array
            print("$pessoas[$a] -> $1 -> $sPers\n");
          }
          else{     
            print("$pessoas[$a] relaciona-se com: $sPers\n");
          }
        }
        else{
          print("$pessoas[$a] relaciona-se com: $sPers\n");
        }
        $countAux++;
      }
    }

    else{

      if($tudo =~ /($par)/){      #se tiver 2 nomes, e tiverem parentesco
        print("$fPers -> $1 -> $sPers\n");
      }
      else{
        print("$fPers relaciona-se com: $sPers\n");
      }

    }

  }
  s/_//g;
}