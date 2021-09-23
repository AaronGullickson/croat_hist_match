########################
# b2m.pl               #
# Perl Program         #
# Aaron Gullickson     #
# 9/14/00              #
########################

######################################################################
# SUMMARY
#
# This program will match birth records from sortedbirths and marriage records
# from sortedmars. Because for most marriages the age at marriage is missing
# for both spouse, we use information from m2b to help reach a decision. 
# First, we score each potential birth to marriage link and then we use these
# links to construct a list of all possible marriage combinations.  We then
# score these based on both spouses scores and by how far apart the spouses 
# are in age. The program is organized as follows:
#
# SECTION 1
#
# This section sets up the hashes that will be used later in the program
# We set up two hashes for marriages (one for wives and for husbands) out of
# sortedmars and we also set up hashes for the results from b2d and m2b.
# These hashes help us retrieve data quickly by mid and bid later in the program.
#
# SECTION 2
#
# This section loops through sortedbirths and for each birth finds all the
# potential marriages in the marriage hash based on first and last name.
# It then loops through these possibilities and assigns a score to each one
# based on matching on several criterion.  It also excludes possibilities, if
# m2b shows that a woman reached menopause before the last birth resulting from
# the marriage.  All birth to marriage links are then pushed onto an array.
#
# SECTION 3
#
# This section loops through all the possible birth-marriage links and finds
# all of the births of the opposite sex that are also potentially linked to that
# marriage.  These are used to construct the entire universe of possible
# marriage combinations based upon the birth-marriage links (including the
# default - that the other spouse was not linked).  It then scores them based
# on how close the spouses are in age (using data derived from sortedmars where
# age at marriage is available).
#
# SECTION 4
#
# The resulting list of marriage combinations are sorted by their score.
#
# SECTION 5
#
# This section loops through the sorted list of marriage combos and if none of
# the ids involved in that combo have already been used (mid, hbid, wbid), it
# prints this out as the optimal link for that marriage.
#
# INPUT
#
# The input files necessary for this project are:
#
# sortedbirths - the file of data on each birth listed in parish data
# sortedmars - the file of data on each marriage listed in parish data
# m2b.matches.txt - file of births that are linked as coming from each marriage
#
# OUTPUT
#
# b2m.diag.txt - This file lists important summary statistics for the matches
#
# b2m.match.prelim.txt - a file of all potential marriage links for each
# birth id.  The fields are:
#
#       bid   mid    score    age    sex
#
#
# b2m.bmatches.txt - a file of the final birth to marriage links.  The fields
# are the same as b2m.match.prelim.txt
#
# b2m.mmatches.txt - a file of the final marriage combinations accepted.
# The fields are:
#
#       mid   hbid   wbid   hage   wage   score
#
#
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

%weights = ("parish"  =>  "5",
	    "fn"      => "10",
	    "sx"      => "10",
	    "ln"      => "10",
	    "pob"     =>  "5",
	    "wit1"    =>  "5",
	    "wit2"    =>  "5",
	    "fnf"     =>  "5",
	    "age"     => "20",
	    "agediff" => "10"
	   );


#set up age range

$agerange=5;

$min_age_mar=15;
$max_age_mar=61;
$missing_age_min=0; #the lowest allowed score for those whose age is missing
$na="NA";

#the lowest allowed score for those whose age is not missing.
#I wouldn't mess with this.  It is set to accept anything that
#falls in the age range so messing with it may produce wierd results
#for which I will not be held responsible :)
$minscore=30;


#get things ready for printing


@weightkeys = keys(%weights);
@weightvalues = values (%weights);
$maximum_value = sum (@weightvalues);
$weightkeys = join ("\t",@weightkeys);
$weightvalues = join ("\t",@weightvalues);

###############################
# INPUT/OUTPUT

$binfile="input/sortedbirths.tsv";
$minfile="input/sortedmars.tsv";
open (BIRIN,"<$binfile") || die ("cant open"." $binfile");
open (MARIN,"<$minfile") || die ("cant open"." $minfile");

$m2binfile="output/m2b.matches.txt";
$prelimmatchfile="output/b2m.match.prelim.txt";
$sortfile="output/b2m.prelim.sorted.txt";
$finalbmatchfile="output/b2m.bmatches.txt";
$finalmmatchfile="output/b2m.mmatches.txt";
$detailfile="output/diagnostics/b2m.diag.txt";
$tiesfile="output/b2m.ties.txt";
open (M2B, "<$m2binfile") || die ("cant open $m2binfile");
open (PRELIM,">$prelimmatchfile") || die ("cant open "."$prelimmatchfile");
open (FINALB,">$finalbmatchfile") || die ("cant open "."$finalbmatchfile");
open (FINALM,">$finalmmatchfile") || die ("cant open "."$finalmmatchfile");
open (DETAIL, ">$detailfile") || die ("cant open "."$detailfile");
open (TIES, ">$tiesfile") || die ("cant open "."$tiesfile");

