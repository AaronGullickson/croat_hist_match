########################
# g2p.pl               #
# Perl Program         #
# Aaron Gullickson     #
# 11/13/02             #
########################

######################################################################
# SUMMARY
#
# This program will link godparents from birth records
# and witnesses from marriage records to their own birth records (marriage records, death records?).
# 
# Since godparenthood often occured mutiple times in the same family (we think)
# I will start with the m2b records as these give us added oomph. 
#
# CHANGE: I am now going to link the godparents to information about
# mothers and fathers in the birth record.  I would like to expand this
# later to look for potential links in the marriage, birth, and death records
# (actually, to just link to croatdata3.txt based on names with multiple 
#  name possibilities for women), but for now we will just do this because
# it solves problem with women's last names.  It should be fine for the 
# mat mortality research because we are only interested in godparents who were 
# themselves grandparents (thus they had to be a mother or father).  However,
# it may become necessary to be more broad when we talk about the survival of 
# the elderly based on their kin networks.
#
######################################################################

require generalsubs;

&get_date_time;

%weights = (
	    "parish" =>  5,
	    "fn"     => 10,
	    "ln"     => 10,
	    "pob"    => 10,
	    "real"   =>  5,
	    "prev"   => 10
	   );

$minage=15;
$maxage=90;
$marriageage=25;
$firstbirthage=28;

$binfile="input/sortedbirths.tsv";
$minfile="input/sortedmars.tsv";
$m2bfile="output/m2b.matches.tsv";
$fulldatafile="output/fulldata.tsv";
#$matchfile="output/g2p.matches.tsv";
$gpfile="output/godparent_dates.tsv";
#$prelimfile="output/g2p.match.prelim.txt";
$detailfile="output/diagnostics/g2p.diag.txt";
open (BIRIN,"<$binfile") || die ("cant open"." $binfile");
open (MARIN,"<$minfile") || die ("cant open"." $minfile");
open (M2B,"<$m2bfile") || die ("cant open"." $m2bfile");
open (CROAT,"<$fulldatafile") || die ("cant open"." $fulldatafile");
#open (PRELIM, ">$prelimfile") || die ("cant open"." $prelimfile");
#open (FINAL,">$matchfile") || die ("cant open "."$matchfile");
open (GP, ">$gpfile") || die ("cant open "."$gpfile");
open (DETAIL, ">$detailfile") || die ("cant open "."$detailfile");


print ("Program name is g2p.pl\n");

print(DETAIL "Detail file for g2p.pl\n");
print(DETAIL "Program started on "."$daterun "."$yrrun"." at "."$timerun\n\n"); 

#put data into hashes
print("Part I: Building Hashes\n");

%mar_hash=();
%birth_hash=();
%m2b_hash=();
%m2bkid_hash=();
%gp_hash=();

$n_validwit1=0;
$n_validwit2=0;

foreach $mar(<MARIN>) {
  
  ($mpar,$mi,$mid,$muni,$myrdate,$myyy,$mmm,$mdd,$mfnh,$mlnh,$mmstath,
   $mageh,$mpoh,$mfnhfa,$mfnw,$mlnw,$mmstatw,$magew,$mpow,$mfnwrel,
   $mtypwrel,$mfnwit1,$mlnwit1,$mpowit1,$mfnwit2,$mlnwit2,$mpowit2,
   $mlnhfull,$mlnwfull,$mlnwit1full,$mlnwit2full,$mnamef,$mnames,
   $mmatchflag)=split("\t", $mar);
  
  $mar_hash{$mid}=$mar;

  #get number of witnesses with both fields valid
  
  if(&isnotnull($mfnwit1) && &isnotnull($mlnwit1)) {
    $n_validwit1++;
  }
  if(&isnotnull($mfnwit2) && &isnotnull($mlnwit2)) {
    $n_validwit2++;
  }

}

