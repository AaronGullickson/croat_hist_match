########################
# m2b.pl               #
# Perl Program         #
# Aaron Gullickson     #
# 9/14/00              #
########################

######################################################################
# SUMMARY
#
# This program will link births to the marriages they must have come
# from.  It should work pretty well, because the combination of
# husband's and wive's names are almost always unique.  We will also be
# able to easily compare it to Marcia's work in combodat.
#
# For each birth, the script will look at the reported names of the parents.
# If it can find an exact match in the marriage records, it accepts it because
# this is almost certainly the right one (no duplicates).  If not, then it 
# collects all marriages in which three of the four names matched (both first
# names must always match but it allows one of the last names of either spouse to be missing).  It then scores all of these possibilities based upon various
# factors including birth spacing and the age of the mother at birth (where age
# of wife is reported) and picks the top score.
#
# This will now be the first script run as it is the most reliable - so
# we will use it to make decisions about b2d and b2m rather than the other
# way around.
#
# In addition to finding children of parent, this script will also build
# "kinsets" - groups of children who appear to be related by parents names
# but whose parents cannot be found in the marriage records.  This will allow
# us to look at lateral kin relations later on.
#
######################################################################

require generalsubs;

$na="NA";
$none="";
$mindur=-4;
$maxdur=40;
$maxint=10;

$minscore=40;



%weights = (
	    "parish"  =>  5,
	    "pof"     => 10,
	    "pom"     =>  5,
	    "int"     => 20,
	    "name"    => 10,
	    "witness" =>  5,
	   );

#these are the minimum intervals accepted between births - most are
#based on biological necessity (more or less).  The first one is based on the
#earliest pre-marital birth in Marcia's dataset.

%minint = (
	   "0"  => -3.578,
	   "1"  => .75,
	   "2"  => .75,
	   "3"  => .75,
	   "4"  => .75,
	   "5"  => .75,
	   "6"  => .75,
	   "7"  => .75,
	   "8"  => .75,
	   "9"  => .75,
	   "10" => .75,
	   "11" => .75,
	   "12" => .75,
	   "13" => .75,
	   "14" => .75,
	  );

#intervals between births for scoring - based on combodat

%maxint = (
	   "0"  => 24.7,
	   "1"  => 19.77,
	   "2"  => 24.22,
	   "3"  => 19.38,
	   "4"  => 16.6,
	   "5"  => 19.32,
	   "6"  => 14.26,
	   "7"  => 10.99,
	   "8"  => 9.024,
	   "9"  => 9.605,
	   "10" => 7.77,
	   "11" => 9.532,
	   "12" => 6.709,
	   "13" => 3.148,
	   "14" => 3,
	  );

%lowerqint = (
	      "0"  => 0.887,
	      "1"  => 1.579,
	      "2"  => 1.697,
	      "3"  => 1.781,
	      "4"  => 1.788,
	      "5"  => 1.78,
	      "6"  => 1.776,
	      "7"  => 1.641,
	      "8"  => 1.665,
	      "9"  => 1.575,
	      "10" => 1.529,
	      "11" => 1.663,
	      "12" => 1.483,
	      "13" => 1.274,
	      "14" => 1.25,
	     );

%upperqint = (
	      "0"  => 2.209,
	      "1"  => 3.086,
	      "2"  => 3.13,
	      "3"  => 3.164,
	      "4"  => 3.244,
	      "5"  => 3.167,
	      "6"  => 3.153,
	      "7"  => 3.114,
	      "8"  => 3.122,
	      "9"  => 3.115,
	      "10" => 2.856,
	      "11" => 2.924,
	      "12" => 2.493,
	      "13" => 2.256,
	      "14" => 2.25,
	     );

%meanint = (
	    "0"  => 1.97,
	    "1"  => 2.611,
	    "2"  => 2.657,
	    "3"  => 2.648,
	    "4"  => 2.696,
	    "5"  => 2.606,
	    "6"  => 2.584,
	    "7"  => 2.539,
	    "8"  => 2.488,
	    "9"  => 2.456,
	    "10" => 2.24,
	    "11" => 2.382,
	    "12" => 2.061,
	    "13" => 1.627,
	    "14" => 1.5,
	   );


&get_date_time;

#input files
$binfile="input/sortedbirths.tsv";
$minfile="input/sortedmars.tsv";
open (BIRIN,"<$binfile") || die ("cant open"." $binfile");
open (MARIN,"<$minfile") || die ("cant open"." $minfile");