print ("Program name is b2m.pl\n");

print(DETAIL "Detail file for b2m.pl\n");
print(DETAIL "Program started on "."$daterun "."$yrrun"." at "."$timerun\n\n");

print(DETAIL "Weights used in analysis:\n");
print(DETAIL "$weightkeys\n");
print(DETAIL "$weightvalues\n\n");

print(DETAIL "Maximum score is "."$maximum_value\n\n");
print(DETAIL "The lowest allowed score is "."$minscore\n\n");

@BIRTH = <BIRIN>;
$birth_length = scalar @BIRTH;
@MAR = <MARIN>;
$mar_length = scalar @MAR;

##################################################
# SECTION 1
#
# This section will set up two marriage hashes described
# above.  The key to the marriage_hash will be first and last
# name and sex.  It will also set up a death hash to see if
# you are already dead.


print("Beginning Section 1: building Hashes\n");

%wmar_hash = ();
%hmar_hash = ();
%mar_hash=();
%b2d_hash=();
%m2b_hash=();
%bdate_hash=();
%lastdate_hash=();

$mw_missing=0;
$mh_missing=0;

$firstmarw_length=0;
$firstmarh_length=0;

foreach $line(@MAR) {

  #split the line up into scalars

  ($mpar,$mi,$mid,$muni,$myrdate,$myyy,$mmm,$mdd,$mfnh,$mlnh,$mmstath,
   $mageh,$mpoh,$mfnhfa,$mfnw,$mlnw,$mmstatw,$magew,$mpow,$mfnwrel,
   $mtypwrel,$mfnwit1,$mlnwit1,$mpowit1,$mfnwit2,$mlnwit2,$mpowit2,
   $mlnhfull,$mlnwfull,$mlnwit1full,$mlnwit2full,$mnamef,$mnames,
   $mmatchflag)=split("\t", $line);

  #create the empty mar_hash which will be my final output later

  $mar_hash{$mid}=join("\t", $mid, $na, $na, $na, $na, $na);

  $mdate_hash{$mid}=$myrdate;

  #create a key from first name, last

  $hkey="$mfnh"."$mlnh";
  $wkey="$mfnw"."$mlnw";

  #push this latest line onto the array in the hash at that key

  #only accept first marriages

  if(&isnotnull($wkey) && $mmstath ne "u" && $mmstath ne "y" && $mmstath ne "r") {

    $mh_missing=$mh_missing + &isnull($mageh);

    $firstmarh_length=$firstmarh_length + 1;

    push(@{$hmar_hash {$hkey}}, $line);

  }

  if(&isnotnull($wkey) && $mmstatw ne "u") {

    $mw_missing=$mw_missing + &isnull($magew);

    $firstmarw_length=$firstmarw_length + 1;

    push(@{$wmar_hash {$wkey}}, $line);

  }

}

foreach $line(<M2B>) {

  ($mid,$lastdate,$numkids,$kids)=split("\t", $line);

  $key="$mid";

  $m2b_hash{$key} = $line;

}

$lastdate_hash{$mid}=$lastdate;

@temp=keys(%wmar_hash);
$wname_length=scalar @temp;
@temp=keys(%hmar_hash);
$hname_length=scalar @temp;


print("Section 1 Done\n");

#################################################
# SECTION 2
#
# This section will loop through sortedbirths and
# match it with records in the marriage hashes.  This produces
# a preliminary set of matches which will then be trimmed
# down in section 3 and 4.

