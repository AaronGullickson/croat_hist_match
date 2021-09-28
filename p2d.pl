############################
# p2d.pl                   #
# Aaron Gullickson         #
# Perl Script              #
# 1/16/2003                #
############################

####################################################
# This script will link the 200000 and 4000000 
# people (parents and spouses with no births) to their 
# potential deaths in the death record.  It will only
# be possible to link to deaths that have not already
# been linked from b2d. This script is run before m2d.pl.

require generalsubs;

&get_date_time;

$minage=15;
$maxage=120;
$maxrepage=60;
$mdate_ave=25;
$parentdate_ave=28;
$na="NA";

%weights = (
	    "age"    => 20,
	    "parish" =>  5,
	    "fn"     => 10,
	    "sx"     => 10,
	    "ln"     => 10,
	    "pob"    =>  5,
	    "pres"   =>  5,
	    "pbur"   =>  5,
	    "fnf"    => 10 #if it matches this a sure thing
	   );

#set up age range

#########################################
# read in data

$binfile="input/sortedbirths.tsv";
$marinfile="input/sortedmars.tsv";
$dinfile="input/sorteddeaths.tsv";
$b2dinfile="output/b2d.matches.tsv";
$m2binfile="output/m2b.matches.tsv";
$fulldatafile="output/fulldata.tsv";
#$prelimmatchfile="output/p2d.match.prelim.txt";
$finalmatchfile="output/p2d.matches.tsv";
$detailfile="output/diagnostics/p2d.diag.txt";
open (BIRIN,"<$binfile") || die ("cant open"." $binfile");
open (MARIN,"<$marinfile") || die ("cant open"." $marinfile");
open (DTHIN,"<$dinfile") || die ("cant open"." $dinfile");
open (B2D,"<$b2dinfile") || die ("cant open"." $b2dinfile");
open (M2B,"<$m2binfile") || die ("cant open "."  $m2binfile");
open (FULL,"<$fulldatafile") || die ("cant open"." $fulldatafile");
#open (PRELIM,">$prelimmatchfile") || die ("cant open "."$prelimmatchfile");
open (FINAL,">$finalmatchfile") || die ("cant open "."$finalmatchfile");
open (DETAIL, ">$detailfile") || die ("cant open "."$detailfile");

print ("Program name is p2d.pl\n");

print(DETAIL "Detail file for p2d.pl\n");
print(DETAIL "Program started on "."$daterun "."$yrrun"." at "."$timerun\n\n"); 


##########################################
# build hashes of remaining available deaths

print("Part I: Building Hashes\n");

%did_used=();
%death_hash=();
$deaths_avail=0;

#first cycle through the b2d file and exclude deaths that are already linked

foreach $line(<B2D>) {

  ($bid, $did, $score, $age, $ddate)=split("\t",$line);

  $did=~s/\s//g;

  if(&isnot_na($did)) {

    $did_used{$did}=1;

  }

}

foreach $line(<DTHIN>) {
  
  #split the line up into scalars
  
  ($dpar,$did1,$did2,$duni,$ddate,$dyyy,$dmm,$ddd,$dfn,$dsx,$dln,$dagey,$dagem,
	$daged,$fnr,$dtpr,$dpob,$dpor,$dpbur,$dmst,$lndu,$dfnf,
	$dfnh)=split("\t", $line);

  #make sure it is unused
  $did2=~s/\s//g;

  if($did_used{$did2}) {

    next;

  } else {

    $deaths_avail++;

    #create a key from first name, last 
    
    $dfn=~s/\s//g;
    $dln=~s/\s//g;

    $key="$dfn"."$dln";
    
    if(&isnotnull($key)) {
      
      push(@{$death_hash {$key}}, $line);
      
    }
    
  }

}

#build name and date hashes

%parentdate=();
%parentname=();
%parentname2=();