#output files
$matchfile="output/m2b.matches.txt";
$prelimfile="output/m2b.match.prelim.txt";
$detailfile="output/diagnostics/m2b.diag.txt";
$sortfile="output/m2b.sorted.txt";
$namesfile="output/m2b.names.txt";
$kinfile="output/m2b.kin.txt";
open (PRELIM, ">$prelimfile") || die ("cant open"." $prelimfile");
open (FINAL,">$matchfile") || die ("cant open "."$matchfile");
open (DETAIL, ">$detailfile") || die ("cant open "."$detailfile");
open (SORT, ">$sortfile") || die ("cant open "."$sortfile");
open (NAMES, ">$namesfile") || die ("cant open "."$namesfile");
open (KIN, ">$kinfile") || die ("cant open "."$kinfile");

print ("Program name is m2b.pl\n");

print(DETAIL "Detail file for m2b.pl\n");
print(DETAIL "Program started on "."$daterun "."$yrrun"." at "."$timerun\n\n");

@MAR = <MARIN>;
$mar_length = scalar @MAR;
@BIRTH = <BIRIN>;
$bir_length = scalar @BIRTH;


#################
# Section 1: set up hashes

#Set up a hash with the marriage name combo as the key

print("Beginning Section 1: Building hashes\n");

%mar_hash=();
$missing_hfn=0;
$missing_wfn=0;
$missing_hln=0;
$missing_wln=0;
%m2b_hash=();
%mdate_hash=();
%bdate_hash=();
%temp1_hash=();
%temp2_hash=();

foreach $mar(@MAR) {

  ($mpar,$mi,$mid,$muni,$myrdate,$myyy,$mmm,$mdd,$mfnh,$mlnh,$mmstath,
   $mageh,$mpoh,$mfnhfa,$mfnw,$mlnw,$mmstatw,$magew,$mpow,$mfnwrel,
   $mtypwrel,$mfnwit1,$mlnwit1,$mpowit1,$mfnwit2,$mlnwit2,$mpowit2,
   $mlnhfull,$mlnwfull,$mlnwit1full,$mlnwit2full,$mnamef,$mnames,
   $mmatchflag)=split("\t", $mar);

  $line=join("\t", $mid, $na, 0);

  $m2b_hash{$mid}=$line;
  $mdate_hash{$mid}=$myrdate;

  $mfnh = &stripwhite($mfnh);
  $mlnh = &stripwhite($mlnh);
  $mfnw = &stripwhite($mfnw);
  $mlnw = &stripwhite($mlnw);

  $missing_hfn=$missing_hfn + &isnull($mfnh);
  $missing_wfn=$missing_wfn + &isnull($mfnw);
  $missing_hln=$missing_hln + &isnull($mlnh);
  $missing_wln=$missing_wln + &isnull($mlnw);

  #I will match on three possibilitiess: 
	# - father first and last and mother first
	# - father first and mother first
	# - all four names.

  #match on three

  $names="$mfnh"."$mlnh"."$mfnw";
  push(@{$mar_hash{$names}}, $mar);

  $names="$mfnh"."$mfnw"."$mlnw";
  push(@{$mar_hash{$names}}, $mar);

  #match on all four

  $names="$mfnh"."$mlnh"."$mfnw"."$mlnw";
  push(@{$mar_hash{$names}}, $mar);

  $temp1_hash{$names}=1;


}

#I can see how many unique name combos there were for all four
$unique1=scalar keys %temp1_hash;

print("Section 1 Done\n");

################
# Now loop through births and find corresponding potential marriages

print("Beginning Section 2: linking births to parent's marriage\n");

$match=0;
$ties=0;
@links=();
@unlinked=();

$missing_ffn=0;
$missing_mfn=0;
$missing_fln=0;
$missing_mln=0;

