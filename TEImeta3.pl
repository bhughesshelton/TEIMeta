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
my $dom;
my $dsn = "DBI:mysql:newbooks4";
use Data::Dumper;
say GREEN, "Please enter your MySQL user name",RESET;
my $username = <STDIN>;
say GREEN, "Please enter your MySQL password",RESET;
my $password = <STDIN>;
chomp $username;
chomp $password;
my %attr = (PrintError=>0, RaiseError=>1);
my $dbh = DBI->connect($dsn,$username,$password, \%attr);
$dbh->{mysql_enable_utf8} = 1;
my @ddl = (
 "
 CREATE TABLE IF NOT EXISTS data (
 title mediumtext,
 author varchar(255),
 printer varchar(255),
 seller varchar (255),
 shop mediumtext,
 loc varchar(255), 
 date varchar(255),
 pub mediumtext 
         ) ENGINE=InnoDB;"
);

for my $sql(@ddl){
  $dbh->do($sql);
}  
say "All tables created successfully!";
say "Sorting...Hang on, this could take a while.";
our @books = get_books();
my $sql = "INSERT INTO data(title,author,printer,seller,shop,loc,date,pub)
    VALUES(?,?,?,?,?,?,?,?)";
my $stmt = $dbh->prepare($sql);
    
foreach my $book(@books){
	if($stmt->execute($book->{title}, $book->{author}, $book->{printer}, $book->{seller}, $book->{shop}, $book->{loc}, $book->{date}, $book->{pub})){
    say "book $book->{title} inserted successfully";
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
	my $date = $xpc->findnodes('//tei:sourceDesc//tei:date[1]');
	$author = $author->to_literal();
	$pub = $pub->to_literal();
	$date = $date->to_literal();
	$title = $title->to_literal();
	my $printer;
	my $seller;
	my $loc;
	my $shop;
	$pub =~ s/\[|\]//g;
	$pub =~ s/vv|VV/W/g;

	if ($pub =~ /wynk/i)
		{$printer = "Wynkyn de Worde"}
		elsif($pub =~ m/^((im-?|re-?)?printed),?:?;? by (\w+\.?:? ?\w+)/i)
		 	 {$printer = $3;}
		elsif($pub =~ m/^by (\w+\.?:? ?\w+)/i)
			 {$printer = $1}
		elsif($pub =~ m/^([A-Z]\. [A-Z]\w+)/i)
			 {$printer = $1}		
		elsif($pub =~ m/by ([A-Z](\w+)?\.?:? \w+)/i)
			 {$printer = $1}
	else {$printer =  "NULL";}	

	
	if ($pub =~ m/for (\w+\.?:? ?\w+)/i) 
			{$seller = $1;}
		elsif($pub =~ m/^sold by (\w+\.?:? ?\w+)/i)
			{$seller = $1;}
		elsif ($pub =~ m/printed,?:?;? and ?(are to be)? sold,? by ?(me)?,? ?(\w+\.?:? ?\w+)?/i)
			{$seller = $3;
			$printer = $3;}
		elsif ($pub =~ m/printed,?:?;? by ?(\w+\.?:? ?\w+)?,?:?;? and ?(are to be)? sold (by him|at (his shop|the))/i)
			{$seller = $1;
			$printer = $1;}		
	else {$seller =  "NULL";}



	# if ($pub =~ m/printed,?:? and ?(are to be)? sold by ?(me)?,? ?(\w+\.? ?\w+)?/i){
	# 	$printer = $3;
	# 	$seller = $3;
	# }elsif($pub =~ m/printed by ?(\w+\.? ?\w+)? and ?(are to be)? sold by him/i){
	# 	$printer = $1;
	# 	$seller = $1;
	# }elsif ($pub =~ /sold by ?(\w+\.? ?\w+)?/i){
	# 	$seller = $1;
	# }elsif ($pub =~ m/for (\w+\.? ?\w+)/i){ 
	# 	$seller = $1;
	# }elsif ($printer eq ""){
	# 	if ($pub =~ /^by (\w+\.? ?\w+)/i){
	# 		$printer = $1;
	# 	}elsif ($pub =~ /printed by (\w+\.? ?\w+)/i){
	# 		$printer = $1;
	# 	}
	# }

	# if ($printer eq "")
	# {$printer = "NULL";}
	# if ($seller eq "")
	# {$seller =  "NULL";}			
	
	if ($pub =~ m/(s(\w+)?t.?-? ?p\w+l\w+)/i)
		{$loc = "Saint Paul's";}
		elsif ($pub =~ m/(P[ao][uw]le?s)/i)
			{$loc = "Saint Paul's";}
		elsif ($pub =~ m/(s(\w+)?t.?-? mart\w+)/i)
			{$loc = "Saint Martin's";}
		elsif ($pub =~ m/(s(\w+)?t.?-? ?dunst\w+)/i)
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
		elsif ($pub =~ m/(roy\w+-? ?exch)/i)
			{$loc = "Royal Exchange";}
		elsif ($pub =~ m/(popes-? ?head-? ?al)/i)
			{$loc = "Pope's Head Alley";}
		elsif ($pub =~ m/((o|au)ld-? ?ba\w+)/i)
			{$loc = "Old Bailey";}
		elsif ($pub =~ m/(station\w+-? ?ha)/i)
			{$loc = "Stationer's Hall";}
	else {$loc =  "NULL";}
	
	if ($pub =~ /the s[iy]g?ne? of ?(the)? (.*?)( at | in | on | ne(e|a)?re? | by | without | [vu]nder | [vu]pper | lower | next | o[uv]er | [vu]pon | bes[iy]d | a |,|\.|;)/i)
	{$shop = $2;}
	elsif ($pub =~ /sold at ?(his shop at)? the (.*?)( at | in | on | ne(e|a)?re? | by | without | [vu]nder | [vu]pper | lower | next | o[uv]er | [vu]pon |bes[iy]d| a |,|\.|;)/i)
	{$shop = $2;}
	# if ($shop =~ /P[ao]ul|chan[ct]er|exchang|shop|[vu]pper|lower|ente?r|temple gate|next/i)
	# {$shop = "NULL";}
	
	if ($date =~ m/(\d+)/)
		{$date = $1;}	
	my %book = (title=> $title, author=> $author, printer=> $printer, seller=>$seller, shop=>$shop, loc=>$loc, date=>$date, pub=>$pub);
	push(@books,\%book);
	
  }
  return @books;
  }
	


			
			

		