foreach $line(<BIRIN>) {

  ($bpar,$bid1,$bid2,$uni,$bdate,$byyy,$bmm,$bdd,$bfn,$bsx,$bfnf,$blnf,$bfnm,
	$blnm,$bpob,$bfng,$blng,$bpog) = split("\t",$line);
  
  #create this entry in the birth id hash

  $bid2=~s/\s//g;
  $bfnf=~s/\s//g;
  $blnf=~s/\s//g;
  $bfnm=~s/\s//g;
  $blnm=~s/\s//g;

  $parentdate{$bid2}=$bdate;
  $parentname{"$bid2"."m"}="$bfnf"."$blnf";
  $parentname{"$bid2"."f"}="$bfnm"."$blnm";
  $parentname2{"$bid2"."f"}="$bfnm"."$blnf";

}

%mardate=();
%marname=();
%marname2=();

foreach $line(<MARIN>) {
  
  chop $line;
  
  ($mpar,$mi,$mid,$muni,$myrdate,$myyy,$mmm,$mdd,$mfnh,$mlnh,$mmstath,
   $mageh,$mpoh,$mfnhfa,$mfnw,$mlnw,$mmstatw,$magew,$mpow,$mfnwrel,
   $mtypwrel,$mfnwit1,$mlnwit1,$mpowit1,$mfnwit2,$mlnwit2,$mpowit2,
   $mlnhfull,$mlnwfull,$mlnwit1full,$mlnwit2full,$mnamef,$mnames,
   $mmatchflag)=split("\t", $line);
  
  $mid=~s/\s//g;
  $mfnw=~s/\s//g;
  $mlnw=~s/\s//g;
  $mfnh=~s/\s//g;
  $mlnh=~s/\s//g;

  $mardate{$mid}=$myrdate;
  $marname{"$mid"."f"}="$mfnw"."$mlnw";
  $marname{"$mid"."m"}="$mfnh"."$mlnh";
  #for women also use last name of husband
  $marname2{"$mid"."f"}="$mfnw"."$mlnh";
  
}

  

foreach $line(<M2B>) {

  ($mid,$lastdate,$numkids,$kids)=split("\t", $line);

  $mid=~s/\s//g;

  #if no kids, marriage should be last data, fix that later

  if(&isnot_na($lastdate)) {

    $lastdate_hash{$mid} = $lastdate;

  } else {

    #if no lastdate for kids then give the date of the marriage

    $lastdate_hash{$mid} = $mardate{$mid};

  }

}


###########################################################
##Now match deaths

print("Part II: Initial Matching\n");

$unmatched=0;
$possible=0;
$prelim_match=0;
%croat=();

