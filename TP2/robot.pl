use strict;
use Lingua::Stem;

my %rules;

my $rule;
my $answer;
my $input;
my @token;

my $pal = qr{[\wáàãéêúíóç]+};	
my $stemmer = Lingua::Stem->new(-locale => 'pt');




#Guardar as regras. 
#Regras começadas por R: são regras.
#Regras começadas por A: são respostas. 
while(<>){

	#Guardar as regras
	$rule = $1 if(/R: (.*)/);
	#Guardar as repostas
	if(/A: (.*)/){
		$answer = $1;
		$rules{$rule}=$answer;
	}
}

my $pid = open(my $fh, "analyze -f /usr/local/share/freeling/config/pt.cfg --flush");

if($pid){
	system("echo Ola");
	print $fh;
}

for my $key (keys %rules){
	my $string;
	#Segmenting/tokenizing a Regra
	while($key =~ /($pal|["\.!?$\,;:]) ?(.*)/){
		print "[$1]\n";
		$string = join('', $string, "$1 ");
		$key = $2;
	}
}

while($input = <STDIN>){

	for my $key(keys %rules){
		my @arrayRule;
		my @arrayQuest;

		#Segmenting/tokenizing a Regra
		while($key =~ /($pal|["\.!?$\,;:]) ?(.*)/){
			print "[$1]\n";
			push @arrayRule, $1;
			$key = $2;
		}
		#Segmenting/tokenizing a Pergunta
		while($input =~ /($pal|[".!?$\,;:]) ?(.*)/){
			push @arrayQuest, $1;
			$input = $2;
		}
		print "@arrayRule\n";
		my $stemmed_words = $stemmer->stem(@arrayRule);
		print "@{$stemmed_words}\n";
	}
}

close($fh);
