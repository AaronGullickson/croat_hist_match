########################
# b2d.pl               #
# Perl Program         #
# Aaron Gullickson     #
# 9/14/00              #
########################

######################################################################
# SUMMARY
#
# This program is to be run after b2m.  It will use the b2m combinations
# to see if it can find better death links for women (given their flaky
# last names).  Also, if it can't find a better death link - it will check
# b2m to make sure current death link makes sense with b2m data.  If it
# doesn't it will kick out the b2m link.

#######################################################################

##############################
# MAIN                       #
##############################

#attach subroutines
require generalsubs;

&get_date_time;


##############################
# ADJUSTABLE PARAMETERS
#
# Here is where you can make
# adjustments to the weights
# or the minimum accepted score

#set up weights

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

%agerange = (
	     "week"            => 7,
	     "month"           => 31,
	     "year"            => 365,
	     "threeyearstart"  => 365,
	     "threeyearend"    => 365,
	     "tenyear"         => 365,
	     "twentyearstart"  => 365,
	     "twentyyearend"   => 730,
	     "fourtyyear"      => 5*365,
	     "overfourtystart" => 10*365,
	     "overfourtyat80"  => 10*365,
	     );

$missing_age_min=40; #the lowest allowed score for those whose age is missing
$na="NA";

#the lowest allowed score for those whose age is not missing.
#I wouldn't mess with this.  It is set to accept anything that
#falls in the age range so messing with it may produce wierd results
#for which I will not be held responsible :)
$minscore=30;


#get things ready for printing
$maximum_value = sum (@weightvalues);

@weightkeys = keys(%weights);
@weightvalues = values (%weights);
$weightkeys = join ("\t",@weightkeys);
$weightvalues = join ("\t",@weightvalues);

@agekeys = keys(%agerange);
@agevalues = values (%agerange);
$agekeys = join ("\t",@agekeys);
$agevalues = join ("\t",@agevalues);

###############################
# INPUT/OUTPUT

$binfile="input/sortedbirths.tsv";
$dinfile="input/sorteddeaths.tsv";
$marinfile="input/sortedmars.tsv";
$b2minfile="output/b2m.mmatches.tsv";
$m2binfile="output/m2b.matches.tsv";
$m2minfile="output/m2m.matches.tsv";
open (BIRIN,"<$binfile") || die ("cant open"." $binfile");
open (DTHIN,"<$dinfile") || die ("cant open"." $dinfile");
open (MARIN,"<$marinfile") || die ("cant open"." $marinfile");
open (B2M,"<$b2minfile") || die ("cant open "."  $b2minfile");
open (M2B,"<$m2binfile") || die ("cant open "."  $m2binfile");
open (M2M,"<$m2minfile") || die ("cant open "."  $m2minfile");

#$prelimmatchfile="output/b2d.match.prelim.txt";
#$sortfile="output/b2d.prelim.sorted.txt";
$finalmatchfile="output/b2d.matches.tsv";
$detailfile="output/diagnostics/b2d.diag.txt";
#$tiesfile="output/b2d.ties.txt";
#open (PRELIM,">$prelimmatchfile") || die ("cant open "."$prelimmatchfile");
#open (SORT,">$sortfile") || die ("cant open "."$sortfile");
open (FINAL,">$finalmatchfile") || die ("cant open "."$finalmatchfile");
open (DETAIL, ">$detailfile") || die ("cant open "."$detailfile");
#open (TIES, ">$tiesfile") || die ("cant open "."$tiesfile");

print ("Program name is b2d.pl\n");

print(DETAIL "Detail file for b2d.pl\n");
print(DETAIL "Program started on "."$daterun "."$yrrun"." at "."$timerun\n\n");

print(DETAIL "Weights used in analysis:\n");
print(DETAIL "$weightkeys\n");
print(DETAIL "$weightvalues\n\n");

print(DETAIL "Age ranges used in analysis:\n");
print(DETAIL "$agekeys\n");
print(DETAIL "$agevalues\n\n");

print(DETAIL "Maximum score is "."$maximum_value\n\n");
print(DETAIL "The lowest allowed score is "."$minscore\n\n");

@DEATH = <DTHIN>;
$death_length = scalar @DEATH;
@BIRTH = <BIRIN>;
$birth_length = scalar @BIRTH;


##################################################
# SECTION 1
#
# This section will set up the death hash described
# above.  The key to the death_hash will be first and last
# name and sex.