foreach $birth(<BIRIN>) {

  ($bpar,$bid1,$bid2,$uni,$bdate,$byyy,$bmm,$bdd,$bfn,$bsx,$bfnf,$blnf,
   $bfnm,$blnm,$bpob,
   $bfng,$blng,$bpog) = split("\t",$birth);

  $bid2=~s/\s//g;

  $birth_hash{$bid2}=$birth;

}

#now build hash keyed by first and last name

$dads=0;
$moms=0;

foreach $rec (<CROAT>) {

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
   $remarok1,$remarok2,$remarok3,$remarok4,$remarok5,$remarok6,
   $remarok7,$remarok8,$remarok9,$remarok10,$remarok11,$remarok12,$remarok13,$remarok14,
   $park1,$park2,$park3,$park4,$park5,$park6,$park7,
   $park8,$park9,$park10,$park11,$park12,$park13,$park14)=split("\t",$rec);

  #fill in gp_hash

  $gp_hash{$bid}="";

  #use this dataset to create a parental hash which has the name of the parent and information about
  #them.
  #Men only get one of these because their information doesn't change.  Women get one for each marriage
  #that has children because their last name does change

  #if the person is not a "real" person (id>200000), then I need to impute
  #a birthdate so they can be accepted as possible links, for now I will impute
  #it based on their date of marriage (or birth) minus some constant factor
  
  #In the future, I would like to link these people to their probable deaths and births (m2ownb, m2m, m2d)
  
  if($bid>=200000 && &is_na($bdate)) {

    if(&isnot_na($mdate1)) {
    
      $bdate=$mdate1-$marriageage;
      
    } else {
      
      $bdate=$dobk1-$firstbirthage;
      
    }
    
  }

  if($sex eq "m") {
    
    #get first and last name from the first kid born (they have to be parents)
    
    if(&isnot_na($idk1)) {
      
      $birth=$birth_hash{$idk1};
      ($bpar,$bid1,$bid2,$uni,$bdate2,$byyy,$bmm,$bdd,$bfn,$bsx,$bfnf,$blnf,
       $bfnm,$blnm,$bpob,
       $bfng,$blng,$bpog) = split("\t",$birth);
      
      $bfnf=&stripwhite($bfnf);
      $blnf=&stripwhite($blnf);
      
      $key="$bfnf"."$blnf";
      
      #what other info - how to put it in there?
      #parish
      #place of each birth
      #death date

      if(&isnotnull($bfnf) && &isnotnull($blnf)) {
      
	$line=join("\t",$key,$bid,$bdate,$ddate,$bpar,$bpob);
	
#	print(PRELIM "$line\n");
	$dads++;
	push(@{$parent_hash{$key}}, $line);
      
      }
      
    }
    
  }

  if($sex eq "f") {

    @temp=($sidk1,$sidk2,$sidk3,$sidk4,$sidk5,$sidk6,$sidk7,$sidk8,$sidk9,$sidk10,
	   $sidk11,$sidk12,$sidk13,$sidk14);

    @idk=($idk1,$idk2,$idk3,$idk4,$idk5,$idk6,$idk7,$idk8,$idk9,$idk10,
	  $idk11,$idk12,$idk13,$idk14);

    $prev_sid=0;

    $i=0;

    for $sid (@temp) {

      if(&isnot_na($sid) && $sid!=$prev_sid) {
	
	#then it is a kid from a new marriage, so add to parent hash
	
	$birth=$birth_hash{$idk[$i]};
	($bpar,$bid1,$bid2,$uni,$bdate2,$byyy,$bmm,$bdd,$bfn,$bsx,$bfnf,$blnf,
	 $bfnm,$blnm,$bpob,
	 $bfng,$blng,$bpog) = split("\t",$birth);
	
	$bfnm=&stripwhite($bfnm);
	$blnm=&stripwhite($blnm);
	
	$key="$bfnm"."$blnf";
	
	#what other info - how to put it in there?
	#parish
	#place of each birth
	#death date

	if(&isnotnull($bfnm) && &isnotnull($blnf)) {
	  
	  $line=join("\t",$key,$bid,$bdate,$ddate,$bpar,$bpob,$sid,$prev_sid);
	  
#	  print(PRELIM "$line\n");
	  $moms++;
	  push(@{$parent_hash {$key}}, $line);
	  
	}

	#if the mother's last name is different from the father's 
	#then include that as a separate possibility

	if(&isnotnull($blnm) && $blnm ne $blnf) {

	  $key="$bfnm"."$blnm";
	  
	  $line=join("\t",$key,$bid,$did,$bpar,$bpob,$sid,$prev_sid);
	  
#	  print(PRELIM "$line\n");
	  $moms++;
	  push(@{$parent_hash {$key}}, $line);
	  
	}

      }
      
      $prev_sid=$sid;
      $i++;

    }
  
  }

}


