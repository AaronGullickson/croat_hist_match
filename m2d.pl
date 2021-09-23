################################
# m2d.pl                       #
# Perl Program                 #
# Aaron Gullickson             #
# 1/8/01                       #
################################

###############################################
# We can't link marriages to deaths very well because there are very few ages
# given at marriage, which means we don't have anything to break ties with.  
# We may be able to solve this problem later but for now we are just going
# to accept the hand links where they don't conflict  with our own. This 
# script just pulls out those hand links and adds them where they do not
# conflict.

print("Starting m2d.pl\n");

require generalsubs;

&get_date_time;

%agerange = (
	     "week"            => 7,
	     "month"           => 7,
	     "year"            => 31,
	     "threeyearstart"  => 31,
	     "threeyearend"    => 183,
	     "tenyear"         => 365,
	     "twentyearstart"  => 365,
	     "twentyyearend"   => 730,
	     "fourtyyear"      => 5*365,
	     "overfourtystart" => 10*365,
	     "overfourtyat80"  => 10*365,
	     );

$handlinkfile="input/combined_data_handlinked.tsv";
$dinfile="input/sorteddeaths.tsv";
$croatdatafile="output/croatdata.txt";
$b2dinfile="output/b2d.matches.txt";
$detailfile="output/diagnostics/m2d.diag.txt";
open (HAND, "<$handlinkfile") || die ("cant open"." $handlinkfile");
open (DTHIN,"<$dinfile") || die ("cant open"." $dinfile");
open (B2D,"<$b2dinfile") || die ("cant open"." $b2dinfile");
open (CROAT, "<$croatdatafile") || die ("cant open"." $croatdatafile");
open (DETAIL, ">$detailfile") || die ("cant open "."$detailfile");

print(DETAIL "Detail file for m2d.temp.pl\n");
print(DETAIL "Program started on "."$daterun "."$yrrun"." at "."$timerun\n\n"); 

############################################################
# SECTION 1: loop through combodat and create an m2d hash

print("Beginning Section 1: Building m2d hash\n");

%b2d_hash=();

foreach $line(<B2D>) {

  chop $line;

  ($bid, $did, $score, $age, $ddate)=split("\t", $line);
    
  if(&isnot_na($did)) {

    $b2d_hash {&stripwhite($did)} = &stripwhite($bid);

  }

}

%m2d_hash=();
%death_hash=();
%ddate_hash=();
%lastdate_hash=();

$hdidexists=0;
$wdidexists=0;
$dagenoimpute=0;