foreach $birth(@BIRTH) {

  ($bpar,$bid1,$bid2,$uni,$bdate,$byyy,$bmm,$bdd,$bfn,$bsx,$bfnf,$blnf,
   $bfnm,$blnm,$bpob,
   $bfng,$blng,$bpog) = split("\t",$birth);

  $bid2=~s/\s//g;


  $bdate_hash{$bid2}=$bdate;

  $bfnf = &stripwhite($bfnf);
  $blnf = &stripwhite($blnf);
  $bfnm = &stripwhite($bfnm);
  $blnm = &stripwhite($blnm);

  $missing_ffn = $missing_ffn + &isnull($bfnf);
  $missing_mfn = $missing_mfn + &isnull($bfnm);
  $missing_fln = $missing_fln + &isnull($blnf);
  $missing_mln = $missing_mln + &isnull($blnm);

  $key="$bfnf"."$blnf"."$bfnm"."$blnm";

  @marriages = @{$mar_hash {$key}};

  #if this is empty then look for other marriages.  If it is
  #not empty then it is certainly the right one - so go no further

  if(&isnull($marriages[0])) {

    $key="$bfnf"."$blnf"."$bfnm";

    @marriages2 = @{$mar_hash {$key}};

    foreach $line(@marriages2) {

      push(@marriages, $line);

    }

    $key="$bfnf"."$bfnm"."$blnm";

    @marriages2 = @{$mar_hash {$key}};

    foreach $line(@marriages2) {

      push(@marriages, $line);

    }

  }

  $empty=1;

  @temp=();

  #now score each of these potential marriages.  See matchrecs below
  #for details

  foreach $mar(@marriages) {

    $score=0;

    ($mpar,$mi,$mid,$muni,$myrdate,$myyy,$mmm,$mdd,$mfnh,$mlnh,$mmstath,
     $mageh,$mpoh,$mfnhfa,$mfnw,$mlnw,$mmstatw,$magew,$mpow,$mfnwrel,
     $mtypwrel,$mfnwit1,$mlnwit1,$mpowit1,$mfnwit2,$mlnwit2,$mpowit2,
     $mlnhfull,$mlnwfull,$mlnwit1full,$mlnwit2full,$mnamef,$mnames,
     $mmatchflag)=split("\t", $mar);

    $mar_history=$m2b_hash{$mid};

    ($mid, $lastdate, $numkids, $kids)=split("\t", $mar_history);

    #for now only one limit, birth must occur within certain time period from
    #marriage

    $duration = $bdate - $myrdate;

    $birth_interval=$bdate - $lastdate;

    #put in another requirement - if magew is given, birth must occur before she hits age 55

    if(&isnot_na($magew)) {

      $motherage=$duration+$magew;

    } else {

      $motherage=25;

    }

    if($duration>$mindur && $duration<$maxdur && $birth_interval>=0 && $numkids<14 && $motherage<55) {

      $score=&matchrecs;

      if($score>$minscore) {

	$empty=0;

	push(@temp, join("\t", $score, $bdate, $bid2, $mid));

      }

    }

  }

  if($empty) {

    printf(PRELIM "%6d\t %s\t %s\t %s\n", $bid2, $na, $na, $na);

    #assign this birth to the unlinked birth array to later
    #build sibsets with.

    push(@unlinked, $birth);

  } else {

    $match = $match + 1;

    @temp = sort {$b<=>$a} @temp;

    ($score1, $bdate1, $bid1, $mid1)=split("\t", $temp[0]);
    ($score2, $bdate2, $bid2, $mid2)=split("\t", $temp[1]);

    $mar_history=$m2b_hash{$mid1};

    ($mid, $lastdate, $numkids, $kids)=split("\t", $mar_history);

    $lastdate>$bdate1 &&  die("birthdates out of order");

    $lastdate=$bdate1;

    if(&isnull($kids)) {

      $kids="$bid1";

      $numkids=1;

    } else {

      $kids="$kids $bid1";

      $numkids=$numkids+1;

    }

    $m2b_hash{$mid}=join("\t", $mid, $lastdate, $numkids, $kids);


    if($score1==$score2  && $mid1!=$mid2) {

      $ties=$ties+1;

    }

    foreach $ref(@temp) {

      ($score, $bdate, $bid, $mid)=split("\t", $ref);

      printf(PRELIM "%6d\t %6d\t %6d\t %6d\n", $bid, $mid, $bdate, $score);

    }

  }

}

print("Section 2 Done\n");

print("Beginning Section 3: linking kin-sets\n");

%kin_hash=();

$unmatched=scalar @unlinked;
$accepted1=0;
$accepted2=0;
$keychanger=1;