#I need to rework m2b so that it produces fifteen hashes which are keyed 
#by the marriage id - correction one hash keyed by marriage id and parity

%g2p_hash=();
@marid2=();

foreach $line (<M2B>) {
  
  chop $line;
  
  ($mid,$lastdate,$numkids,$idk1,$idk2,$idk3,$idk4,$idk5,$idk6,$idk7,$idk8,$idk9,
   $idk10,$idk11,$idk12,$idk13,$idk14)=split("\t", $line);

  #only put in hash if there is a real birth
  #change this to a single hash where key is mid.parity

  if(&isnot_na($idk1)) {$m2bkid_hash{"$mid"."_1"}=$idk1;}
  if(&isnot_na($idk2)) {$m2bkid_hash{"$mid"."_2"}=$idk2;}
  if(&isnot_na($idk3)) {$m2bkid_hash{"$mid"."_3"}=$idk3;}
  if(&isnot_na($idk4)) {$m2bkid_hash{"$mid"."_4"}=$idk4;}
  if(&isnot_na($idk5)) {$m2bkid_hash{"$mid"."_5"}=$idk5;}
  if(&isnot_na($idk6)) {$m2bkid_hash{"$mid"."_6"}=$idk6;}
  if(&isnot_na($idk7)) {$m2bkid_hash{"$mid"."_7"}=$idk7;}
  if(&isnot_na($idk8)) {$m2bkid_hash{"$mid"."_8"}=$idk8;}
  if(&isnot_na($idk9)) {$m2bkid_hash{"$mid"."_9"}=$idk9;}
  if(&isnot_na($idk10)) {$m2bkid_hash{"$mid"."_10"}=$idk10;}
  if(&isnot_na($idk11)) {$m2bkid_hash{"$mid"."_11"}=$idk11;}
  if(&isnot_na($idk12)) {$m2bkid_hash{"$mid"."_12"}=$idk12;}
  if(&isnot_na($idk13)) {$m2bkid_hash{"$mid"."_13"}=$idk13;}
  if(&isnot_na($idk14)) {$m2bkid_hash{"$mid"."_14"}=$idk14;}

  push(@marid2,$mid);

}

@temp2=keys %m2bkid_hash;
$number_births=scalar @temp2;

#Now do preliminary matching
#I can't do this like I did the earlier matching by 
#creating a preliminary match file and then sorting this by
#score to get final matches because information about pervious birth
#is used in matching score for next birth.  Therefore, I must do the final
#matching for each even (marriage, first birth, second birth, etc.) before starting
#the next event

print("Part II: Scoring matches\n");

#create a hash to put successful links in based on witness/godparent's birth id

#start with marriage witness 1 and 2
@marid = keys(%mar_hash);

@links_wit1=();
@links_wit2=();
%mid1_notdone=();
%mid2_notdone=();

$n_prelimmatch_wit1=0;
%n_possmatch_wit1=();
$n_prelimmatch_wit2=0;
%n_possmatch_wit2=();

print("\tMarriage Witnesses:\n");
print("\t\tpreliminary matches\n");

