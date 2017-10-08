#!/usr/bin/perl
use strict;
use warnings;
use feature 'say';
use utf8;
use XML::LibXML;
use XML::LibXML::XPathContext;
use DBI;
use Term::ANSIColor qw{ :constants };
my $filename;
my @source_files = glob ("*.xml");
no warnings "experimental::autoderef";
no warnings 'utf8';
my $id = 0;
use Data::Dumper;
say GREEN, "Please enter your MySQL user name",RESET;
my $username = <STDIN>;
say GREEN, "Please enter your MySQL password",RESET;
my $password = <STDIN>;
say GREEN, "Name Your Datbase",RESET;
my $db = <STDIN>;
chomp $username;
chomp $password;
chomp $db;
my $dsn = "DBI:mysql:Driver={SQL Server}";
my %attr = (PrintError=>0, RaiseError=>1);
my $dbh = DBI->connect($dsn,$username,$password, \%attr);
$dbh->{mysql_enable_utf8} = 1;
my @ddl = (

	"CREATE DATABASE IF NOT EXISTS $db;",
		
	"USE $db;",
	"CREATE TABLE IF NOT EXISTS data (
	id mediumint,
	title mediumtext,
	author varchar(255),
	shop mediumtext,
	loc varchar(255), 
	date smallint,
	pub mediumtext,
	keywords varchar(255), 
	dub tinyint
	         ) ENGINE=InnoDB;",

	"CREATE TABLE IF NOT EXISTS sellers (
	id mediumint, 
	firstname varchar(255),
	lastname varchar(255)
	) ENGINE=InnoDB;",

	"CREATE TABLE IF NOT EXISTS printers (
	id mediumint, 
	firstname varchar(255),
	lastname varchar(255)
	) ENGINE=InnoDB;"


);

for my $sql(@ddl){
  $dbh->do($sql);
}  
say "All tables created successfully!";
say "Sorting...Hang on, this could take a while.";
our @books = get_books();
my $sql = "INSERT INTO data(id,title,author,shop,loc,date,pub,keywords,dub)
    VALUES(?,?,?,?,?,?,?,?,?)";
my $stmt = $dbh->prepare($sql);
    
foreach my $book(@books){
	if($stmt->execute($book->{id}, $book->{title}, $book->{author}, $book->{shop}, $book->{loc}, $book->{date}, $book->{pub}, $book->{keywords}, $book->{dub})){
    say "book $book->{title} inserted successfully";
	}
}

$sql = "INSERT INTO sellers(id,firstname,lastname)
    VALUES(?,?,?)";
    $stmt = $dbh->prepare($sql);
foreach my $book (@books) {
		my $id = $book->{id};
 	   my @AoA = $book->{sellers};	
  		foreach my $seller(@AoA){
  				foreach my $name (@{$seller}){
  					my $firstname = @$name[0];
  		 			my $lastname = @$name[1]; 
				 	if($stmt->execute($id, $firstname, $lastname)){
				 		say "for book $id seller $firstname $lastname inserted successfully";
				 	}

  				}
  		}
}

$sql = "INSERT INTO printers(id,firstname,lastname)
    VALUES(?,?,?)";
    $stmt = $dbh->prepare($sql);
foreach my $book(@books){

		my $id = $book->{id};
 	    my @AoA = $book->{printers};
 		foreach my $printer(@AoA){
			foreach my $name (@{$printer}){
				my $firstname = @$name[0];
	 			my $lastname = @$name[1]; 
				 if($stmt->execute($id, $firstname, $lastname)){
				 	say "for book $id printer $firstname $lastname inserted successfully";
				 }
			}
		}	
}


$stmt->finish();	
$dbh->disconnect();
say "Finished with everything !!!!!!!!!!!!!!";

