#!/usr/bin/perl

use strict;
use warnings;
use utf8::all;

my $pessoa;                                                                               #guarda qualquer occorência de nome proprio
my $fPers;                                                                                #primeiro nome proprio a aparecer
my $sPers;
my $tudo;
my $tPers;
my $temp;
my $countAux;
my $count;
my %counter;
my $iterator;

my $PM = qr{[A-ZÁÀÃÉÚÍÓÇ][a-záàãéúíóç]+};                                                   #palavra maiúscula
my $de = qr{d[aoe]s?};                                                                      #conector - ex: "de,da,do"
my $s = qr{[\n ]};                                                                          #space or new line
my $np = qr{$PM ($s $PM|$s $de $s $PM)*}x;                                                  #nome proprio completo
my $rSupM = qr{genro|amante|marido|padrasto};                                               #relação "superior" -> masculino
my $rSup = qr{pai|av[óô]|ti[oa]|bisav[óô]|amig[oa]|cunhad[oa]|sogr[oa]};                    #relação "superior"
my $rSupF = qr{mãe|nora|esposa|madrasta};                                                   #relação "superior" -> feminino
my $rInf = qr{filh[oa]|sobrinh[oa]|net[oa]|irmão?|prim[oa]|cunhad[oa]|bastardo};            #relação "inferior"
my $par = qr{$rSup|$rSupM|$rSupF|$rInf};                                                    #relação de parentesco
my $pal = qr{\w+};                                                                          #palavra [a-zA-Z_0-9]+
my $all = qr{(([^\n]$pal)|[.,;-?!])(\W$pal?)*};
my $allP = qr{([^\n]$pal)(\W$pal?)*?};

while(<>){
  s/(^\s?|[.!?":]([ \n]|$PM)|^-- )/$1_/g;
  while(/(\b$np)($all)($np)/g){
    my @pessoas;
    $fPers = $1;                                                                            #guarda o primeiro nome do paragrafo
    $sPers = $7;                                                                            #guarda o último nome do paragrafo
    $tudo = $3;                                                                             #guarda todo o conteudo entre os nomes próprios
    $count = 0;
    $pessoas[$count++] = $fPers;                                                            #guardar o primeiro nome no array
    if($tudo =~ /($np)/){                                                                  #se paragrafo tiver mais do que 2 nomes proprios
      while($tudo =~ /($allP) ($np)($all)/){                                               #enquanto enquanto houver nomes próprios entre os dois nomes próprios do maior regex
        $pessoa = $4;
        $countAux = 0;
        foreach $a (keys @pessoas){
          if($1 =~ /($par)/){                                                               #se tiver relações de parentesco
            if($countAux == $count-1){                                                      #se a relação de parentesco pertencer ao nome próprio no indice do array
              verifica_relacao($pessoas[$a],$pessoa,$1);
            }
            else{
              verifica($pessoas[$a], $pessoa);
            }
          }
          else{
            verifica($pessoas[$a],$pessoa);
          }
          $countAux++;
        }
        $pessoas[$count++] = $4;                                                            #guardar os nomes próprios
        $tudo = $6;                                                                         #iterar o ciclo
      }
      my $countAux = 0;                                                                     #Estabelecer a relação entre os nomes do array e o último nome próprio
      foreach $a (keys @pessoas){
        if($tudo =~ /($par)/){                                                              #Caso exista uma relação de parentesco entre o último e penúltimo nome próprio.                                        #$tudo neste caso é a relação entre o penúltimo e último nome próprio
          if($countAux == $count-1){                                                        #se a relação de parentesco pertencer ao nome próprio no indice do array
              verifica_relacao($pessoas[$a],$sPers,$1);
          }
          else{
              verifica($pessoas[$a], $sPers);
          }
        }
        else{
          verifica($pessoas[$a], $sPers);
        }
        $countAux++;
      }
    }
    else{
      if($tudo =~ /($par)/){                                                                #se tiver 2 nomes, e tiverem parentesco
        verifica_relacao($fPers,$sPers,$1);;
      }
      else{
        verifica($fPers, $sPers);
      }
    }
  }
  s/_//g;
}

my %sortedHash;
my %sortedHashP;
my %verify;
my $newTuple;

my $i = 20;
my $union;

#print "As relações de parentesco são: \n";

#for (sort{$sortedHashP{$b} <=> $sortedHashP{$a}} keys %sortedHashP){
#    if(/($np)-($np)-($par)/g) {
#       $union = "$1-$3-$5";
#	     print "$1 -> $3 -> $5\n";
#    }
#    $i--;
#    if ($i eq 0) {last;}
#}

#$i = 20;

#print "As outras relações são: \n";

for (sort{$sortedHash{$b} <=> $sortedHash{$a}} keys %sortedHash){
    if(/($np)-($np)/g) {
       $union = "$1-$3";
	     print "$1 -> $3 -> $sortedHash{$union}\n";
    }
    $i--;
    if ($i eq 0) {last;}
}


#verifica se o tuplo de Nomes proprios que se relacionam já apareceram anteriormente -- caso em que existe relação
sub verifica_relacao {
  my $tempVr;
  my $tempVr2;
  my ($p1, $p2, $r) = @_;
  $tempVr = "$p2-$p1-$r";
  $tempVr2 = "$p1-$p2";
  if ($sortedHashP{$tempVr}) {
    $sortedHashP{$tempVr}++;
  }
  else {
    $tempVr = "$p1-$p2-$r";
    $sortedHashP{$tempVr}++;
    $verify{$tempVr2}++;
  }
}

#verifica se o tuplo de Nomes proprios que se relacionam já apareceram anteriormente
sub verifica {
  my $tempV;
  my $tempV2;
  my ($p1, $p2) = @_;
  $tempV = "$p2-$p1";
  $tempV2 = "$p1-$p2";
  if (!$verify{$tempV} & !$verify{$tempV2}) {
    if ($sortedHash{$tempV}) {
      $sortedHash{$tempV}++;
    }
    else {
      $tempV = "$p1-$p2";
      $sortedHash{$tempV}++;
    }
  }
}

#print $graph->as_html_file( );