foreach $mid (@marid) {

  #only look for witnesses for real marriages
  if($mid<30000) {
    
    $mar=$mar_hash{$mid};
    $mid1_notdone{$mid}=1;
    $mid2_notdone{$mid}=1;
    $n_possmatch_wit1{$mid}=0;
    $n_possmatch_wit2{$mid}=0;
    
    ($mpar,$mi,$mid,$muni,$myrdate,$myyy,$mmm,$mdd,$mfnh,$mlnh,$mmstath,
     $mageh,$mpoh,$mfnhfa,$mfnw,$mlnw,$mmstatw,$magew,$mpow,$mfnwrel,
     $mtypwrel,$mfnwit1,$mlnwit1,$mpowit1,$mfnwit2,$mlnwit2,$mpowit2,
     $mlnhfull,$mlnwfull,$mlnwit1full,$mlnwit2full,$mnamef,$mnames,
     $mmatchflag)=split("\t", $mar);
    
    $mfnwit1=&stripwhite($mfnwit1);
    $mlnwit1=&stripwhite($mlnwit1);
    $mfnwit2=&stripwhite($mfnwit2);
    $mlnwit2=&stripwhite($mlnwit2);
    
    $key1="$mfnwit1"."$mlnwit1";
    $key2="$mfnwit2"."$mlnwit2";

    @array1 = @{$parent_hash {$key1}};
    @array2 = @{$parent_hash {$key2}};

    #now I will loop through the array that had all matching names and score
    #each possible link.  If the link score is high enough it will be added
    #to list of all possible links
  
    foreach $ref(@array1) {
      
      ($stuff,$bid2,$bdate,$ddate,$bpar,$bpob)=split("\t",$ref);
 
      #how to deal with the 400000+ crowd.  Perhaps give them a 
      #negative weight to preference real people.

      #make sure they are alive and meet some minimum age requirement

      #if I don't know ddate then impute a maximum reasonable value 

      if(&is_na($ddate)) {
	$ddate=$bdate+$maxage;
      }

      if($myrdate>$ddate || ($myrdate-$bdate)<$minage) {
	
	next;
	
      }
      
      $score=&matchrecs_witness1;

      if($score>0) {

	$n_prelimmatch_wit1++;
	$n_possmatch_wit1{$mid}++;

	#add it to potential links for first witness
	$answer=join("\t", $score, $mid, $bid2, $myrdate);
	
	push(@link_wit1, $answer);

      }

    }

    foreach $ref(@array2) {
      

      ($stuff,$bid2,$bdate,$ddate,$bpar,$bpob)=split("\t",$ref);

      if(&is_na($ddate)) {
	$ddate=$bdate+$maxage;
      }

      if($bid2>200000 || $myrdate>$ddate || ($myrdate-$bdate)<$minage) {
	
	next;
	
      }
      
      $score=&matchrecs_witness2;

      if($score>0) {
	
	$n_prelimmatch_wit2++;
	$n_possmatch_wit2{$mid}++;

	$answer=join("\t", $score, $mid, $bid2, $myrdate);
	
	push(@link_wit2, $answer);
	
	
      }
      
    }

  }

}

#sort and assign final scores

print("\t\tfinal matching\n");

@link_wit1 = sort {$b<=>$a} @link_wit1;

$n_finalmatch_wit1=0;

foreach $wit1(@link_wit1) {
  
  ($score, $mid, $bid2, $myrdate)=split("\t", $wit1);
    
  if($mid1_notdone{$mid}) {
    
    $g2p_hash{$mid}=join("\t",$mid,$bid2);
    #put in godparent hash
    $gp_hash{$bid2}=join("\t",$gp_hash{$bid2},$myrdate);


    $n_finalmatch_wit1++;

    $mid1_notdone{$mid}=0;

  } 
  
} 

#fill in NAs
#use second marriage ID array now to include non-observed marriages

foreach $mkey(@marid2) {

  if($mid1_notdone{$mkey}) {

    $g2p_hash{$mkey}=join("\t",$mkey,"NA");

  }
  
}

@link_wit2 = sort {$b<=>$a} @link_wit2;

$n_finalmatch_wit2=0;

