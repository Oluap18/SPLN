#!/usr/bin/perl

use Graph::Easy;
use strict;
use warnings;
use utf8::all;


my $graph = Graph::Easy->new();													#inicia grafo
my $i=0;																		#Número de relações
my %sortedHash;																	#Armazena as relações antes de ser representadas no grafo
my $union;																		#forma key para hash no formato "NP1-NP2"
my $pessoa;																		#guarda qualquer occorência de nome proprio entre o primeiro e último nome próprio da regex
my $fPers;																		#primeiro nome proprio da regex
my $uPers;																		#último nome proprio da regex
my $resto;																		#Texto entre 2 nomes próprios

my $PM = qr{[A-ZÁÀÃÉÊÚÍÓÇ][a-záàãéêúíóç]+};										#palavra maiúscula
my $de = qr{d[aoe]s?};															#conector - ex: "de,da,do"
my $s = qr{[\n ]};																#space or new line
my $Pre = qr{Sr\. |Sra\. |Dr\. |Dra\. |Eng\. |Miss\. |Mr\. };					#Prefixos associados a um nome próprio
my $np = qr{$Pre? $PM ($s $PM|$s $de $s $PM)*}x;								#nome proprio completo
my $pal = qr{[\wáàãéêúíóç]+};													#palavra
my $all = qr{.*};																#Maior match de qualquer coisa
my $allP = qr{.*?};																#Menos match de qualquer coisa

print "Quantas personagens deseja verificar as suas relações?\n";
$i = <STDIN>;


while(<>){
	#Tratamento dos nomes próprios válidos
	s/(^|[\n]|[?!.;:]|['"«]|[-—]|^--)( ?)($PM)/$1$2_$3/g;						#Tratar dos casos que são considerados nomes próprios inválidos
	s/($Pre)(_)($np)/_$1_$3/g;													#Tratar dos casos que existem nomes próprios com prefixos
	s/(\b$np)/{$1}/g;															#Colocar os nomes próprios válidos entre {}
	s/(_)($Pre)(_)($np)/{$2$4}/g;												#Colocar os nomes próprios com prefixos entre {}

	#Encontrar relações entre os nomes próprios
	while(/{($np)}($all){($np)}/g){
		my %pessoas;
		$fPers = $1;															#Guardar o primeiro nome próprio da regex
		$uPers = $4;															#Guardar o último nome próprio da regex
		$resto = $3;															#guarda todo o conteudo entre o primeiro e último nome próprio
		$pessoas{$fPers}++;														#guarda todas as ocorrências de nomes próprios
		#Se tiver mais que 2 nomes próprios
		if($resto =~ /{($np)}/) {												#Verifica se existe um nome próprio entre o primeiro e último nome próprio
			while($resto =~ /($allP) \{($np)\}($all)/){							#Trata todos os nomes próprios entre o primeiro e último nome próprio
				$pessoa = $2;
				if(!exists $pessoas{$pessoa}){									#Evita guardar pessoas "repetidas" no regex, para apenas relacionar 1 vez a pessoa com as outras
					foreach my $key (keys %pessoas){							#Percorre as pessoas que precedem a $Pessoa, relacionando-as com esta
						verifica($key, $pessoa);								#Insere a pessoa na hash
					}
					$pessoas{$pessoa}++; 										#Guarda a pessoa na hash para relacionar com as seguintes
				}
				$resto = $4;													#itera o ciclo para procurar mais pessoas
			}
			if(!exists $pessoas{$uPers}){										#Verifica se a última pessoa da regex já foi mencionada
				foreach my $key (keys %pessoas){
					verifica($key, $uPers);										#Relaciona a última pessoa da regex com as que precedem esta
				}
			}
		}
		#Se tiver só 2 nomes próprios
		else{
			verifica($fPers, $uPers);											#Caso só exista 2 nomes próprios, relaciona estes
		}
	}
	s/{($np)}/$1/g;																#Repõe o texto original
	s/_//g;																		#Repõe o texto original
}


#
for (sort{$sortedHash{$b} <=> $sortedHash{$a}} keys %sortedHash){				#ordena de forma decrescente a hash (de acordo com o valor correspondente a quantas vezes aparece a relação)
	if(/($np)-($np)/g) {														#decompoe a key para conseguir buscar os 2 nomes
		$union = "$1-$3";														#necessário para ir buscar o valor da key
		if ($1 !~ /$3/ && $3 !~ /$1/) {											#verifica se não está a relacionar 2 nomes proprios iguais
			$graph->add_edge ($1, $3);											#adiciona ao grafo os dois nodos e a ligação entre eles (função já verifica se existem ou não)
		}
	}
	$i--;
	if ($i eq 0) {last;}
}

open(my $fh, '>', 'result.html');

print $fh $graph->as_html_file( );
close $fh;

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