foreach $birth(@unlinked) {

  ($bpar,$bid1,$bid2,$uni,$bdate,$byyy,$bmm,$bdd,$bfn,$bsx,$bfnf,$blnf,$bfnm,$blnm,$bpob,
   $bfng,$blng,$bpog) = split("\t",$birth);

  $bfnf = &stripwhite($bfnf);
  $blnf = &stripwhite($blnf);
  $bfnm = &stripwhite($bfnm);
  $blnm = &stripwhite($blnm);

  if(&isnotnull($bfnf) && &isnotnull($blnf) && &isnotnull($bfnm)) {

    $accepted1++;

    $key="$bfnf"."$blnf"."$bfnm";

    $line=$kin_hash{"$key"};
    ($firstdate, $lastdate, $numkids, $kids)=split("\t", $line);


    #make some simple rules governing acceptance into kin set.
    #no more than $maxint years between births, no more than max time between
    #first and final birth - if they dont, make it here then start a new kinset

    if(&isnull($lastdate)) {

      $firstdate=$bdate;
      $lastdate=$bdate-.75;

    }

    $duration=$bdate-$firstdate;
    $birth_interval=$bdate-$lastdate;

    $lastdate=$bdate;
    $numkids=$numkids+1;
    $kids=join(" ", $kids, $bid2);


    if(($birth_interval>=.75 || $birth_interval==0) && $birth_interval<=$maxint && $duration<$maxdur) {

      $accepted2++;

      $kin_hash{"$key"} = join("\t", $firstdate, $lastdate, $numkids, $kids);

    } else {

      #start new kinset

      #all of these should be in temporal order, so all subsequent kids will also
      #fall into this new kinset

      #first change the key on the old one so that we can use this one

      $kin_hash{"$key".$keychanger}=$line;

      $accepted2++;

      $keychanger++;

      $firstdate=$bdate;
      $lastdate=$bdate;
      $numkids=1;
      $kids=$bid2;

      $kin_hash{"$key"} = join("\t", $firstdate, $lastdate, $numkids, $kids);

    }

  }

}

print("Section 3 Done\n");

print("Beginning Section 4: Printing results\n");

@keys=keys(%m2b_hash);
@kids_linked=();


foreach $key(@keys) {

  $marriage=$m2b_hash{$key};

  ($mid,$lastdate,$numkids,$kids)=split("\t", $marriage);

  push(@kids_linked, $numkids);

  ($idk1,$idk2,$idk3,$idk4,$idk5,$idk6,$idk7,$idk8,$idk9,
   $idk10,$idk11,$idk12,$idk13,$idk14)=split(" ", $kids);

  $idk1=~s/\s//g;

  $firstdur=$bdate_hash{$idk1}-$mdate_hash{$mid};
  $lastdur=$lastdate-$mdate_hash{$mid};

  if(&isnull($idk1))  {$idk1=$na};
  if(&isnull($idk2))  {$idk2=$na};
  if(&isnull($idk3))  {$idk3=$na};
  if(&isnull($idk4))  {$idk4=$na};
  if(&isnull($idk5))  {$idk5=$na};
  if(&isnull($idk6))  {$idk6=$na};
  if(&isnull($idk7))  {$idk7=$na};
  if(&isnull($idk8))  {$idk8=$na};
  if(&isnull($idk9))  {$idk9=$na};
  if(&isnull($idk10)) {$idk10=$na};
  if(&isnull($idk11)) {$idk11=$na};
  if(&isnull($idk12)) {$idk12=$na};
  if(&isnull($idk13)) {$idk13=$na};
  if(&isnull($idk14)) {$idk14=$na};

  $line=join("\t", $mid,$lastdate,$numkids,$idk1,$idk2,$idk3,$idk4,$idk5,$idk6,$idk7,$idk8,$idk9,
	     $idk10,$idk11,$idk12,$idk13,$idk14);

  print(FINAL "$line\n");

}

#Now print out kinsets

@keys=keys(%kin_hash);
@kids_unlinked=();

$id=30001;

foreach $key(@keys) {

  $marriage=$kin_hash{$key};

  ($firstdate, $lastdate,$numkids,$kids)=split("\t", $marriage);

  push(@kids_unlinked, $numkids);

  ($idk1,$idk2,$idk3,$idk4,$idk5,$idk6,$idk7,$idk8,$idk9,
   $idk10,$idk11,$idk12,$idk13,$idk14)=split(" ", $kids);

  if(&isnull($idk1))  {$idk1=$na};
  if(&isnull($idk2))  {$idk2=$na};
  if(&isnull($idk3))  {$idk3=$na};
  if(&isnull($idk4))  {$idk4=$na};
  if(&isnull($idk5))  {$idk5=$na};
  if(&isnull($idk6))  {$idk6=$na};
  if(&isnull($idk7))  {$idk7=$na};
  if(&isnull($idk8))  {$idk8=$na};
  if(&isnull($idk9))  {$idk9=$na};
  if(&isnull($idk10)) {$idk10=$na};
  if(&isnull($idk11)) {$idk11=$na};
  if(&isnull($idk12)) {$idk12=$na};
  if(&isnull($idk13)) {$idk13=$na};
  if(&isnull($idk14)) {$idk14=$na};

  $line=join("\t", $id,$lastdate,$numkids,$idk1,$idk2,$idk3,$idk4,$idk5,$idk6,$idk7,$idk8,$idk9,
	     $idk10,$idk11,$idk12,$idk13,$idk14);

  print(FINAL "$line\n");

  $id=$id+1;

}

