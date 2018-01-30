use strict;
use threads;
use threads::shared;

my %rulesAux; #O que suporta as regras iniciais
my %rules:shared; #O que vai suportar as regras aquando aplicada a lemmatização

my @threads;
my $rule;
my $answer;
my $input;
my $topico; #Modo do bot. $1 = Turismo. $0 = Regras.

my $PM = qr{[A-ZÁÀÃÉÊÚÍÓÇ]|[a-záàãéêúíóç]+};
my $de = qr{d[aoe]s?};
my $s = qr{[\n ]};
my $np = qr{$PM ($s $PM| $PM)*}x;

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
	my $aux = $key;
	my $counter = 0;
	my $string;
	my @raw;
	push @threads, async{
		while($aux =~ /(["',.!?()+*]|(\w+) ?)(.*)/){
			$raw[$counter++]= $1;
			$aux = $3;
		}
		my @output = qx{echo '$key' | analyze -f /usr/local/share/freeling/config/pt.cfg};
		$counter = 0;
		for (@output){
			if($_){ 		#para retirar possiveis \n que tenha
				/.*? (.*?) .*/;
				my $aux = $1;
				if($raw[$counter] =~ /[A-Z]\w*/){
					$string = join('', $string, ucfirst($aux), " ");
				}
				else{
					$string = join('', $string, "$aux ");
				}
				$counter++;
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
	$topico = 0;
	my $string;
	my $aux = $_;
	my $counter = 0;
	my %arrayQuest;
	my @raw;
	#Lemmatizar e tokanizar a pergunta do utilizador
	while($aux =~ /(["',.!?()+*]|(\w+) ?)(.*)/){
		$raw[$counter++]= $1;
		$aux = $3;
	}
	my @output = qx{echo '$_' | analyze -f /usr/local/share/freeling/config/pt.cfg};
	$counter = 0;
	chomp(@output);
	for (@output){
		if($_){ #Chomp tira todos por alguma razão
			/.*? (.*?) .*/;
			my $aux = $1;
			if($raw[$counter] =~ /[A-Z]\w*/){
				$arrayQuest{$counter++} = ucfirst($aux);
			}
			else{
				$arrayQuest{$counter++} = $aux;
			}
		}
	}

	#Secção do turismo
	for(keys %arrayQuest){
		my $indice;
		if($arrayQuest{$_} =~ /(cidade|turismo|local|conhecer|visitar)/){
			$indice = $_;
			turismo(\%arrayQuest, $indice);
			$topico = "1";	#Resposta dada pela vertente do turismo do bot.
			last;
		}
	}

	if($topico == "0"){
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
}

sub turismo{
	my ($arrayQuest, $indice) = @_;
	while(!($arrayQuest->{++$indice} =~ /[A-Z].*/)){}
			if($indice != (scalar keys %$arrayQuest)){
				my $nome = $arrayQuest->{$indice++};
				my $url = join('', "http://www.google.com/search?hl=pt&q=", $nome, "_Principais_Locais&ie=UTF-8");
				my $results = qx(curl -sA "Chrome" -L '$url');
				while($results =~ /,<br>(.*?)<\/span>(.*)/){
					print "$1\n";
					$results = $2;
				}
			}
}

#palavras-chave - tempo, meteorologia, temperatura, temperaturas, condições meteorológicas
# recebe como argumento o nome da cidade, em minusculas
sub weather{
  my @day;
  my @temp;
  my $city = shift;
  my $counter = 1;
  my $ua = new LWP::UserAgent;
  $ua->timeout(120);
  my $url="https://www.tempo.pt/$city.htm";
  my $request = new HTTP::Request('GET', $url);
  my $response = $ua->request($request);
  my $content = $response->content();
  open my $fh, "<", \$content;
  while(my $row = <$fh>) {
    while($row =~ /datetime="([0-9]{4})-([0-9]{2})-([0-9]{2})"/g) {
      push(@day,"$3-$2-$1");
    }
  }
  close $fh;
  open my $fh, "<", \$content;
  my $t;
  while(<$fh>) {
    while(/ (-?[0-9]+)&deg; /g) {
      my $info;
      if (($counter % 2) eq 0) {
        $info = "Temperatura Máxima: $t ºC \n Temperatura minima: $1 ºC\n";
        push(@temp, $info);
        undef $info;my $counter = 1;
      }
      else {
      }
      $t = $1;
      $counter++;
    }
  }
  print "Qual o intervalo de tempo que desejas? (1 a 7 dias): ";
  my $time = <STDIN>;
  for my $i (0 .. ($time-1)) {
    my $first  = $day[$i];
    my $second = $temp[$i];
    print "$first \n $second \n"
  }
}

#palavras-chave: informações, informação, Quem + verbo ser, biografia
#recebe o nome da pessoa, em qualquer formato (quer maiscula como miniscula)
sub personInfo{
  my $name = shift;
  my $info;
  $_ = $name;
  s/ +/_/g;
  $name = $_;
  my $ua = new LWP::UserAgent;
  $ua->timeout(120);
  my $url="https://pt.wikipedia.org/wiki/$name";
  my $request = new HTTP::Request('GET', $url);
  my $response = $ua->request($request);
  my $content = $response->content();
  open my $fh, "<", \$content;
  while(my $row = <$fh>) {
    if ($row =~ /<p><b>(.+)\.(.+)?<\/p>/) {
      $info = $1;
    }
  }
  $_ = $info;
  if ($info) {
    s/<.*?>//g;
    s/\[[0-9]+\]//g;
    print "$name\n";
    $info = $_;
    print "\n$info. \n \n \n";
  }
  else {
    print "Desculpa mas não consegui obter nenhuma informação.\n"
  }
}

#Se não for especificada o assunto da noticia, a variavel search deve ficar a "mundo" | 4 noticias neste momento
sub noticias{
  my $news;
  my $counter = 1;
  my $search = shift;
  my $url = join('', "http://www.google.pt/search?q=", $search, "+noticias&source=lnms&tbm=nws&sa=X&ved");
  my $results = qx(curl -sA "Chrome" -L '$url' | iconv -f iso8859-1 -t utf-8);
  while($results =~ /class="st">(.*?)\./g){
    $_ = $1;
    s/<.*?>//g;
    s/\[[0-9]+\]//g;
    print "Noticia $counter:\n";
    $news = $_;
    print "--> $news;\n\n";
    $counter++;
    if ($counter eq 5) {
      last;
    }
  }
}