foreach $wit2(@link_wit2) {
  
  ($score, $mid, $bid2, $myrdate)=split("\t", $wit2);
  
  if($mid2_notdone{$mid}) {

    $g2p_hash{$mid}=join("\t",$g2p_hash{$mid},$bid2);
    $gp_hash{$bid2}=join(" ",$gp_hash{$bid2},$myrdate);

    $n_finalmatch_wit2++;
    
    $mid2_notdone{$mid}=0;
  
  }

}

#put in NAs where missing 2nd witness

foreach $mkey(@marid2) {

  if($mid2_notdone{$mkey}) {

      $g2p_hash{$mkey}=join("\t",$g2p_hash{$mkey},"NA");

  }
  
}

######################################################################################
#now get matches for first kid
#change this to match on all fourteen kids

@parity=(1,2,3,4,5,6,7,8,9,10,11,12,13,14);

$links_gp=();
%bid1_notdone=();

$n_prelimmatch_gp1=0;
%n_possmatch_gp1=();

%finalscore=();
@ties=(0,0,0,0,0,0,0,0,0,0,0,0,0,0);
@length_bid=(0,0,0,0,0,0,0,0,0,0,0,0,0,0);
@matched=(0,0,0,0,0,0,0,0,0,0,0,0,0,0);

foreach $parity(@parity) {

    print("\tBirth $parity\n");
    print("\t\tpreliminary matching\n");

    foreach $key(@marid2) {
    
	$idk=$m2bkid_hash{"$key"."_"."$parity"};

	if($key==11746 && $parity==2) {

	  $bob=1;

	}

	#get previous ids to see if the same
	@prev_ids=split("\t",$g2p_hash{$key});

	#make sure there is a real birth here - if not then skip the rest

	if(&isnotnull($idk)) {

	    $length_bid[$parity-1]++;
	    
	    $birth=$birth_hash{$idk};
      
	    chop $birth;
	    
	    ($bpar,$bid1,$bid2,$uni,$bdate,$byyy,$bmm,$bdd,$bfn,$bsx,$bfnf,$blnf,
	     $bfnm,$blnm,$bpob,
	     $bfng,$blng,$bpog) = split("\t",$birth);
	    
	    $bid_notdone{"$key"."_"."$parity"}=1;
	    
	    $name="$bfng"."$blng";
	    
	    @array = @{$parent_hash {$name}};
	    
	    #Make sure a couple of conditions hold	    
	    foreach $ref(@array) {
		
		($stuff,$bid_gp,$bdate_gp,$ddate_gp,$bpar_gp,$bpob_gp)=split("\t",$ref);
		
		#can't have died before birthday and must be at least minimum age
		
		if(&is_na($ddate_gp)) {
		    $ddate_gp=$bdate_gp+$maxage;
		}
		
		if($ddate_gp>$bdate && ($bdate-$bdate_gp)>$minage) {
		    
		    $score=&matchrecs_godp;
		    
		    if($score>0) {
			
			$answer=join("\t", $score, $key, $bid2, $bid_gp, $bdate);
			
			push(@{$link_gp {$parity}}, $answer);
			
			#print(PRELIM "$answer\n");
			
		    }
		    
		}
		
	    }
	    
	}
	
    }

    print("\t\tfinal matching\n");

    @link_gp=@{$link_gp{$parity}};

    @link_gp = sort {$b<=>$a} @link_gp;

    foreach $gp(@link_gp) {
    
	($score, $mid, $bid_kid, $bid_gp, $bdate)=split("\t", $gp);
    
	if($bid_notdone{"$mid"."_"."$parity"}) {
     
	    $g2p_hash{$mid}=join("\t",$g2p_hash{$mid},$bid_gp);
	    $gp_hash{$bid_gp}=join(" ",$gp_hash{$bid_gp},$bdate);

	    $bid_notdone{"$mid"."_"."$parity"}=0;
	    
	    $finalscore{"$mid"."_"."$parity"}=$score;
      
	    $matched[$parity-1]++;

	} else {

	    #find out if tied

	    if($finalscore{"$mid"."_"."$parity"}==$score) {

		$ties[$parity-1]++;

	    }

	}
	
    } 

    foreach $mkey(@marid2) {
    
	if($bid_notdone{"$mkey"."_"."$parity"}) {
	    
	    $g2p_hash{$mkey}=join("\t",$g2p_hash{$mkey},"NA");
	    
	}
	
    }
    
}

