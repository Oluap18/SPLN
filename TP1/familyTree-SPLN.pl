#!/usr/bin/perl

use Graph::Easy;
use strict;
use warnings;
use utf8::all;

my $graph = Graph::Easy->new();																
my $i=30;																					#Número de relações
my %sortedHash;																				#Armazena as relações antes de ser representadas no grafo
my $union;
my $pessoa;                                                                               	#guarda qualquer occorência de nome proprio entre o primeiro e último nome próprio da regex
my $fPers;                                                                                	#primeiro nome proprio da regex
my $uPers;																				  	#último nome proprio da regex
my $tudo;																					#Texto entre 2 nomes próprios

my $PM = qr{[A-ZÁÀÃÉÚÍÓÇ][a-záàãéúíóç]+};                                                   #palavra maiúscula
my $de = qr{d[aoe]s?};                                                                      #conector - ex: "de,da,do"
my $s = qr{[\n ]}; 
my $Pre = qr{Sr\. |Sra\. |Dr\. |Dra\. |Eng\. |Miss\. |Mr\. };                 				#Prefixos associados a um nome próprio                                                        #space or new line
my $np = qr{$Pre? $PM ($s $PM|$s $de $s $PM)*}x;                                            #nome proprio completo
my $pal = qr{[\wáàãéúíóç]+};                                                                #palavra
my $all = qr{.*};																			#Maior match de qualquer coisa
my $allP = qr{.*?};																			#Menos match de qualquer coisa

while(<>){
	#Tratamento dos nomes próprios válidos
  	s/(^|[\n]|[?!.;:]|['"«]|[-—]|^--)( ?)($PM)/$1$2_$3/g;									#Tratar dos casos que são considerados nomes próprios inválidos
  	s/($Pre)(_)($np)/_$1_$3/g;																#Tratar dos casos que existem nomes próprios com prefixos
  	s/(\b$np)/{$1}/g;																		#Colocar os nomes próprios válidos entre {}
  	s/(_)($Pre)(_)($np)/{$2$4}/g;															#Colocar os nomes próprios com prefixos entre {}

  	#Encontrar relações entre os nomes próprios
  	while(/{($np)}($all){($np)}/g){
	    my %pessoas;
	    $fPers = $1;																		#Guardar o primeiro nome próprio da regex
	    $uPers = $4;          																#Guardar o último nome próprio da regex
	    $tudo = $3;                                                                         #guarda todo o conteudo entre o primeiro e último nome próprio
	    $pessoas{$fPers}++;																	#guarda todas as ocorrências de nomes próprios											

	    if($tudo =~ /{($np)}/){																#Verifica se existe um nome próprio entre o primeiro e último nome próprio
	      	while($tudo =~ /($allP) \{($np)\}($all)/){										#Trata todos os nomes próprios entre o primeiro e último nome próprio
		        $pessoa = $2;
		        if(!exists $pessoas{$pessoa}){
			        foreach my $key (keys %pessoas){
					    verifica($key, $pessoa);
				   	}
			      	$pessoas{$pessoa}++; 		     
			    }                                                   #guardar os nomes próprios
			    $tudo = $4;                                         #iterar o ciclo
		    }
		    if(!exists $pessoas{$uPers}){
			    foreach my $key (keys %pessoas){
			       	verifica($key, $uPers);
			    }
		    }
		}
		else{
		  	verifica($fPers, $uPers);
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