print("Beginning Section 2: Linking births and marriages\n");

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

  if(&isnull($bid_hash{$bid2})) {

    $bid_hash{$bid2}=join("\t", $bid2, $na, $na, $na, $bsx);

  }

  $bdate_hash{$bid2}=$bdate;

  #make a key of first name, last name, and sex

  $key="$bfn"."$blnf";

  if($bsx eq "f") {

    @array = @{$wmar_hash {$key}};

  }

  if($bsx eq "m") {

    @array = @{$hmar_hash {$key}};

  }

  #the variable empty is a boolean that will be true until a match is made
  #for this particular birth record

  $empty=1;

  #temp will be an array of all possible acceptable matches for this birth
  #record.  All of these will be printed to the matching output.

  @temp=();

  #now I will loop through the array that had all matching names and score
  #each possible link.  If the link score is high enough it will be added
  #to @temp which will then be printed.

  foreach $ref(@array) {

    ($mpar,$mi,$mid,$muni,$myrdate,$myyy,$mmm,$mdd,$mfnh,$mlnh,$mmstath,
     $mageh,$mpoh,$mfnhfa,$mfnw,$mlnw,$mmstatw,$magew,$mpow,$mfnwrel,
     $mtypwrel,$mfnwit1,$mlnwit1,$mpowit1,$mfnwit2,$mlnwit2,$mpowit2,
     $mlnhfull,$mlnwfull,$mlnwit1full,$mlnwit2full,$mnamef,$mnames,
     $mmatchflag)=split("\t", $ref);

    $m2blink=$m2b_hash{"$mid"};

    ($mid2,$lastdate,$numkids,$kids)=split("\t", $m2blink);

    #figure out whether man or woman

    if($bsx eq "m"){

      $mfn=$mfnh;
      $mln=$mlnh;
      $mmstat=$mmstath;
      $agem=$mageh;
      $mpo=$mpoh;
      $mfnf=$mfnhfa;
      $fnwit1=$mfnwit1;
      $lnwit1=$mlnwit1;
      $fnwit2=$mfnwit2;
      $lnwit2=$mlnwit2;
      $powit1=$mpowit1;
      $powit2=$mpowit2;
      $msx="m";
      $finaldate=$bdate+80;
    }

    if($bsx eq "f") {
      undef($fnwit1); #get rid of witness stuff for women
      undef($lnwit1);
      undef($fnwit2);
      undef($lnwit2);
      undef($mfnf);
      $mfn=$mfnw;
      $mln=$mlnw;
      $mmstat=$mmstatw;
      $agem=$magew;
      $mpo=$mpow;
      $msx="f";
      $finaldate=$bdate+55;
    }

    if($mmstat="n"){

      $mfnf=$mnamef;

    } #end check on unmarried female

    # make sure that the last birth in the marriage occurs before menopause
		# for women and before 80 for men only score it if it fits inside the right
		# date limits


    if($finaldate<=$lastdate) {

      $score=0;

    } else {

    #score this match - see matchrecs below for details

      ($score, $age)=&matchrecs;

    }

    #If the score is nonzero then add it to the array

    if($score>0) {

      $answer=join("\t", $bid2, $mid, $score, $age, $bsx);

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

  printf(PRELIM "%6d\t %s\t %s\t %s\t %s\n", $bid2, $na, $na, $na, $na);

    $linkline=join("\t", 0,$bid2,$na,$na, $na, $na);

    push(@links, $linkline);

  } else {

    $matched = $matched+1;

    push(@matchlength, scalar @temp);

    foreach $ref(@temp) {

      ($bid, $mid, $score, $age, $sex)=split("\t", $ref);

      printf(PRELIM "%6d\t %6d\t %6.3f\t %6.3f %s\n", $bid, $mid, $score, $age, $sex);

      $linkline=join("\t",$score, $bid, $mid, $age, $sex);

      push(@{$mid_hash{"$mid"."$sex"}}, $linkline);

      push(@links, $linkline);

    }

  }

}

$totalmatchlength = sum (@matchlength);

$averagematchlength = $totalmatchlength/$matched;

@temp = keys(%bid_hash);
$bid_length=scalar @temp;

print("Section 2 Done\n");

print("Beginning Section 3: Collecting all marriage possibilities\n");

#Put these results into a hash of all possible combos for each marriage.
#Then determine the likelihood of each of those based on the distance in age between spouses.

#I need a list which is all possible combinations from bid_hash

@marlinks=();