####################################################
# print out final data

print("Part III: Printing out final data\n");

@temp = keys(%g2p_hash);

for $mid (@temp) {

  #print(FINAL "$g2p_hash{$mid}\n");

}

@temp = keys(%gp_hash);

for $bid (@temp) {

  print(GP "$bid\t$gp_hash{$bid}\n");

}



#############################################################################################
# Report Diagnostics

print(DETAIL "There were $n_validwit1 valid first witnesses and $n_validwit2 second witnesses\n\n");

print(DETAIL "There were $dads dads and $moms moms who could be linked from croatdata3.txt\n\n");

print(DETAIL "There were $n_prelimmatch_wit1 preliminary matches for the first witness\n");
print(DETAIL "There were $n_prelimmatch_wit2 preliminary matches for the second witness\n\n");

#calculate average number of matches
@keys = keys %n_possmatch_wit1;
$sum=0;
$more=0;
foreach $key (@keys) { 
  $n=$n_possmatch_wit1{$key};
  $sum=$sum+$n;
  $more=$more+($n>1);
}

$length=scalar @keys;
$average=$sum/$length;
$prop=$more/$length;
print(DETAIL "On average, there were $average potential matches for each first witness link\n");
print(DETAIL "The proportion of first witness links with more than one possible match was $prop\n");

print(DETAIL "There were $n_finalmatch_wit1 final matches for the first witness\n");
print(DETAIL "There were $n_finalmatch_wit2 final matches for the second witness\n\n");

print(DETAIL "There were $length_bid[0] first parity births\n");
print(DETAIL "There were $matched[0] linked first parity births\n");
print(DETAIL "There were $ties[0] ties for parity one godparents\n\n");

print(DETAIL "There were $length_bid[1] second parity births\n");
print(DETAIL "There were $matched[1] linked second parity births\n");
print(DETAIL "There were $ties[1] ties for parity two godparents\n\n");

print(DETAIL "There were $length_bid[2] third parity births\n");
print(DETAIL "There were $matched[2] linked third parity births\n");
print(DETAIL "There were $ties[2] ties for parity three godparents\n\n");

print(DETAIL "There were $length_bid[3] fourth parity births\n");
print(DETAIL "There were $matched[3] linked fourth parity births\n");
print(DETAIL "There were $ties[3] ties for parity four godparents\n\n");

print(DETAIL "There were $length_bid[4] fifth parity births\n");
print(DETAIL "There were $matched[4] linked fifth parity births\n");
print(DETAIL "There were $ties[4] ties for parity five godparents\n\n");

print(DETAIL "There were $length_bid[5] sixth parity births\n");
print(DETAIL "There were $matched[5] linked sixth parity births\n");
print(DETAIL "There were $ties[5] ties for parity six godparents\n\n");

print(DETAIL "There were $length_bid[6] seventh parity births\n");
print(DETAIL "There were $matched[6] linked seventh parity births\n");
print(DETAIL "There were $ties[6] ties for parity seven godparents\n\n");

print(DETAIL "There were $length_bid[7] eighth parity births\n");
print(DETAIL "There were $matched[7] linked eighth parity births\n");
print(DETAIL "There were $ties[7] ties for parity eight godparents\n\n");

print(DETAIL "There were $length_bid[8] ninth parity births\n");
print(DETAIL "There were $matched[8] linked ninth parity births\n");
print(DETAIL "There were $ties[8] ties for parity nine godparents\n\n");

print(DETAIL "There were $length_bid[9] tenth parity births\n");
print(DETAIL "There were $matched[9] linked tenth parity births\n");
print(DETAIL "There were $ties[9] ties for parity ten godparents\n\n");

