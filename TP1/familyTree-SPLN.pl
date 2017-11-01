#!/usr/bin/perl

use Graph::Easy;
use strict;
use warnings;
use utf8::all;

my $graph = Graph::Easy->new();
my $i=30;
my %sortedHash;
my %sortedHashP;
my %verify;
my $newTuple;
my $union;
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
my $s = qr{[\n ]}; 
my $Pre = qr{Sr\. |Sra\. |Dr\. |Dra\. |Eng\. |Miss\. |Mr\. };                                                                         #space or new line
my $np = qr{$Pre? $PM ($s $PM|$s $de $s $PM)*}x;                                                  #nome proprio completo
my $pal = qr{[\wáàãéúíóç]+};                                                                          #palavra [a-zA-Z_0-9]+
my $all = qr{.*};
my $allP = qr{.*?};

while(<>){
  	s/(^|[\n]|[?!.;:]|['"«]|[-—]|^--)( ?)($PM)/$1$2_$3/g;
  	s/($Pre)(_)($np)/_$1_$3/g;																#Tratar dos casos que existem prefixos
  	s/(\b$np)/{$1}/g;
  	s/(_)($Pre)(_)($np)/{$2$4}/g;

  	while(/{($np)}($all){($np)}/g){
	    my %pessoas;
	    $fPers = $1;   
	    $sPers = $4;          
	    $tudo = $3;                                                                             #guarda todo o conteudo entre os nomes próprios
	    $pessoas{$fPers}++;

	    if($tudo =~ /{($np)}/){
	      	while($tudo =~ /($allP) \{($np)\}($all)/){
		        $pessoa = $2;
		        if(!exists $pessoas{$pessoa}){
			        foreach my $key (keys %pessoas){
					    verifica($key, $pessoa);
				   	}
			      	$pessoas{$pessoa}++; 		     
			    }                                                   #guardar os nomes próprios
			    $tudo = $4;                                         #iterar o ciclo
		    }
		    if(!exists $pessoas{$sPers}){
			    foreach my $key (keys %pessoas){
			       	verifica($key, $sPers);
			    }
		    }
		}
		else{
		  	verifica($fPers, $sPers);
	    }
	}
	s/{($np)}/$1/g;
	s/_//g;
}

#print "As outras relações são: \n";

for (sort{$sortedHash{$b} <=> $sortedHash{$a}} keys %sortedHash){
    if(/($np)-($np)/g) {
       $union = "$1-$3";
       if ($1 !~ /$3/ && $3 !~ /$1/) {
          $graph->add_edge ($1, $3);
	      #print "$1 -> $3 -> $sortedHash{$union}\n";
       }
    }
    $i--;
    if ($i eq 0) {last;}
}

#my $DOT;
#my $graphviz = $graph->as_graphviz();
#open $DOT, '|dot -Grankdir=LR -Tpng -o graph.png' or die ("Cannot open pipe to dot: $!");
#print $DOT $graphviz;
#close $DOT;
print $graph->as_html_file( );

#verifica se o tuplo de Nomes proprios que se relacionam já apareceram anteriormente
sub verifica {
  	my $tempV;
  	my $tempV2;
  	my ($p1, $p2) = @_;
  	$tempV = "$p2-$p1";
  	$tempV2 = "$p1-$p2";
    if ($sortedHash{$tempV}) {
      	$sortedHash{$tempV}++;
    }
    else {
      	$sortedHash{$tempV2}++;
    }
}