foreach $line(@links) {

  ($score, $bid, $mid, $age, $sex)=split("\t", $line);

  #see if these is a marriage

  if($mid ne "NA") {

    #find all possible mates

    if($sex eq "f") {

      $mkey="$mid"."m";
      $wbid=$bid;
      $hbid=$na;
      $wage=$age;
      $hage=$na;

    }

    if($sex eq "m") {

      $mkey="$mid"."f";
      $hbid=$bid;
      $wbid=$na;
      $hage=$age;
      $wage=$na;

    }

    @mates = @{$mid_hash {$mkey}};

    #every marriage has a potential mate:nobody - that needs a score.

    $tscore=$score+5;

    $line=join("\t", $tscore, $mid, $wbid, $hbid, $wage, $hage);

    $mlinkkey="$mid"."$wbid"."$hbid";

    push(@marlinks, $line);

    foreach $ref(@mates) {

      ($score2, $bid2, $mid2, $age2, $sex2)=split("\t", $ref);

      #make the key so that females always come first

      if($sex eq "f") {

	$wbid=$bid;
	$hbid=$bid2;
	$wscore=$score;
	$hscore=$score2;
	$wage=$age;
	$hage=$age2;

      }

      if($sex eq "m") {

	$wbid=$bid2;
	$hbid=$bid;
	$wscore=$score2;
	$hscore=$score;
	$wage=$age2;
	$hage=$age;

      }

      $spousematch=0;

      #get the marriage

      $tscore=($wscore+$hscore)/2;

      $agediff=$hage - $wage;

      #need to score this age difference somehow.  Something where within
      #certain range they all get the same score.  Then linearly declining 
			#score to some bounds where they get 0.

      if($agediff>=-1 && $agediff<=5) {

	$agediffmatch=$weights{"agediff"};

      } else {

	if($agediff>=-21 && $agediff<=25) {

	  $temp=$agediff-2;

	  $diff = abs($temp)-3;

	  $agediffmatch=(1 - $diff/20) * $weights{"agediff"};

	} else {

	  $agediffmatch=0;

	}

      }

      $tscore=$tscore+$agediffmatch;

      $line=join("\t", $tscore, $mid, $wbid, $hbid, $wage, $hage);

      $mlinkkey="$mid"."$wbid"."$hbid";

      push(@marlinks, $line);

    }
  }
}

print("Section 3 Done\n");

######Now sort these

print("Beginning Section 4: Sorting\n");

@marlinks = sort {$b<=>$a} @marlinks;

$marlinks_length=scalar @marlinks;

print("Section 4 Done\n");

print("Beginning Section 5: Final matching\n");

####Now use algorithm to pick them out if they have not been listed already

%mid_done=();
%wbid_done=();
%hbid_done=();
$single_match=0;


foreach $mar(@marlinks) {


  ($tscore, $mid, $wbid, $hbid, $wage, $hage)=split("\t", $mar);


  $lastage=$lastdate_hash{$mid}-$bdate_hash{$bid};

  $mnotdone=&isnull($mid_done{$mid});
  $hnotdone=&isnull($hbid_done{$hbid}) || $hbid=="NA";
  $wnotdone=&isnull($wbid_done{$wbid}) || $wbid=="NA";

  if($mnotdone && $hnotdone && $wnotdone && $tscore>$minscore) {


    if($hbid=="NA" || $wbid=="NA") {

      $single_match=$single_match+1

    }

    $hline=join("\t", $hbid, $mid, $tscore, $hage, "m");
    $wline=join("\t", $wbid, $mid, $tscore, $wage, "f");
    $mline=join("\t", $mid, $hbid, $wbid, $hage, $wage, $tscore);

    $bid_hash{$hbid}=$hline;
    $bid_hash{$wbid}=$wline;
    $mar_hash{$mid}=$mline;

    $mid_done{$mid}=1;
    $hbid_done{$hbid}=1;
    $wbid_done{$wbid}=1;

  }

}

$births_matched=0;

@keys=keys(%bid_hash);

foreach $key(@keys) {

  $line=$bid_hash{$key};

  ($bid, $mid, $score, $age, $sex)=split("\t",$line);

  $temp = $mid!="NA";

  $births_matched = $births_matched +  $temp;

  print(FINALB "$line\n");

}

$hmar_matched=0;
$wmar_matched=0;
$mar_matched=0;
$both_matched=0;

@keys=keys(%mar_hash);

foreach $key(@keys) {

  $line=$mar_hash{$key};

  ($mid, $hbid, $wbid, $hage, $wage, $score)=split("\t",$line);

  $h_present = $hbid!="NA";
  $hmar_matched = $hmar_matched + $h_present;
  $w_present = $wbid!="NA";
  $wmar_matched = $wmar_matched + $w_present;

  $one_present = $h_present || $w_present;
  $mar_matched = $mar_matched + $one_present;

  $both_present = $h_present && $w_present;
  $both_matched = $both_matched + $both_present;

  print(FINALM "$line\n");

}

print("Section 5 Done\n");


###################################
# Now print the final diagnostics

print(DETAIL "Length of sortedbirths is "."$birth_length\n");
print(DETAIL "Length of sortedmars is "."$mar_length\n\n");
print(DETAIL "Number of first marriages for women is "."$firstmarw_length\n\n");
print(DETAIL "Number of first marriages for men is "."$firstmarh_length\n\n");

print(DETAIL "$mh_missing "."first marriages for men have no recorded age at marriage\n");
$percent_missing=100*$mh_missing/$firstmarh_length;
print(DETAIL "As a percentage of all male first marriages, this is "."$percent_missing"."%\n\n");