print(DETAIL "There were $length_bid[10] eleventh parity births\n");
print(DETAIL "There were $matched[10] linked eleventh parity births\n");
print(DETAIL "There were $ties[10] ties for parity eleven godparents\n\n");

print(DETAIL "There were $length_bid[11] twelfth parity births\n");
print(DETAIL "There were $matched[11] linked twelfth parity births\n");
print(DETAIL "There were $ties[11] ties for parity twelve godparents\n\n");

print(DETAIL "There were $length_bid[12] thirteenth parity births\n");
print(DETAIL "There were $matched[12] linked thirteenth parity births\n");
print(DETAIL "There were $ties[12] ties for parity thirteen godparents\n\n");

print(DETAIL "There were $length_bid[13] fourteenth parity births\n");
print(DETAIL "There were $matched[13] linked fourteenth parity births\n");
print(DETAIL "There were $ties[13] ties for parity fourteen godparents\n\n");

$totallinks=&sum(@matched);
$totalbirths=&sum(@length_bid);

print(DETAIL "All together, $totallinks godparents were matched for $totalbirths births\n");
print(DETAIL "$number_births births\n");

print("Program complete\n");

#############################################################################################
# Matching Subroutines


sub matchrecs_witness1 {

  #inits
  $parmatch=0;
  $fnmatch=$weights{"fn"};
  $lnmatch=$weights{"ln"};
  $pobmatch=0;
  $realmatch=0;
  $summatch=0;
  
  #calculate whether any or previous godparent/witness id is the same
  #not yet implemented

  &isnotnull($bpar);
  if(($truth==1)&&($bpar eq $mpar))   {$parmatch = $weights{"parish"}};
  &isnotnull($bpob);
  if(($truth==1)&&($bpob eq $mpowit1))    {$pobmatch = $weights{"pob"}};
  
  if($bid2<200000) {$realmatch = $weights{"real"}};

  $summatch = $parmatch+$fnmatch+$lnmatch+$pobmatch+$realmatch;
  
  return($summatch);
  
}

sub matchrecs_witness2 {

  #names can be matched to marriage or birth so just give the points

  #inits
  $parmatch=0;
  $fnmatch=$weights{"fn"};
  $lnmatch=$weights{"ln"};
  $pobmatch=0;
  $realmatch=0;
  $summatch=0;
  
  #calculate whether any or previous godparent/witness id is the same
  #not yet implemented

  &isnotnull($bpar);
  if(($truth==1)&&($bpar eq $mpar))   {$parmatch = $weights{"parish"}};
  &isnotnull($bpob);
  if(($truth==1)&&($bpob eq $mpowit2))    {$pobmatch = $weights{"pob"}};
   
  if($bid2<200000) {$realmatch = $weights{"real"}};

  $summatch = $parmatch+$fnmatch+$lnmatch+$pobmatch+$realmatch;
  
  return($summatch);
  
}

sub matchrecs_godp {

  #names can be matched to marriage or birth so just give the points

  #inits
  $parmatch=0;
  $fnmatch=$weights{"fn"};
  $lnmatch=$weights{"ln"};
  $pobmatch=0;
  $realmatch=0;
  $prevmatch=0;
  $summatch=0;
  
  #calculate whether any or previous godparent/witness id is the same

  foreach $id (@prev_ids) {

      if($id==$bid_gp) {

	  $prevmatch = $weights{"prev"};

      }

  }


  &isnotnull($bpar);
  if(($truth==1)&&($bpar eq $bpar_gp))   {$parmatch = $weights{"parish"}};
  &isnotnull($bpog);
  if(($truth==1)&&($bpog eq $bpob_gp))    {$pobmatch = $weights{"pob"}};

  if($bid_gp<200000) {$realmatch = $weights{"real"}};
  
  $summatch = $parmatch+$fnmatch+$lnmatch+$parmatch+$pobmatch+$realmatch+$prevmatch;
  
  return($summatch);
  
}