print("Beginning Section 1: building Death Hash\n");

%death_hash = ();
%lastdate_hash=();
%b2m_hash=();
%mdate_hash=();
%hlastname_hash=();
%remar_hash=();

$d_agemiss=0;

$sum_age_at_death=0;

foreach $line(@DEATH) {

  #split the line up into scalars

  ($dpar,$did1,$did2,$duni,$ddate,$dyyy,$dmm,$ddd,$dfn,$dsx,$dln,$dagey,$dagem,
	$daged,$fnr,$dtpr,$dpob,$dpor,$dpbur,$dmst,$lndu,$dfnf,
	$dfnh)=split("\t", $line);

  #create a key from first name, last

  $key="$dfn"."$dln"."$dsx";

  if(&isnotnull($key)) {

    push(@{$death_hash {$key}}, $line);

  }


  #I also want to know how many of these have missing ages

  $missing=(&isnull($dagey) && &isnull($dagem) && &isnull($daged));
  $d_agemiss=$d_agemiss+$missing;

  if($missing==0) {

    $sum_age_at_death=$sum_age_at_death + ($dagey*365+$dagem*30.44+$daged)/365;

  }

}

$age_at_death=$sum_age_at_death/$death_length;

foreach $line(<M2B>) {

  ($mid,$lastdate,$numkids,$kids)=split("\t", $line);

  $mid=~s/\s//g;

  $lastdate_hash{$mid} = $lastdate;

}

foreach $line(<MARIN>) {

  chop $line;

  ($mpar,$mi,$mid,$muni,$myrdate,$myyy,$mmm,$mdd,$mfnh,$mlnh,$mmstath,
   $mageh,$mpoh,$mfnhfa,$mfnw,$mlnw,$mmstatw,$magew,$mpow,$mfnwrel,
   $mtypwrel,$mfnwit1,$mlnwit1,$mpowit1,$mfnwit2,$mlnwit2,$mpowit2,
   $mlnhfull,$mlnwfull,$mlnwit1full,$mlnwit2full,$mnamef,$mnames,
   $mmatchflag)=split("\t", $line);

  $mid=&stripwhite($mid);

  $mdate_hash{$mid}=$myrdate;
  $hfirstname_hash{$mid}=$mfnh;
  $wfirstname_hash{$mid}=$mfnw;
  $hlastname_hash{$mid}=$mlnh;

}

foreach $line(<B2M>) {

  chop $line;

  ($mid, $hbid, $wbid, $hage, $wage, $score)=split("\t", $line);

  $mid=&stripwhite($mid);
  $hbid=&stripwhite($hbid);
  $wbid=&stripwhite($wbid);

  $b2m_hash{$hbid}=$mid;
  $b2m_hash{$wbid}=$mid;

}

foreach $line(<M2M>) {

  chop $line;

  ($mid,$spouse,$remarid,$score)=split("\t", $line);

  $mid=&stripwhite($mid);
  $remarid=&stripwhite($remarid);
  $spouse=&stripwhite($spouse);

  $spouse=~s/h/m/g;
  $spouse=~s/w/f/g;

  $remar_hash{$mid.$spouse} = $remarid;

}

print("Section 1 Done\n");

#################################################
# SECTION 2
#
# This section will loop through sortedbirths and
# match it with records in the death hash.  This produces
# a preliminary set of matches which will then be trimmed
# down in section 3 and 4.

print("Beginning Section 2: Linking births and deaths\n");

$unmatched=0;
$matched=0;
$matchlength=0;

#I am also going to create a birth id hash that will be filled
#with NA's.  I will fill it later in the final links

%bid_hash=();