foreach $line(<HAND>) {

  ($marid, $completed, $remhd, $remwd, $dom, $ageh, $agew, $vill, $fnw1, 
   $lnw1, $fnw2, $lnw2, $wfn, $wln, $hfn, $hln, $par, $hdid, $hdod, $haad, 
	 $hpob, $hpor, $hpobur, $wdid, $wdod,  $waad, $wpob, $wpor, $wpobur, $remh,
	 $doremh, $pohremh, $powremh, $remw, $doremw, $pohremw, $powremw, $dom2w,
	 $dom2h, $hbid, $wbid, $hdob, $wdob, $ageh2, $agew2, $hdid2, $wdid2, $hdod2,
	 $wdod2, $remh2, $remw2, $wdob2, $hdob2, $dobk1, $sexk1, $pobk1, $fngk1, 
	 $lngpk1,  $dodk1,  $idk1,  $dod2k1,  $didk1,  $maridk1,  $domk1,
   $dobk2,  $sexk2,  $pobk2,  $fngk2,  $lngpk2,  $dodk2,  $idk2,  $dod2k2, 
	 $didk2,  $maridk2,  $domk2, $dobk3,  $sexk3,  $pobk3,  $fngk3,  $lngpk3, 
	 $dodk3,  $idk3,  $dod2k3,  $didk3,  $maridk3,  $domk3, $dobk4,  $sexk4, 
	 $pobk4,  $fngk4,  $lngpk4,  $dodk4,  $idk4,  $dod2k4,  $didk4,  $maridk4,
	 $domk4, $dobk5,  $sexk5,  $pobk5,  $fngk5,  $lngpk5,  $dodk5,  $idk5, 
	 $dod2k5,  $didk5,  $maridk5,  $domk5, $dobk6,  $sexk6,  $pobk6,  $fngk6, 
	 $lngpk6,  $dodk6,  $idk6,  $dod2k6,  $didk6,  $maridk6,  $domk6,
   $dobk7,  $sexk7,  $pobk7,  $fngk7,  $lngpk7,  $dodk7,  $idk7,  $dod2k7,
	 $didk7,  $maridk7,  $domk7, $dobk8,  $sexk8,  $pobk8,  $fngk8,  $lngpk8, 
	 $dodk8,  $idk8,  $dod2k8, $didk8,  $maridk8,  $domk8, $dobk9,  $sexk9, 
	 $pobk9,  $fngk9,  $lngpk9,  $dodk9,  $idk9,  $dod2k9,  $didk9,  $maridk9,
	 $domk9, $dobk10, $sexk10, $pobk10, $fngk10, $lngpk10, $dodk10, $idk10,
	 $dod2k10, $didk10, $maridk10, $domk10, $dobk11, $sexk11, $pobk11, $fngk11,
	 $lngpk11, $dodk11, $idk11, $dod2k11, $didk11, $maridk11, $domk11, $dobk12,
	 $sexk12, $pobk12, $fngk12, $lngpk12, $dodk12, $idk12, $dod2k12, $didk12,
	 $maridk12, $domk12, $dobk13, $sexk13, $pobk13, $fngk13, $lngpk13, $dodk13,
	 $idk13, $dod2k13, $didk13, $maridk13, $domk13, $dobk14, $sexk14, $pobk14,
	 $fngk14, $lngpk14, $dodk14, $idk14, $dod2k14, $didk14, $maridk14, 
   $domk14)=split("\t", $line);
 

  #get rid of any extra whitespace on the keys

  $marid=~s/\s//g;

  #add to hash if this death id isn't already claimed

  if(&isnull($b2d_hash{$wdid})) {

    $m2d_hash{$marid."f"}=$wdid;

  }

  if(&isnull($b2d_hash{$hdid})) {

    $m2d_hash{$marid."m"}=$hdid;

  }


  $wdidexists = $wdidexists + isnot_na($wdid);
  $hdidexists = $hdidexists + isnot_na($hdid);
  
}

#need a death hash to assign age at birth

foreach $line(<DTHIN>) {

  ($dpar,$did1,$did2,$duni,$ddate,$dyyy,$dmm,$ddd,$dfn,$dsx,$dln,$dagey,$dagem,$daged,
   $fnr,$dtpr,$dpob,$dpor,$dpbur,$dmst,$lndu,$dfnf,$dfnh)=split("\t", $line);

  $did2=~s/\s//g;
  
  $dage=$dagey+($dagem/12)+($daged/365);

  $death_hash {$did2} = $dage;
  
  $ddate_hash {$did2} = $ddate;

}

#read in marriages to get a marriage date because Marcia uses 
#different ones

print("Section 1 Complete\n");

###############################################################################
# SECTION 2: loop through croatdata and add deaths where they are missing

print("Beginning Section 2: Integrating m2d links\n");

$m2df_added = 0;
$m2dm_added = 0;

$m2df_less = 0;
$m2dm_less = 0;

%croat=();

