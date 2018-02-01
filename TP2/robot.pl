use strict;
use threads;
use threads::shared;
use LWP::UserAgent;
use utf8::all;
use Unicode::Normalize;

my %rulesAux; #O que suporta as regras iniciais
my %rules:shared; #O que vai suportar as regras aquando aplicada a lemmatização

my @threads;
my $rule;
my $answer;
my $input;
my $resposta; #Se o bot já respondeu ou não.

my $PM = qr{[A-ZÁÀÃÉÊÚÍÓÕÇ]|[a-záàãéêúíóõç]+};
my $de = qr{d[aoe]s?};
my $s = qr{[\n ]};
my $np = qr{$PM ($s $PM| $PM)*}x;
my @pickUpLines = ("\n-> Muito bem. Que mais queres falar?\nMe: ",
										"\n-> Continuo à tua disposição para qualquer coisa.\nMe: ",
										"\n-> Estas não são as únicas informações que eu posso disponibilizar! Existem muitas mais!\nMe: ");


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
		while($aux =~ /(["',.!?()+*]|($PM+)[ -]?)(.*)/){
			$raw[$counter++]= $1;
			$aux = $3;
		}
		my @output = qx{echo '$key' | analyze -f /usr/local/share/freeling/config/pt.cfg};
		$counter = 0;
		for (@output){
			if($_){ 		#para retirar possiveis \n que tenha
				/.*? (.*?) .*/;
				my $aux = $1;
				if($raw[$counter] =~ /[A-Z]$PM*/){
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

print "--> Olá, queres conversar comigo?\nMe: ";

#Proceder à comparação de perguntas, às regras.
while(<STDIN>){
	$resposta = 0;
	my $string;
	my $aux = $_;
	my $counter = 0;
	my %arrayQuest;
	my @raw;
	#Lemmatizar e tokanizar a pergunta do utilizador
	while($aux =~ /(["',.!?()+*]|($PM+) ?)(.*)/){
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
			if($raw[$counter] =~ /[A-ZÁÀÃÉÊÚÍÓÕÇ]\w*/){
				$arrayQuest{$counter++} = ucfirst($aux);
			}
			else{
				$arrayQuest{$counter++} = $aux;
			}
		}
	}

	for my $counter (keys %arrayQuest){
		my $indice;

		#Turismo
		if($arrayQuest{$counter} =~ /([Cc]idade|[Tt]urismo|[Ll]ocal|[Cc]onhecer|[Vv]isitar|[Ii]nformação)/){
			$indice = $counter;
			while(!($arrayQuest{++$indice} =~ /[A-ZÁÀÃÉÊÚÍÓÕÇ].*/) & $indice != scalar keys %arrayQuest){}
			if($indice != (scalar keys %arrayQuest)){
				my $nome = $arrayQuest{$indice};
				turismo($nome);
				$resposta = "1";
			}
		}
		#Meteorologia
		if($arrayQuest{$counter} =~ /([Tt]empo|[Mm]eteorologia|[Tt]emperatura|[Tt]emperaturas|[Mm]eteorológico|[Mm]eteorologia|[Ii]nformação)/){
			$indice = $counter;
			while(!($arrayQuest{++$indice} =~ /[A-ZÁÀÃÉÊÚÍÓÕÇ].*/) & $indice != scalar keys %arrayQuest){}
			if($indice != (scalar keys %arrayQuest)){
				my $nome = $arrayQuest{$indice};
				#Retirar acentos
				$nome = NFKD($nome);
				$nome =~ s/\p{NonspacingMark}//g;
				#Colocar as palavras a minúsculo
				$nome =~ y/[A-Z]_/[a-z]-/;
				weather($nome);
				$resposta = "1";
			}
		}
		#Biografia
		if($arrayQuest{$counter} =~ /([Ii]nformação|[Qq]uem|[Bb]iografia)/){
			$indice = $counter;
			#Palavra chave : Quem é
			if($arrayQuest{$indice} =~ /quem/){
				for my $key(keys %arrayQuest){
					if($arrayQuest{$key} =~ /ser/ & $key > $indice){
						$indice = $key;
						while(!($arrayQuest{++$indice} =~ /[A-ZÁÀÃÉÊÚÍÓÕÇ].*/) & $indice != scalar keys %arrayQuest){}
						if($indice != (scalar keys %arrayQuest)){
							my $nome = $arrayQuest{$indice};
							my $nomeCaps;			#Nome com as letras iniciais maiúscilas
							while($nome =~ /(.*?)_(.*)/){
								$nome = $2;
								$nomeCaps = join('', $nomeCaps, ucfirst($1), "_");
							}
							$nomeCaps = join('', $nomeCaps, ucfirst($nome));
							personInfo($nomeCaps);
							$resposta = "1";
						}
					}
				}
			}
			#Todas as outras
			else{
				while(!($arrayQuest{++$indice} =~ /[A-ZÁÀÃÉÊÚÍÓÕÇ].*/ & $indice != scalar keys %arrayQuest)){}
				if($indice != (scalar keys %arrayQuest)){
					my $nome = $arrayQuest{$indice};
					my $nomeCaps;			#Nome com as letras iniciais maiúscilas
					while($nome =~ /(.*?)_(.*)/){
						$nome = $2;
						$nomeCaps = join('', $nomeCaps, ucfirst($1), "_");
					}
					$nomeCaps = join('', $nomeCaps, ucfirst($nome));
					personInfo($nomeCaps);
					$resposta = "1";
				}
			}
		}
		#Noticias
		if($arrayQuest{$counter} =~ /([Nn]oticiar|[Ii]nformação)/){
			$indice = $counter;
			while(!($arrayQuest{++$indice} =~ /[A-ZÁÀÃÉÊÚÍÓÕÇ].*/) & $indice != scalar keys %arrayQuest){
			}
			my $nome;
			if($indice != (scalar keys %arrayQuest)){
				$nome = $arrayQuest{$indice};
				$nome =~ y/[A-ZÁÀÃÉÊÚÍÓÕÇ]_/[a-zaaaeeuiooç]-/;
				noticias($nome, 0);
				$resposta = "1";
			}
			else{
				$nome = "Mundo";
				noticias($nome, 1);
				$resposta = "1";
			}
		}
		last if($resposta == "1");

	}
	if($resposta == "0"){
		regras(\%rules, \%arrayQuest);
	}

}

sub regras{
	my ($rules, $arrayQuest) = @_;

	my $valorComp = 0;	#Valor de comparação da string
	my $keyOri;			#Chave original, sem ser alterada
	my $answer;			#Resposta a ser dada pelo bot
	my $nPal=0;
	#Comparar a pergunta às rules
	for my $key(keys %$rules){
		$keyOri = $key;
		my %arrayRule;		#Array que vai conter as palavras tokenizadas da regra a comparar
		my $counterR = 0;	#Contador para percorrer as regras
		my $valorCompAux = 0;		#Valor de comparação auxiliar que vai servir para comparar com o valor de comparaçao das outras regras
		my $counterQ = 0;			#Contador que vai percorrer a pergunta
		my %arrayI;					#Posição das palavras nas regras (-3 caso não existam), para adicionar bónus de palavras seguidas, e para ter em conta palavras repetidas

		#Segmenting/tokenizing a Rule
		while($key =~ /(.*?) (.*)/){
			$arrayRule{$counterR} = $1;
			$arrayRule{$counterR++} =~ y/[A-Z]/[a-z]/;
			$key = $2;
		}

		#Percorrer todas as palavras da pergunta
		while($counterQ != scalar keys %$arrayQuest){
			$arrayQuest->{$counterQ} =~ y/[A-Z]/[a-z]/;
			$counterR = 0;
			#Percorrer todas as palavras da rule, até encontrar uma palavra igual à da pergunta
			while($arrayQuest->{$counterQ} cmp $arrayRule{$counterR} || exists $arrayI{$counterR}){
				my $teste = $arrayQuest->{$counterQ} cmp $arrayRule{$counterR};
				last if($counterR == scalar keys %arrayRule);
				$counterR++;
			}
			#Se encontrou uma palavra igual
			if($counterR != (scalar keys %arrayRule)){
				$arrayI{$counterR} = $counterQ;
				my $c1 = $counterQ-1;
				my $c2 = $counterQ-2;
				#Se alguma das 2 palavras anteriores for igual na regra e na pergunta
				$valorCompAux+=2 if($arrayI{$counterR-1} =~ /($c1|$c2)/ || $arrayI{$counterR-2} =~ /($c1|$c2)/);
				$valorCompAux+=1;
			}
			#Proxima palavra
			$counterQ++;
		}

		#Se tiver mais pontos de comparação.
		if($valorCompAux > $valorComp){
			#Guarda o valor de comparação, a resposta e o número de palavras da rule
			$valorComp = $valorCompAux;
			$answer = $rules->{$keyOri};
			$nPal = (scalar keys %arrayRule) -1;
		}
		#Se tiver os mesmos pontos de comparação, é escolhido
		#O texto que tiver menos palavras.
		if($valorCompAux == $valorComp){
			#Se a rule tiver menos palavra que a antiga
			if((scalar keys %arrayRule) - 1 < $nPal){
				#Guarda o valor de comparação, a resposta e o número de palavras da rule
				$valorComp = $valorCompAux;
				$answer = $rules->{$keyOri};
				$nPal = (scalar keys %arrayRule) -1;
			}
		}
	}
	my $line;
	my $val = ($nPal + ($nPal-1)*2)*0.3;
	if($valorComp > $val){
		print "\n-> $answer\nMe: ";
	}
	else{
		srand;
		open FILE, "<proverbios.txt" or die "Could not open filename: $!\n";
		rand($.)<1 and ($line=$_) while <FILE>;
		close FILE;
		print "\n-> $line\Me: ";
	}
}

sub turismo{
	my @prefixos = ("\n-> Ah, ", "");
	my @sufixos = (" tem muitos locais túristicos que podes visitar.\n", " belo sitio para passar férias.\n", " podes passar um bom tempo lá.\n");
	my @locais;
	my ($nome) = @_;

	my $url = join('', "http://www.google.com/search?hl=pt&q=", $nome, "_Principais_Locais&ie=UTF-8");
	my $results = qx(curl -sA "Chrome" -L '$url' | iconv -f iso8859-1 -t utf-8);
	while($results =~ /,<br>(.*?)<\/span>(.*)/){
		push @locais, $1;
		$results = $2;
	}

	if(scalar @locais != 0){
		my $rand = int(rand(scalar @prefixos -1));
		print $prefixos[$rand];
		while($nome =~ /(.*?)_(.*)/){
			print ucfirst("$1 ");
			$nome = $2;
		}
		print ucfirst("$nome,");
		$rand = int(rand(scalar @sufixos -1));
		print $sufixos[$rand];

		print "-> Aqui estão alguns locais que podes visitar:\n";
		my $counter = 0;
		while($counter < 10 & $counter != scalar @locais){
			print "  -- $locais[$counter++]\n";
		}
		print "\n-> Deseja conhecer mais locais?\nMe: ";
		$resposta = <STDIN>;
		$resposta =~ y/[A-Z]/[a-z]/;
		if($resposta =~ /sim/){
			print "\n-> Estes são os restantes locais turísticos que conheço:\n";
			while($counter != scalar @locais){
				print "  -- $locais[$counter++]\n";
			}
			print "\n";
		}
		$rand = int(rand(2));
		if (($rand % 2) eq 0) {
			$rand = int(rand(scalar @pickUpLines -1));
			print $pickUpLines[$rand];
		}
		else {
			print "\nMe: ";
		}
	}
	else{
		$resposta="0";
	}
}


sub weather{
	my $rand;
	my @day;
	my @temp;
	my $minimum;
	my $rand;
	my $city = shift;
	my $counter = 1;
	my @cold = ("\n-> Que frio! A temperatura mínima para hoje em $city é bastante baixa! ",
							"\n-> Atenção às temperaturas bastante baixas em $city! ");
	my @pleasant = ("\n-> Espera-se uma temperatura bastante amena hoje, em $city! ",
									"\n-> Temperaturas bastante amenas, no dia de hoje, em $city!" );
	my @hot = ("\n-> Atenção às altas temperaturas que se esperam para $city! ",
							"\n-> Vaga de calor em $city. Um verdadeiro dia de Verão! ");
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
	        	$info = "   Temperatura Máxima: $t ºC ------- Temperatura minima: $1 ºC\n";
	        	push(@temp, $info);
	        	undef $info;my $counter = 1;
						if ($counter eq 1) {
							$minimum = $1;
						}
	      	}
	      	$t = $1;
	      	$counter++;
	    }
	}
	if(scalar @temp != 0){
		print "\n-> Qual o intervalo de tempo que desejas consultar? (1 a 7 dias):\nMe:  ";
		my $time = <STDIN>;
		if ($minimum < 10) {
			$rand = int(rand(scalar @cold -1));
			print $cold[$rand];
		}
		elsif ($minimum >= 10 & $minimum <= 20) {
			$rand = int(rand(scalar @pleasant -1));
			print $pleasant[$rand];
		}
		else {
			$rand = int(rand(scalar @hot -1));
			print $hot[$rand];
		}
		print "Confere então as temperaturas:\n";
		for my $i (0 .. ($time-1)) {
		   	my $first  = $day[$i];
		   	my $second = $temp[$i];
		   	print "-- $first\n$second \n"
		}
		$rand = int(rand(2));
		if (($rand % 2) eq 0) {
			$rand = int(rand(scalar @pickUpLines -1));
			print $pickUpLines[$rand];
		}
		else {
			print "\nMe: ";
		}
	}
	else{
		$resposta="0";
	}
}

sub personInfo{
	my $rand;
	my @intro = ("\n-> Encontrei algumas informações que te podem ser úteis:\n",
							"\n-> Consegui recolher algumas informações, ora confere:\n");
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
			$rand = int(rand(scalar @intro -1));
			print $intro[$rand];
	    $info = $_;
	    print "[] $info.\n";
			$rand = int(rand(2));
			if (($rand % 2) eq 0) {
				$rand = int(rand(scalar @pickUpLines -1));
				print $pickUpLines[$rand];
			}
			else {
				print "\nMe: ";
			}
	}
	else {
		$resposta="0";
	 }
}

sub noticias{
	my $rand;
  	my $news;
  	my $counter = 1;
  	my $search = shift;
	my $tag = shift;
  	my $url = join('', "http://www.google.pt/search?q=", $search, "+noticias&source=lnms&tbm=nws&sa=X&ved");
  	my $results = qx(curl -sA "Chrome" -L '$url' | iconv -f iso8859-1 -t utf-8);
	if ($tag eq 0) {
			print "\n-> Algumas das principais noticias sobre $search:\n\n";
	}
	else {
		print "\n-> Algumas das principais noticias da atualidade:\n\n";
	}
	while($results =~ /class="st">(.*?)\./g){
    	$_ = $1;
		if ($1) {
	   		s/<.*?>//g;
	   		s/\[[0-9]+\]//g;
	   		$news = $_;
	   		print "[$counter] $news.\n\n";
	   		$counter++;
	   		if ($counter eq 5) {
	   			last;
    		}
		}
		else {
			$resposta="0";
		}
  	}
	$rand = int(rand(2));
	if (($rand % 2) eq 0) {
		$rand = int(rand(scalar @pickUpLines -1));
		print $pickUpLines[$rand];
	}
	else {
		print "\nMe: ";
	}
}