foreach $line(@BIRTH) {

  ($bpar,$bid1,$bid2,$uni,$bdate,$byyy,$bmm,$bdd,$bfn,$bsx,$bfnf,$blnf,$bfnm,$blnm,$bpob,
   $bfng,$blng,$bpog) = split("\t",$line);

  #create this entry in the birth id hash

  $bid2=~s/\s//g;

  if(&isnull($bid_hash{$bid2})) {

    $bid_hash{$bid2}=join("\t", $bid2, $na, $na, $na, $na);

  }

  #make a key of first name, last name, and sex

  $key="$bfn"."$blnf"."$bsx";

  $mid=$b2m_hash{$bid2};
  $mid=~s/\s//g;

  $lastdate=$lastdate_hash{$mid};
  $mdate=$mdate_hash{$mid};

  #Get the array from the death_hash that matches the key

  @array = @{$death_hash {$key}};

  #the variable empty is a boolean that will be true until a match is made
  #for this particular birth record

  #if its a women also look for marriage names
  #loop through all remarriages to collect all possible names


  if($bsx=~m/f/i & &isnot_na($mid)) {

    $bid2=~s/\s//g;

    $lname=$hlastname_hash{$mid};

    $key = "$bfn"."$lname"."$bsx";

    @array2 = @{$death_hash {$key}};

    foreach $line(@array2) {

      push(@array, $line);

    }

    #now loop

    $remar=$remar_hash{$mid.$bsx};

    while(&isnotnull($remar)) {

      $mid=$remar;

      $lname=$hlastname_hash{$remar};

      $lastdate=$lastdate_hash{$remar};

      $key = "$bfn"."$lname"."$bsx";

      @array2 = @{$death_hash {$key}};

      foreach $line(@array2) {

	push(@array, $line);

      }

      $remar=$remar_hash{$remar.$bsx};

    }

  }

  #If spouse moves on to a remarriage, then this person cannot die after remarriage

  if($bsx eq "f") {

      $spsx="m";

  }

  if($bsx eq "m") {

      $spsx="f";

  }

  #because mid was updated before, I should get the last marriage for this person

  $remarsp=$remar_hash{$mid.$spsx};

  if(&isnotnull($remarsp)) {

      $remarsp_date=$mdate_hash{$remarsp};

  } else {

      $remarsp_date=2000;

  }


  $empty=1;

  #temp will be an array of all possible acceptable matches for this birth
  #record.  All of these will be printed to the matching output.

  @temp=();

  #now I will loop through the array that had all matching names and score
  #each possible link.  If the link score is high enough it will be added
  #to @temp which will then be printed.

  foreach $ref(@array) {

    ($dpar,$did1,$did2,$duni,$ddate,$dyyy,$dmm,$ddd,$dfn,$dsx,$dln,$dagey,
		$dagem,$daged,$fnr,$dtpr,$dpob,$dpor,$dpbur,$dmst,$lndu,$dfnf,
		$dfnh)=split("\t", $ref);

    #score this match

    #now I need to check to make sure death would work with marriage
    #link.  Let it happen up to one week before a birthdate because
    #baptisms often take place only on the sunday after the birth.

    if($bdate>$ddate || $mdate>$ddate || ($lastdate-8/365)>$ddate) {

      $score=0;

    } else {

      if($dtpr=~m/f/i==0) {

	if($bsx=~m/f/i) {

	  $bfnf=$hfirstname_hash{$mid};

	} elsif ($bsx=~m/m/i) {

	  $bfnf=$wfirstname_hash{$mid};

	}

      }

      ($score, $age)=&matchrecs;

      #who should we try to match

    }

    #If the score is nonzero then add it to the array

    if($score>0) {

      $answer=join("\t", $bid2, $did2, $score, $age, $ddate);

      push(@temp, $answer);

      $empty=0;

    }
  }

  #Ok now @temp contains all of the possible links that were non-zero
  #I will print these out to the output file.  There are two possibilities:
  #either it is empty or it is not.  In any case I am going to print to the
  #output file and push on to an array of @links, that I will then sort.

  if($empty==1) {

    $unmatched=$unmatched+1;

    #printf(PRELIM "%6d\t %s\t %s\t %s\t %s\n", $bid2, $na, $na, $na, $na);

    $linkline=join("\t", 0,$bid2,$na,$na,$na);

    push(@links, $linkline);

  } else {

    $matched = $matched+1;

    $matchlength = scalar @temp;

    foreach $ref(@temp) {

      ($bid, $did, $score, $age, $ddate)=split("\t", $ref);

      #printf(PRELIM "%6d\t %6d\t %6.3f\t %6.3f %6.6f\n", $bid, $did, $score, $age, $ddate);

      $linkline=join("\t",$score, $bid, $did, $age, $ddate);

      push(@links, $linkline);


    }

  }

  push(@matchlength, $matchlength);

}

$totalmatchlength = sum (@matchlength);

$averagematchlength = $totalmatchlength/$matched;

print("Section 2 Done\n");

#####################
# SECTION 3 : sort it

#sort links by the highest score to the lowest

print("Beginning Section 3: Sorting\n");

@links = sort {$b<=>$a} @links;

print("Section 3 Done\n");

