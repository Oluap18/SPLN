use strict;
use threads;
use threads::shared;

my %rulesAux; #O que suporta as regras iniciais
my %rules:shared; #O que vai suportar as regras aquando aplicada a lemmatização

my @threads;
my $rule;
my $answer;
my $input;

my $pal = qr{[\wáàãéêúíóç]+};	

#Guardar as regras. 
#Regras começadas por R: são regras.
#Regras começadas por A: são respostas. 
while(<>){

	#Guardar as regras
	$rule = $1 if(/R: (.*)/);
	#Guardar as repostas
	if(/A: (.*)/){
		$answer = $1;
		$rulesAux{$rule}=$answer;
	}
}
my $thread;
#Tokanizar e lemmatizar as regras
for my $key(keys %rulesAux){
	my $string;
	push @threads, async{
		my @output = qx{echo '$key' | analyze -f /usr/local/share/freeling/config/pt.cfg};
		for (@output){
			if($_){ 		#para retirar possiveis \n que tenha
				/.*? (.*?) .*/;
				$string = join('', $string, "$1 ");
			}
		}
		$rules{$string} = $rulesAux{$key};
	}
}

for(@threads){
	$_ -> join;
}

print "Ola, queres conversar comigo?\n";

#Proceder à comparação de perguntas, às regras.
while(<STDIN>){
	my $string;
	my $counter = 0;
	my %arrayQuest;
	#Lemmatizar e tokanizar a pergunta do utilizador
	my @output = qx{echo '$_' | analyze -f /usr/local/share/freeling/config/pt.cfg};
	for (@output){
		if($_){ 		#para retirar possiveis \n que tenha
			/.*? (.*?) .*/;
			$arrayQuest{$counter++} = $1;
		}
	}
	my $valorComp = 0;
	my $keyOri;
	my $answer;
	my $nPal = 0;
	#Comparar a pergunta às rules
	for my $key(keys %rules){
		$keyOri = $key;
		my %arrayRule;
		my $counterR = 0;
		my $valorCompAux = 0;
		my $counterQ = 0;
		my $valorBonus = 0;			#Valor de comparação bónus por ter palavras seguidas iguais

		chomp $key;
		#Segmenting/tokenizing a Rule
		while($key =~ /(.*?) (.*)/){
			$arrayRule{$counterR++} = $1;
			$key = $2;
		}
		#Percorrer todas as palavras da pergunta
		while($counterQ != (scalar keys %arrayQuest) - 1){
			$counterR = 0;
			#Percorrer todas as palavras da rule, até encontrar uma palavra igual à da pergunta
			while(!($arrayQuest{$counterQ} =~ /\Q$arrayRule{$counterR}\E/)){
				$counterR++;
			}
			#Se encontrou uma palavra igual
			if($counterR != (scalar keys %arrayRule) -1){
				print "$arrayRule{$counterR}\n";
				#Somar o valor de comparação bónus das palavras seguidas, mais o facto de a palavra ser igual
				$valorCompAux+=$valorBonus+1;
				$valorBonus++;
			}
			#Se não encontrou
			else{
				$valorBonus--;
			}
			#Proxima palavra
			$counterQ++;
		}
		my $teste = (scalar keys %arrayRule) -1;
		#Se tiver mais pontos de comparação.
		if($valorCompAux > $valorComp){
			#Guarda o valor de comparação, a resposta e o número de palavras da rule
			$valorComp = $valorCompAux;
			$answer = $rules{$keyOri};
			$nPal = (scalar keys %arrayRule) -1;
		}
		#Se tiver os mesmos pontos de comparação, é escolhido
		#O texto que tiver menos palavras.
		if($valorCompAux == $valorComp){
			#Se a rule tiver menos palavra que a antiga
			if((scalar keys %arrayRule) - 1 < $nPal){
				#Guarda o valor de comparação, a resposta e o número de palavras da rule
				$valorComp = $valorCompAux;
				$answer = $rules{$keyOri};
				$nPal = (scalar keys %arrayRule) -1;
			}
		}
	}
	my $line;
	print "$answer\n" if($valorComp != 0);
	if($valorComp == 0){
		srand;
		open FILE, "<proverbios.txt" or die "Could not open filename: $!\n";
		rand($.)<1 and ($line=$_) while <FILE>;
		close FILE;
		print "$line";
	}
}