foreach $line (<FULL>) {

  chop $line;

  ($bid, $bdate, $sex, 
   $motherid, $fatherid, 
   $mid1, $mid2, $mid3, $mid4, $mid5, 
   $sid1, $sid2, $sid3, $sid4, $sid5,
   $mdate1, $mdate2, $mdate3, $mdate4, $mdate5, 
   $did, $ddate,
   $idk1,$idk2,$idk3,$idk4,$idk5,$idk6,$idk7,
   $idk8,$idk9,$idk10,$idk11,$idk12,$idk13,$idk14,
   $dobk1, $dobk2, $dobk3, $dobk4, $dobk5, $dobk6, $dobk7, $dobk8, 
   $dobk9, $dobk10, $dobk11, $dobk12, $dobk13, $dobk14, 
   $sidk1,$sidk2,$sidk3,$sidk4,$sidk5,$sidk6,
   $sidk7,$sidk8,$sidk9,$sidk10,$sidk11,$sidk12,$sidk13,$sidk14,
   $remark1,$remark2,$remark3,$remark4,$remark5,$remark6,
   $remark7,$remark8,$remark9,$remark10,$remark11,$remark12,$remark13,$remark14,
   $remarok1,$remarok2,$remarok3,$remarok4,$remarok5,$remarok6,$remarok7,
	 $remarok8,$remarok9,$remarok10,$remarok11,$remarok12,$remarok13,$remarok14,
   $park1,$park2,$park3,$park4,$park5,$park6,$park7,
   $park8,$park9,$park10,$park11,$park12,$park13,$park14)=split("\t", $line);

	 #is this the header line?
   if($bid eq "bid") {
     $header=$line;
     next;
   }

  $croat{$bid}=$line;

  $key2=();
  $firstevent=();

  #only take those who are not "real" people

  if($bid>=200000) {

    $possible++;

    #if there is a real marriage then get name from that

    if($mid1<30000) {

      $key=$marname{"$mid1"."$sex"};
      $bdate=$mardate{$mid1}-$mdate_ave;
      $firstevent=$mdate1;
      $maxrep=$maxage;

      if($sex=="f") {

	$key2=$marname2{"$idk1"."$sex"};
	$maxrep=$maxrepage;
	
      }
      
    } else {

      #get it from first kid

      $key=$parentname{"$idk1"."$sex"};
      $bdate=$parentdate{$idk1}-$parentdate_ave;
      $firstevent=$dobk1;
      $maxrep=$maxage;

      if($sex=="f") {

	$key2=$parentname2{"$idk1"."$sex"};
	$maxrep=$maxrepage;

      }
      
    }

    $lastdate=$lastdate_hash{$mid1};    

    #look for later last dates if subsequent marriages

    if(&isnot_na($mid2)) {

      $lastdate=$lastdate_hash{$mid2};    

    }

    if(&isnot_na($mid3)) {

      $lastdate=$lastdate_hash{$mid3};    

    }

    if(&isnot_na($mid4)) {

      $lastdate=$lastdate_hash{$mid4};    

    }

    if(&isnot_na($mid5)) {

      $lastdate=$lastdate_hash{$mid5};    

    }
    
    @array=@{$death_hash {$key}};

    #add links using husband's last name for women

    @array2 = @{$death_hash {$key2}};

    foreach $line(@array2) {

      push(@array, $line);

    }

    #get the date of the last child

    $dob = join("\t",$dobk1, $dobk2, $dobk3, $dobk4, $dobk5, $dobk6, $dobk7,
		$dobk8, $dobk9, $dobk10, $dobk11, $dobk12, $dobk13, $dobk14);
    
    $dob=~s/NA//g;
    
    @dob = split("\t", $dob);
    
    @dob = sort {$b<=>$a} @dob;
    
    $lastbirth = @dob[0];


    @temp=();
    $empty=1;

    foreach $ref(@array) {
    
      ($dpar,$did1,$did2,$duni,$ddate,$dyyy,$dmm,$ddd,$dfn,$dsx,$dln,$dagey,
			$dagem,$daged,$fnr,$dtpr,$dpob,$dpor,$dpbur,$dmst,$lndu,$dfnf,
			$dfnh)=split("\t", $ref);

      #no exact conditions to check since we don't know these people's exact age
      #wait - they can't die before they stop having kids, make sure that if age is imputed from 
      #death record, it doesn't make the women too young at her first event

      if($ddate>=$lastdate && ($ddate-$bdate)>$minage && ($ddate-$bdate)<$maxage) {

	($score,$dif,$raad)=&matchrecs;

	if($score>0) {
      
	  $answer=join("\t", $bid, $did2, $score, $ddate, $dif,$raad);
	  
	  push(@temp, $answer);
	  
	  $empty=0;
	  
	}    
      
      }
      
    }

    if($empty) {

      $unmatched++;
      
      #printf(PRELIM "%6d\t %s\t %s\t %s\t %s\n", $bid, $na, $na, $na);
      
    } else {

      $prelim_match++;
      
      foreach $ref(@temp) {
	
	($bid, $did, $score, $ddate, $dif, $raad)=split("\t", $ref);
	
	#printf(PRELIM "%6d\t %6d\t %6.3f\t %6.6f\n", $bid, $did, $score, $ddate);
	
	$linkline=join("\t",$score, $bid, $did, $ddate, $dif, $raad);

	push(@links, $linkline);
	

      }
      
    }
    
  }

}

############################################
#now sort and do final linking

#close and reopen croatdata

close FULL;
open (FULL,">$fulldatafile") || die ("cant open"." $fulldatafile");

#print the header line 
print(FULL "$header\n");

print("Part III: Sorting and Final Linking\n");

@links = sort {$b<=>$a} @links;

%bdone_hash=();
%ddone_hash=();

$match=0;
$ties=0;