print(DETAIL "$mw_missing "."first marriages for women have no recorded age at marriage\n");
$percent_missing=100*$mw_missing/$firstmarw_length;
print(DETAIL "As a percentage of all female first marriages, this is "."$percent_missing"."%\n\n");

print(DETAIL "The number of unique wives' names is $wname_length\n");
print(DETAIL "The number of unique husbands' names is $hname_length\n\n");

print(DETAIL "Number of births matched initially is "."$matched\n");
$percent_matched = 100*$matched/$birth_length;
print(DETAIL "As a percentage of all first births, this is "."$percent_matched"."%\n\n");

print(DETAIL "The average number of matches for births that were matched is "."$averagematchlength\n\n");

print(DETAIL "There were $ties scoring ties\n\n");

print(DETAIL "Number of births matched in final links is "."$births_matched\n");
$percent_matched = 100*$births_matched/$birth_length;
print(DETAIL "As a percentage of all births, this is "."$percent_matched"."%\n\n");

print(DETAIL "Number of marriages matched to a husband in final links is "."$hmar_matched\n");
$percent_matched = 100*$hmar_matched/$firstmarh_length;
print(DETAIL "As a percentage of all marriages, this is "."$percent_matched"."%\n\n");

print(DETAIL "$mar_matched marriages were matched to at least one spouse\n");
print(DETAIL "$single_match marriages were matched for only one spouse\n");
print(DETAIL "$both_matched marriages were matched to both spouses\n\n");

print(DETAIL "Number of marriages matched to a wife in final links is "."$wmar_matched\n");
$percent_matched = 100*$wmar_matched/$firstmarw_length;
print(DETAIL "As a percentage of all marriages, this is "."$percent_matched"."%\n\n");


&get_date_time;

print(DETAIL "Program ended on "."$daterun "."$yrrun"." at "."$timerun\n\n");

print("Program Complete.\n");

#######################################################################
# Matching subroutine

sub matchrecs {

  #inits
  $aammatch=0;
  $parmatch=0;
  $fnmatch=0;
  $sxmatch=0;
  $lnmatch=0;
  $pobmatch=0;
  $presmatch=0;
  $pburmatch=0;
  $fnfmatch=0;
  $aammatch=0;
  $wit1match=0;
  $wit2match=0;
  $summatch=0;



  $raam=$agem;

  #deal with age

    $aam = $myrdate-$bdate;

  if($aam<$min_age_mar || $aam>$max_age_mar) {

    $summatch=0;

    return($summatch)

  }


  $diff=abs($raam-$aam);
  $scale=1 - $diff/$agerange;
  $aammatch=$weights{"age"}*$scale;


  if(&isnull($raam)) {

    $aammatch=0;

  }

  if($aammatch<0) {

    $summatch = 0;
    return($summatch, $aam);

  }


  #check other stuff
  &isnotnull($bpar);
  if(($truth==1)&&($bpar eq $mpar))   {$parmatch = $weights{"parish"}};
  &isnotnull($bfn);
  if(($truth==1)&&($bfn eq $mfn))     {$fnmatch = $weights{"fn"}};
  &isnotnull($blnf);
  if(($truth==1)&&($blnf eq $mln))    {$lnmatch = $weights{"ln"}};
  &isnotnull($bsx);
  if(($truth==1)&&($bsx eq $msx))     {$sxmatch = $weights{"sx"}};
  &isnotnull($bpob);
  if(($truth==1)&&($bpob eq $mpo))    {$pobmatch = $weights{"pob"}};
  &isnotnull($bfnf);
  if(($truth==1)&&($bfnf eq $mfnf))   {$fnfmatch = $weights{"fnf"}};
  &isnotnull($lnwit1);
  if(($truth==1)&&($blng eq $lnwit1)) {$wit1match= $weights{"wit1"}};
  &isnotnull($fnwit1);
  if(($truth==1)&&($bfng eq $fnwit1)) {$wit1match= $weights{"wit1"}};
  &isnotnull($lnwit2);
  if(($truth==1)&&($blng eq $lnwit2)) {$wit2match= $weights{"wit2"}};
  &isnotnull($fnwit2);
  if(($truth==1)&&($bfng eq $fnwit2)) {$wit2match=$weights{"wit2"}};

  $summatch = $parmatch+$fnmatch+$sxmatch+$lnmatch+$pobmatch+$presmatch+$pburmatch+
    +$fnfmatch+$aammatch+$wit1match+$wit2match;


  return($summatch, $aam);

}
