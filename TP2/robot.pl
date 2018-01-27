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

for(keys %rules){
	print "$_\n";
}

#Proceder à comparação de perguntas, às regras.
while(<STDIN>){
	my $string;
	my $counter = 0;
	my @arrayQuest;
	#Lemmatizar e tokanizar a pergunta do utilizador
	my @output = qx{echo '$_' | analyze -f /usr/local/share/freeling/config/pt.cfg};
	for (@output){
		if($_){ 		#para retirar possiveis \n que tenha
			/.*? (.*?) .*/;
			push @arrayQuest, $1;
		}
	}

	#Comparar a pergunta às rules
	for my $key(keys %rules){
		my $valorComp;
		my $keyOri = $key;
		my @arrayRule;
		my @palavrasIguais;

		#Segmenting/tokenizing a Rule
		while($key =~ /(.*?) (.*)/){
			push @arrayRule, $1;
			$key = $2;
		}

		for(@arrayQuest){
			
		}

	}
}