foreach $line(@links) {

  ($score, $bid, $did, $ddate, $dif, $raad)=split("\t", $line);

  if(&isnull($bdone_hash{$bid}) &isnull($ddone_hash{$did}) & $score>=$minscore) {

    #put it into croatdata

    $rec=$croat{$bid};

    ($bid, $bdate, $sex, 
     $motherid, $fatherid, 
     $mid1, $mid2, $mid3, $mid4, $mid5, 
     $sid1, $sid2, $sid3, $sid4, $sid5,
     $mdate1, $mdate2, $mdate3, $mdate4, $mdate5, 
     $did_old, $ddate_old,
     $idk1,$idk2,$idk3,$idk4,$idk5,$idk6,$idk7,
     $idk8,$idk9,$idk10,$idk11,$idk12,$idk13,$idk14,
     $dobk1, $dobk2, $dobk3, $dobk4, $dobk5, $dobk6, $dobk7, $dobk8, 
     $dobk9, $dobk10, $dobk11, $dobk12, $dobk13, $dobk14, 
     $sidk1,$sidk2,$sidk3,$sidk4,$sidk5,$sidk6,
     $sidk7,$sidk8,$sidk9,$sidk10,$sidk11,$sidk12,$sidk13,$sidk14,
     $remark1,$remark2,$remark3,$remark4,$remark5,$remark6,$remark7,
		 $remark8,$remark9,$remark10,$remark11,$remark12,$remark13,$remark14,
     $remarok1,$remarok2,$remarok3,$remarok4,$remarok5,$remarok6,$remarok7,
		 $remarok8,$remarok9,$remarok10,$remarok11,$remarok12,$remarok13,$remarok14,
     $park1,$park2,$park3,$park4,$park5,$park6,$park7,
     $park8,$park9,$park10,$park11,$park12,$park13,$park14)=split("\t", $rec);
    
    #recalculate birthdate based on raad

    if(&isnotnull($raad)) {

      $bdate=$ddate-$raad;

    }

    $newrec=join("\t", $bid, $bdate, $sex, 
		 $motherid, $fatherid, 
		 $mid1, $mid2, $mid3, $mid4, $mid5, 
		 $sid1, $sid2, $sid3, $sid4, $sid5,
		 $mdate1, $mdate2, $mdate3, $mdate4, $mdate5, 
		 &na($did), &na($ddate),
		 $idk1,$idk2,$idk3,$idk4,$idk5,$idk6,$idk7,
		 $idk8,$idk9,$idk10,$idk11,$idk12,$idk13,$idk14,
		 $dobk1, $dobk2, $dobk3, $dobk4, $dobk5, $dobk6, $dobk7, $dobk8, 
		 $dobk9, $dobk10, $dobk11, $dobk12, $dobk13, $dobk14, 
		 $sidk1,$sidk2,$sidk3,$sidk4,$sidk5,$sidk6,
		 $sidk7,$sidk8,$sidk9,$sidk10,$sidk11,$sidk12,$sidk13,$sidk14,
		 $remark1,$remark2,$remark3,$remark4,$remark5,$remark6,$remark7,$remark8,
		 $remark9,$remark10,$remark11,$remark12,$remark13,$remark14,
		 $remarok1,$remarok2,$remarok3,$remarok4,$remarok5,$remarok6,$remarok7,
		 $remarok8,$remarok9,$remarok10,$remarok11,$remarok12,$remarok13,$remarok14,
		 $park1,$park2,$park3,$park4,$park5,$park6,$park7,
		 $park8,$park9,$park10,$park11,$park12,$park13,$park14);

    $croat{$bid}=$newrec;

    $newline=join("\t", $bid, $did, $score, $ddate, $dif);

    print(FINAL "$newline\n");

    #add another match

    $match++;

    #put it into the birth id hash
    
    $bid_hash{$bid}=$newline;

    #close off these ids for further links

    $bdone_hash{$bid}=$score;
    $ddone_hash{$did}=$score;

  }

}

###print out croat data

@bid =keys %croat;

foreach $bid (@bid) {

  $line=$croat{$bid};

  print(FULL "$line\n");

}