$family_size_linked = &sum (@kids_linked) / scalar @kids_linked;
$family_size_unlinked = &sum (@kids_unlinked) / scalar @kids_unlinked;

print("Section 4 Done\n");


####

print(DETAIL "There were $mar_length marriages\n");
print(DETAIL "There were $bir_length births\n\n");

print(DETAIL "There were $unique1 unique name combinations when all four were used\n\n");
print(DETAIL "$missing_hfn marriages were missing husband's first name\n");
print(DETAIL "$missing_hfn marriages were missing wife's first name\n");
print(DETAIL "$missing_hln marriages were missing husband's last name\n");
print(DETAIL "$missing_wln marriages were missing wife's last name\n\n");

print(DETAIL "$missing_ffn births were missing father's first name\n");
print(DETAIL "$missing_mfn births were missing mother's first name\n");
print(DETAIL "$missing_fln births were missing father's last name\n");
print(DETAIL "$missing_mln births were missing mother's last name\n\n");

print(DETAIL "There were $match matches\n");
$percent = $match/$bir_length * 100;
print(DETAIL "$percent percent of births were linked to a marriage\n\n");

print(DETAIL "There were $unmatched unmatched births\n");
print(DETAIL "Of these, $accepted1 had sufficient parental names\n");
print(DETAIL "Of these, $accepted2 were accepted into kinsets\n\n");

print(DETAIL "The average family size in linked families was $family_size_linked\n");
print(DETAIL "The average family size in unlinked families was $family_size_unlinked\n");


print(DETAIL "There were $ties births that had tied marriage links\n\n");

&get_date_time;


print(DETAIL "Program ended on "."$daterun "."$yrrun"." at "."$timerun\n\n");

print("Program complete.\n");

###############################################################
# Matching routine

sub matchrecs {

  #first add to score if mother's last name matches as well

  #for first children, the birth interval will
  #be the duration

  if($numkids==0) {

    $birth_interval=$duration;

  }

  #first make sure that birth interval falls within min and max

  if($birth_interval<$minint{$numkids} || $birth_interval>$maxint{$numkids}) {

    if($birth_interval==0) {

      $intmatch=$weights{"int"};

    } else {

      $score=0;

      return($score);

    }

  }

  #if it falls in range, then

  if($birth_interval>$lowerqint{$numkids} && $birth_interval<$upperqint{$numkids}) {

    #give the maximum score

    $intmatch = $weights{"int"};

  } else {

    #give linearly declining score

    if($birth_interval<=$lowerqint{$numkids}) {

      $diff = $lowerqint{$numkids} - $birth_interval;
      $scale = 1 - $diff/(abs($lowerqint{$numkids}-abs($minint{$numkids})));
      $intmatch = $scale * $weights{"int"};

    }

    if($birth_interval>=$upperqint{$numkids}) {

      $diff = $birth_interval - $upperqint{$numkids};
      $scale = 1 - $diff/($maxint{$numkids}-$upperqint{$numkids});
      $intmatch = $scale * $weights{"int"};

    }

  }

  #if birth interval is zero handle in a special way

  if($birth_interval==0) {

    $intmatch=$weights{"int"};

  }

  $mfnh = &stripwhite($mfnh);
  $mlnh = &stripwhite($mlnh);
  $mfnw = &stripwhite($mfnw);
  $mlnw = &stripwhite($mlnw);

  $score = $score + $intmatch;

  if("$mfnw" eq "$bfnm" && &isnotnull($bfnm)) {$score=$score+$weights{"name"};}

  if("$mlnw" eq "$blnm" && &isnotnull($bfnm)) {$score=$score+$weights{"name"};}

  if("$mfnh" eq "$bfnf" && &isnotnull($bfnm)) {$score=$score+$weights{"name"};}

  if("$mlnh" eq "$blnf" && &isnotnull($bfnm)) {$score=$score+$weights{"name"};}

  if("$bpar" eq  "$mpar" && &isnotnull($bpar)) {$score=$score+$weights{"parish"};}

  if("$mlnwit1" eq "$blng" && &isnotnull($blng)) {$score=$score+$weights{"witness"};}

  if("$bpob" eq "$mpoh" && &isnotnull($bpob)) {$score=$score+$weights{"pof"};}

  if("$bpob" eq "$mpow" && &isnotnull($bpob)) {$score=$score+$weights{"pom"};}

  return($score);

}