sub get_books{
	foreach my $filename (@source_files) {
	my $dom = XML::LibXML->load_xml(location => $filename);
	my $xpc = XML::LibXML::XPathContext->new($dom);
	$xpc->registerNs('tei',  'http://www.tei-c.org/ns/1.0');
	my $title = $xpc->findnodes('//tei:sourceDesc//tei:title[1]');
	my $pub = $xpc->findnodes('//tei:sourceDesc//tei:publisher');
	my $author = $xpc->findnodes('//tei:sourceDesc//tei:author[1]');
	my $date = $xpc->findnodes('//tei:sourceDesc/tei:editionStmt/tei:edition/tei:date');
	my $keys = $xpc->findnodes('//tei:keywords/*');
	if (!$date){
		$date =	$xpc->findnodes('//tei:sourceDesc//tei:date');
		}

	$author = $author->to_literal();
	$pub = $pub->to_literal();
	$title = $title->to_literal();
	$id++;
	my $printerString;
	my $sellerString;
	my @printers;
	my @sellers;
	my $loc;
	my $shop;
	my $dub = 0;
	$pub =~ s/\[|\]//g;
	$pub =~ s/vv|VV/W/g;
	next if $pub =~ m/^s\.n/i;
	if ($pub =~ /(wynk|de Worde)/i){
			$printerString = "Wynkyn deWorde";		
		}elsif($pub =~ /(N\w*\.?,? (and|&) [IJ]\w*\.? Okes)/i){
			$printerString = "Nicholas Okes and John Okes";
		}elsif($pub =~ m/^(([Ii]m|[Re])?[Pp]r[yi]nted)? ?[Bb]y (([A-Z]\w*\.?:? ?[A-Z]\w*\.?),?( ?(and)?)? ?(([A-Z]\w*\.?:? ?[A-Z]\w*\.?),?( ?(and)?)?)? ?(([A-Z]\w*\.?:? ?[A-Z]\w*\.?),?( ?(and)?)?)? ?(([A-Z]\w*\.?:? ?[A-Z]\w*\.?),?( ?(and)?)?)? ?(([A-Z]\w*\.?:? ?[A-Z]\w*\.?),?( ?(and)?)?)? ?(([A-Z]\w*\.?:? ?[A-Z]\w*\.?),?( ?(and)?)?)? ?(([A-Z]\w*\.?:? ?[A-Z]\w*\.?),?( ?(and)?)?)? ?(([A-Z]\w*\.?:? ?[A-Z]\w*\.?),?( ?(and)?)?)? ?(([A-Z]\w*\.?:? ?[A-Z]\w*\.?),?( ?(and)?)?)? ?(([A-Z]\w*\.?:? ?[A-Z]\w*\.?),?( ?(and)?)?)?)/){
		 	$printerString = $3;
		}elsif($pub =~ m/([Ee]xcudebat|[Ii]mpensis|[Tt]ypis|In (ae|æ)dibus) (([A-Z]\w*\.?:? ?[A-Z]\w*\.?),?( ?(and)?)? ?(([A-Z]\w*\.?:? ?[A-Z]\w*\.?),?( ?(and)?)?)? ?(([A-Z]\w*\.?:? ?[A-Z]\w*\.?),?( ?(and)?)?)? ?(([A-Z]\w*\.?:? ?[A-Z]\w*\.?),?( ?(and)?)?)? ?(([A-Z]\w*\.?:? ?[A-Z]\w*\.?),?( ?(and)?)?)? ?(([A-Z]\w*\.?:? ?[A-Z]\w*\.?),?( ?(and)?)?)? ?(([A-Z]\w*\.?:? ?[A-Z]\w*\.?),?( ?(and)?)?)? ?(([A-Z]\w*\.?:? ?[A-Z]\w*\.?),?( ?(and)?)?)? ?(([A-Z]\w*\.?:? ?[A-Z]\w*\.?),?( ?(and)?)?)? ?(([A-Z]\w*\.?:? ?[A-Z]\w*\.?),?( ?(and)?)?)?)/){
			$printerString = $2;
		}elsif($pub =~ m/English College Press/i){
			$printerString = "St Omer";
		}elsif($pub =~ m/English Secret Press/i){
			$printerString = "Secret Press";
		}elsif($pub =~ m/Birchley Hall Press/i){
			$printerString = "Birchley Press";
		}elsif($pub =~ m/of Stationers/i){
			$printerString = "Worshipful Stationers";				 				
		}elsif($pub =~ m/^((?!([Ff]or|[Ii]n|[Aa]t|[Pp][ea]r) )([A-Z]\w*\.?:? ?[A-Z]\w*\.?))/){
			$printerString = $1;
		}elsif($pub =~ m/(by me,?|in the house? of) ([A-Z]\w*\.?:? ?[A-Z]\w*\.?)/i){
			$printerString = $2;
		}elsif($pub =~ m/(([Ww][yi]dd?owe?|[Ee]xecutrix) ?(of [A-Z]\w*\.?:?)? ([A-Z]\w*\.?))/i){
			my $surname = $4;
			$printerString = "Widow $surname";
		}elsif($pub =~ m/[Bb]y ([A-Z]\w*\.?:? ?[A-Z]\w*\.?)/){
			$printerString = $1;
		}



		if ($pub =~ m/[Ff]or (([A-Z]\w*\.?:? ?\w+\.?),?( ?(and)?)? ?(([A-Z]\w*\.?:? ?\w+\.?),?( ?(and)?)?)? ?(([A-Z]\w*\.?:? ?\w+\.?),?( ?(and)?)?)? ?(([A-Z]\w*\.?:? ?\w+\.?),?( ?(and)?)?)? ?(([A-Z]\w*\.?:? ?\w+\.?),?( ?(and)?)?)? ?(([A-Z]\w*\.?:? ?\w+\.?),?( ?(and)?)?)? ?(([A-Z]\w*\.?:? ?\w+\.?),?( ?(and)?)?)? ?(([A-Z]\w*\.?:? ?\w+\.?),?( ?(and)?)?)? ?(([A-Z]\w*\.?:? ?\w+\.?),?( ?(and)?)?)? ?(([A-Z]\w*\.?:? ?\w+\.?),?( ?(and)?)?)?)/){ 
			 	$sellerString = $1;
			}elsif($pub =~ m/[Ss]ou?lde? [Bb]y (([A-Z]\w*\.?:? ?\w+\.?),?( ?(and)?)? ?(([A-Z]\w*\.?:? ?\w+\.?),?( ?(and)?)?)? ?(([A-Z]\w*\.?:? ?\w+\.?),?( ?(and)?)?)? ?(([A-Z]\w*\.?:? ?\w+\.?),?( ?(and)?)?)? ?(([A-Z]\w*\.?:? ?\w+\.?),?( ?(and)?)?)? ?(([A-Z]\w*\.?:? ?\w+\.?),?( ?(and)?)?)? ?(([A-Z]\w*\.?:? ?\w+\.?),?( ?(and)?)?)? ?(([A-Z]\w*\.?:? ?\w+\.?),?( ?(and)?)?)? ?(([A-Z]\w*\.?:? ?\w+\.?),?( ?(and)?)?)? ?(([A-Z]\w*\.?:? ?\w+\.?),?( ?(and)?)?)?)/){
				$sellerString = $1;
			}elsif ($pub =~ m/([Ii]m-?|[Rr]e-?)?[Pp]r[yi]nted,?:?;? and ?((are)? to be)? sold,? by ?(me)?,? ?([A-Z]\w*\.?:? ?\w+\.?)?/){
				$sellerString = $5;
				$printerString = $5;
			}elsif ($pub =~ m/([Ii]m-?|[Rr]e-?)?[Pp]r[iy]nted,?:?;? by ([A-Z]\w*\.?:? ?\w+\.?)?,?:?;? and ?(are to be)? sold (by him|at his shop)/){
				$sellerString = $2;
				$printerString = $2;
			}

	if ($pub =~ m/(s(\w+)?t.?-? ?p\w+l\w+)/i)
		{$loc = "Saint Paul's";}
		elsif ($pub =~ m/(P[ao][uw]le?s)/i)
			{$loc = "Saint Paul's";}
		elsif ($pub =~ m/(s(\w+)?t.?-? mart\w+)/i)
			{$loc = "Saint Martin's";}
		elsif ($pub =~ m/(s(\w+)?t.?-? ?d[uo]nst\w+)/i)
			{$loc = "Saint Dunston's";}
		elsif ($pub =~ m/(s(\w+)?t.?-? ?marg\w+)/i)
			{$loc = "Saint Margarets's";}
		elsif ($pub =~ m/(s(\w+)?t.?-? ?mild\w+)/i)
			{$loc = "Saint Mildred's";}
		elsif ($pub =~ m/(s(\w+)?t.?-? ?pet\w+)/i)
			{$loc = "Saint Peter's";}								
		elsif ($pub =~ m/(s(\w+)?t.?-? ?aust\w+)/i)
			{$loc = "Saint Austin's";}
		elsif ($pub =~ m/Pater/i)
			{$loc = "Paternoster Row";}
		elsif ($pub =~ m/(fle?ete?-? ?st\w+)/i)
			{$loc = "Fleetstreet";}
		elsif ($pub =~ m/(fle?ete?-? ?b\w+)/i)
			{$loc = "Fleetbridge";}
		elsif ($pub =~ m/(L[ou]nd\w+-? ?br\w+)/i)
			{$loc = "London Bridge";}
		elsif ($pub =~ m/(roy\w+-? ?excha)/i)
			{$loc = "Royal Exchange";}
		elsif ($pub =~ m/(popes-? ?head-? ?al)/i)
			{$loc = "Pope's Head Alley";}
		elsif ($pub =~ m/((o|au)ld-? ?ba\w+)/i)
			{$loc = "Old Bailey";}
		elsif ($pub =~ m/(station\w+-? ?ha)/i)
			{$loc = "Stationer's Hall";}
	else {$loc =  "NULL";}
	
		if ($pub =~ m/ at the ?(s[iy]g?ne? of ?(the)?)? (.*?)( at | in | on | ne(e|a)?re? | by | without | [vu]nder | [vu]pper | lower | nexte? | o[uv]er | [vu]pon | bes[iy]d| a | ag(ai|ey|ay)nst | w[iy]th[iy]n (and|&) are |(?<! s)\. (?![[ij]o)|,|:|;|\[|\])/i){
		$shop = $3;
		}else{
		 	$shop = "NULL";
		}

	if ($date =~ m/(\d{4})/){
		$date = $1;
	}else{
		$date = 0;
	}
	
	if ($sellerString){
		 @sellers = &psStrings($sellerString);
	}else{
		 @sellers = ["NULL", "NULL"];
	}

	if ($printerString){
		 @printers = &psStrings($printerString);
	}else{
		 @printers = ["NULL", "NULL"];
	}

	

	$keys =~ s/Early works to 1[89]00|17th century|English|\W//g;
	$keys = substr ($keys,0,250);



			chomp(@printers, @sellers, $shop);
	my %book = (id=> $id, title=> $title, author=> $author, printers=> [@printers], sellers=>[@sellers], shop=>$shop, loc=>$loc, date=>$date, pub=>$pub, keywords=>$keys, dub=>$dub);
	push(@books,\%book);
	
  }
  return @books;
}

sub psStrings{
	my $psString = $_[0];
	my @psNames;

	$psString =~ s/\.|:|;/ /g;
	$psString =~ s/,and /,/g;
	$psString =~ s/ and /,/g;
    $psString  =~ s/ {2,}/ /g;
    my @tmp = split /,/, $psString;
	chomp @tmp;
	foreach my $tmp (@tmp){
		if ($tmp =~ m/\w+/){
 			my @psName = split / /, $tmp;
 			push @psNames, \@psName;

		}		
	}
return @psNames;	
}