foreach $line(<CROAT>) {
  
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
   $remark1,$remark2,$remark3,$remark4,$remark5,$remark6,$remark7,$remark8,
	 $remark9,$remark10,$remark11,$remark12,$remark13,$remark14,
   $remarok1,$remarok2,$remarok3,$remarok4,$remarok5,$remarok6,$remarok7,
	 $remarok8,$remarok9,$remarok10,$remarok11,$remarok12,$remarok13,$remarok14,
   $park1,$park2,$park3,$park4,$park5,$park6,$park7,
   $park8,$park9,$park10,$park11,$park12,$park13,$park14)=split("\t", $line);
  
  #get the last date of birth in the family

  $dob = join("\t",$dobk1, $dobk2, $dobk3, $dobk4, $dobk5, $dobk6, $dobk7,
	$dobk8, $dobk9, $dobk10, $dobk11, $dobk12, $dobk13, $dobk14);

  $dob=~s/NA//g;
  
  @dob = split("\t", $dob);

  @dob = sort {$b<=>$a} @dob;
  
  $lastdate = @dob[0];

  #check to see if did is missing and they were married

  if(&is_na($did) && &isnot_na($mid1)) {

    #see what the m2d link says

    $mid1=~s/\s//g;
    $sex=~s/\s//g;

    $did=$m2d_hash{$mid1.$sex};

    if(&isnot_na($did)  && &isnotnull($did)) {
      
      if($sex eq "f") {

				$m2df_added++;

      }

      if($sex eq "m") {

				$m2dm_added++;

      }

      $ddate=$ddate_hash{$did};

      #now I need to assign an age at birth based upon the results
      #from the death link

      $did=~s/\s//g;
      
      $dage=$death_hash{$did};

      $bdate_old=$bdate;

      $bdate=$ddate-$dage;

      #figure out a bunch of ages conditional on
      #both dates being there

      if(&isnot_na($bdate_old)) {

				$dage_old=$ddate-$bdate_old;

      } else {

				$dage_old=50;

      }

      if(&isnot_na($dobk1)  && isnot_na($bdate)) {

				$firstbirthage=$dobk1-$bdate;

      } else {

				$firstbirthage=20;

      }

      if(&isnotnull($lastdate)) {

				$lastbirthage=$lastdate-$bdate;

      } else {

				$lastbirthage=20;
 
      }

      #check for various reasons to deny link.  Once again allow 7 days
      #leeway between birth of child and death.

      if($bdate>$mdate1 || ($lastdate-8/365)>$ddate || $dage_old>100 ||
			 $dage_old<0 || $firstbirthage<15 || $lastbirthage>55) {
	
				 $bdate=$bdate_old;
	
				$did="NA";
				$ddate="NA";
	
				$_ = $sex;

				/f/i && $m2df_less++;
				/m/i && $m2dm_less++;

      }

      #if the old birthdate is not missing, then use it but keep link

      if(&isnot_na($bdate_old) && $bid<200000) {

				$dagenoimpute++;

				$bdate=$bdate_old;

      }

    }
    
    
  }

  #now reconstitute line

   $newline=join("\t", $bid, $bdate, $sex, 
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
		 $remark1,$remark2,$remark3,$remark4,$remark5,$remark6,$remark7,$remark8,
		 $remark9,$remark10,$remark11,$remark12,$remark13,$remark14,
		 $remarok1,$remarok2,$remarok3,$remarok4,$remarok5,$remarok6,$remarok7,
		 $remarok8,$remarok9,$remarok10,$remarok11,$remarok12,$remarok13,$remarok14,
		 $park1,$park2,$park3,$park4,$park5,$park6,$park7,
		 $park8,$park9,$park10,$park11,$park12,$park13,$park14);
  
	$croat{$bid}=$newline;
}

#close croatdata and then re-open
close CROAT;
open (CROAT,">$croatdatafile") || die ("cant open"." $croatdatafile");

###print out croat data
@bid =keys %croat;
foreach $bid (@bid) {
  $line=$croat{$bid};
  print(CROAT "$line\n");
}

print("Section 2 Complete\n");
###########################################################################

print(DETAIL "$hdidexists m2d links for men were found in hand-linked data\n");
print(DETAIL "$wdidexists m2d links for men were found in hand-linked data\n\n");

print(DETAIL "$m2df_added m2d links for women were added initially\n");
print(DETAIL "$m2dm_added m2d links for men were added initially\n\n");

print(DETAIL "$m2df_less m2d links for women were rejected\n");
print(DETAIL "$m2dm_less m2d links for men were rejected\n\n");

&get_date_time;

print(DETAIL "Program finished on "."$daterun "."$yrrun"." at "."$timerun\n\n"); 

print("Program Complete\n");
    
    