##############################
# SECTION 4: Optimizing links

print("Beginning Section 4: Final Linking\n");

#build empty hashes which will tell me if that
#birth id or death id has already been used in a
#link and what the score was so that I can evaluate
#ties

%bdone_hash=();
%ddone_hash=();

#Build an empty birth id hash to put links into
#this way I will get empty links in the final
#output

@age_at_death=();
$match=0;
$ties=0;

foreach $line(@links) {

  #print(SORT "$line\n");

  ($score, $bid, $did, $age, $ddate)=split("\t", $line);

  if(&isnull($bdone_hash{$bid}) &isnull($ddone_hash{$did}) & $score>=$minscore) {

    $newline=join("\t", $bid, $did, $score, $age, $ddate);

    #add another match

    $match=$match+1;

    #put it into the birth id hash

    $bid_hash{$bid}=$newline;

    #close off these ids for further links

    $bdone_hash{$bid}=$score;
    $ddone_hash{$did}=$score;

    #add to age at death

    push(@age_at_death, $age);

  } else {

    #check for ties

    if ($bdone_hash{$bid}==$score & $score>=$minscore) {

      $ties = $ties+1;

      #print(TIES "There is a birth id tie at $line\n");

    }

    if ($ddone_hash{$bid}==$score & $score>$minscore) {

      $ties = $ties+1;

      print(TIES "There is a death id tie at $line\n");

    }


  }

}



$deathage = sum(@age_at_death)/$match;

#Now print out the results

@keys=keys(%bid_hash);

foreach $key(@keys) {

  $line=$bid_hash{$key};

  ($bid, $did, $score, $age, $ddate)=split("\t", $line);

  if($did=="NA") {

    printf(FINAL "%6d\t %s\t %s\t %s\t %s\n", $bid, $did, $score, $age, $ddate);

  } else {

    printf(FINAL "%6d\t %6d\t %6.3f\t %6.3f\t %6.6f\n", $bid, $did, $score, $age, $ddate);

  }

}

print("Section 4 Done\n");

###################################
# Now print the final diagnostics

print(DETAIL "Length of sortedbirths is "."$birth_length\n");
print(DETAIL "Length of sorteddeaths is "."$death_length\n\n");

print(DETAIL "$d_agemiss "."death records have no recorded age at death\n");
$percent_missing=100*$d_agemiss/$death_length;
print(DETAIL "As a percentage of all deaths, this is "."$percent_missing"."%\n\n");

print(DETAIL "The average age at death from the death records is "."$age_at_death\n\n");
print(DETAIL "The average age at death from the final matches is "."$deathage\n\n");


print(DETAIL "Number of births matched initially is "."$matched\n");
$percent_matched = 100*$matched/$birth_length;
print(DETAIL "As a percentage of all births, this is "."$percent_matched"."%\n\n");

print(DETAIL "The average number of matches for births that were matched is ".
      "$averagematchlength\n\n");

print(DETAIL "There were $ties scoring ties\n\n");

print(DETAIL "Number of births matched in final links is "."$match\n");
$percent_matched = 100*$match/$birth_length;
print(DETAIL "As a percentage of all births, this is "."$percent_matched"."%\n\n");

&get_date_time;

print(DETAIL "Program ended on "."$daterun "."$yrrun"." at "."$timerun\n\n");

print("Program Complete.\n");