print(DETAIL "There were $possible non-real people and $deaths_avail deaths unlinked.\n\n");
print(DETAIL "$prelim_match had at least one preliminary match and $match of these were ultimately linked to a death\n\n");
print(DETAIL "$unmatched had no preliminary matches\n");

##################################################################################

#######################
# This subroutine will calculate the score for the
# match between a particular death and person 
# record.

sub matchrecs {
    
   $summatch=0; 
   $parmatch=0;
   $fnmatch=0;
   $sxmatch=0;
   $lnmatch=0;
   $pobmatch=0;
   $presmatch=0; 
   $pburmatch=0;
   $fnfmatch=0;
   $aadmatch=0;
  
  $aad = $ddate-$bdate; #age at death in decimal yrs from dates
  
  #a boolean for missing age parameters.  As people get older it 
  #is much more likely that $dagem and $daged are missing.  Therefore
  #I will only kick them out if $dagey is missing
  
  $age_missing=(&isnull($dagey) && &isnull($dagem) && &isnull($daged));
  
  $raad = ($dagey*365.25+$dagem*30.44+$daged)/365; #reported age at death
  
  $summatch=0;
  
  $diff=abs($aad-$raad);
  
  
  #Now the program will assign a score for the age match based on how far
  #off the reported age at death is from the calculated age at death.  The degree
  #of age misreporting allowed will vary with the calculated age at death.

   #need a simpler switch to address the proxy nature of birthdates for the 
   #"non-reals"

   #perhaps just one simple scale
   
   #first I need to exclude links where the person would have been too young 
   # too be married or have a kid or too old to have a kid based on reported age at 
   # death

   #also exlude them if it would mean they had children past reproductive ages

   $implied_bdate=$ddate-$raad;

   if(($firstevent-$implied_bdate)<$minage || ($lastbirth-$implied_bdate)>$maxrep) {

     return(0);

   }

   $scale = 1 - $diff/abs($minage);
   $aadmatch=$weights{"age"}*$scale;
      
    
    #age match.  Essentially, this kicks out anybody who
   #is more than some proportional term away.  
   
#   if ($age_missing) {
     
     #this needs to be set so that adding it to 
     #the minimum allowed score for missing age 
     #leads to the minimum accepted score in general
     
     #It also needs a fudge factor because, it has to be
     #higher than the min score
     
#     $aadmatch=$minscore-$missing_age_min; 
     
#   } else {
     
#     if ($aadmatch < 0) {
       
#       $summatch = 0;
#       return($summatch, $aad);
       
#    }
     
#  }
   
   #If it was inside the range, then score everything else
   
   #parish match
   if (("$park1" eq "$dpar") && &isnotnull($park1)){$parmatch = $weights{"parish"};}
   else {$parmatch = 0;}
   
   #sex match
   if (("$sex" eq "$dsx")&& &isnotnull($bsx)) {$sxmatch = $weights{"sx"};}
   else {$sxmatch = 0;}
   
   #place of birth match
#   if (("$bpob" eq "$dpob")&& &isnotnull($bpob)) {$pobmatch = $weights{"pob"};}
#   else {$pobmatch = 0}
     
   #place of ? match
#   if (("$bpob" eq "$dpres")&& &isnotnull($bpob)) {$presmatch = $weights{"pres"};}
#   else {$presmatch = 0;}
   
   #place of burial match
#   if (("$bpob" eq "$dpbur")&& &isnotnull($bpob)) {$pburmatch = $weights{"pbur"};}
#   else {$pburmatch = 0;}
   
   #relative name match - if this death was from a spouse then don't
   #hold it against them
#   if (("$bfnf" eq "$fnr") && &isnotnull($bfnf)){

#     $fnfmatch = $weights{"fnf"};
     
#   } elsif(&isnotnull($bfnf) && &isnotnull($fnr) && &isnotnull($mid)) {
     
     #should I require this to match if present?
     
     #$summatch=0;
     #return $summatch;

#   }
   
   $summatch = $parmatch + $fnmatch + $sxmatch + $lnmatch + $pobmatch + $presmatch + 
     $pburmatch + $fnfmatch + $aadmatch;

   $diff=$diff/365;
  
   return($summatch, $diff, $raad);
  
}