#######################
# This subroutine will calculate the score for the
# match between a particular death and birth
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

  if($aad<0 || $aad>100) {

    $summatch=0;

    return($summatch, $aad);

  }

  #a boolean for missing age parameters.  As people get older it
  #is much more likely that $dagem and $daged are missing.  Therefore
  #I will only kick them out if $dagey is missing

  $age_missing=(&isnull($dagey) && &isnull($dagem) && &isnull($daged));

  $raad = ($dagey*365.25+$dagem*30.44+$daged)/365; #reported age at death

  $summatch=0;

  $diff=abs($aad-$raad)*365.25;


  #Now the program will assign a score for the age match based on how far
  #off the reported age at death is from the calculated age at death.  The degree
  #of age misreporting allowed will vary with the calculated age at death.

 SWITCH:{

    if($aad<.02){ #less than a week old

      $scale = 1 - $diff/$agerange{"week"};
      $aadmatch=$weights{"age"}*$scale;

      last SWITCH;

    } #end of weekolds

    if($aad < .0834){ #> 1 week < 1 month old

      $scale=1 - $diff/$agerange{"month"};
      $aadmatch=$weights{"age"}*$scale;

      last SWITCH;

    } #end of montholds

    if($aad <1){ #>1 month < 1 yr old

      $scale=1-$diff/$agerange{"year"};
      $aadmatch=$weights{"age"}*$scale;

      last SWITCH;

    } #end of yearolds


    if ($aad<3){ #>1 to <3 years old

      $allow = $agerange{"threeyearstart"} + ($aad-1) *
	($agerange{"threeyearend"}/3); #1 to 3 years
      $scale = 1-$diff/$allow;
      $aadmatch=$weights{"age"}*$scale;

      last SWITCH;

    } #end of 1 to 3 yr olds

    if($aad<10){ #>3 < 10 years old

      $scale=1-$diff/$agerange{"tenyear"};
      $aadmatch=$weights{"age"}*$scale;

      last SWITCH;

    } #end of 10 yr olds

    if ($aad<20){ #>10 < 20 yrs old

      $allow = $agerange{"twentyyearstart"} + ($aad-10) *
	($agerange{"twentyyearend"}/10); #1 to 3 years
      $scale = 1-$diff/$allow;
      $aadmatch=$weights{"age"}*$scale;

      last SWITCH;

    } #end of 20 yr olds

    if ($aad<40){ #>10 < 20 yrs old

      $scale = 1-$diff/$agerange{"fourtyyear"};
      $aadmatch=$weights{"age"}*$scale;

      last SWITCH;

    } #end of 20 yr olds

    $allow= $agerange{"overfourtystart"} + ($aad-50) *
      ($agerange{"overfourtyat80"}/30); #up to 10 for 80
    $scale= 1 - $diff/$allow;
    $aadmatch=$weights{"age"}*$scale;

  } #end of switch


    #age match.  Essentially, this kicks out anybody who
   #is more than some proportional term away.



   if ($age_missing) {

     #this needs to be set so that adding it to
     #the minimum allowed score for missing age
     #leads to the minimum accepted score in general

     #It also needs a fudge factor because, it has to be
     #higher than the min score

     $aadmatch=$minscore-$missing_age_min;

   } else {

     if ($aadmatch < 0) {

       $summatch = 0;
       return($summatch, $aad);

    }

  }

   #If it was inside the range, then score everything else

   #parish match
   if (("$bpar" eq "$dpar") && &isnotnull($bpar)){$parmatch = $weights{"parish"};}
   else {$parmatch = 0;}

   #first name match
   if (("$bfn" eq "$dfn")&& &isnotnull($bfn)) {$fnmatch = $weights{"fn"};}
   else {$fnmatch = 0;}

   #sex match
   if (("$bsx" eq "$dsx")&& &isnotnull($bsx)) {$sxmatch = $weights{"sx"};}
   else {$sxmatch = 0;}

   #last name match
   #can match either on husband or father's last name if female

   if (("$blnf" eq "$dln")&& &isnotnull($blnf)) {$lnmatch = $weights{"ln"};}
   else {$lnmatch = 0;}

   if($bsx=~m/f/i && $lnmatch==0 && &isnot_na($mid)) {

     if (("$lname" eq "$dln") && &isnotnull($lname)) {

       $lnmatch = $weights{"ln"};

     }

   }

   #place of birth match
   if (("$bpob" eq "$dpob")&& &isnotnull($bpob)) {$pobmatch = $weights{"pob"};}
   else {$pobmatch = 0}

   #place of ? match
   if (("$bpob" eq "$dpres")&& &isnotnull($bpob)) {$presmatch = $weights{"pres"};}
   else {$presmatch = 0;}

   #place of burial match
   if (("$bpob" eq "$dpbur")&& &isnotnull($bpob)) {$pburmatch = $weights{"pbur"};}
   else {$pburmatch = 0;}

   #relative name match - if this death was from a spouse then don't
   #hold it against them
   if (("$bfnf" eq "$fnr") && &isnotnull($bfnf)){

     $fnfmatch = $weights{"fnf"};

   } elsif(&isnotnull($bfnf) && &isnotnull($fnr) && &isnotnull($mid)) {

     #should I require this to match if present?

     #$summatch=0;
     #return $summatch;

   }

   $summatch = $parmatch + $fnmatch + $sxmatch + $lnmatch + $pobmatch + $presmatch +
     $pburmatch + $fnfmatch + $aadmatch;

   return($summatch, $aad);


}
