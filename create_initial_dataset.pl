####################
# combinedata.pl   #
# Perl Program     #
# Aaron Gullickson #
# 11/17/00         #
####################

##############################################################################
# This program will put together complete datasets based upon the results from 
# the matching programs (b2d, b2m, m2b, m2m).  It will create two datasets. 
# One dataset will be a dataset of all marriages and contain information on
# these marriages.  The second will be an individual dataset which will have
# pointers to birth id, parents id, marriage ids, and death id.  Then I will
# create a dataset that merges these two to create an individual dataset with 
# a full life history.
#
# The structure of the program is as follows:
#
# SECTION 1 
# In this section, I will create hashes from all the input files in order to
# retrieve data easily
#
# SECTION 2
#
# Build the marriage dataset, starting from M2B.  Marriage IDs will be as
# follows.
# 2-23320 - real marriage
# 30000+  - unobserved marriage reconstructed from kinsets
#
# SECTION 3
#
# Build individual data, starting from Sorted Births.  Birth IDs will be as
# follows.
# 2-112200 - real birth
# 200000-399999 - unobserved birth - imputed from missing spouse
# 400000+ - unobserved birth imputed from reconstructed marriage
#
# SECTION 4
#
# Combine marriage and individual data sets.
#
###############################################################################

###################
# INPUT/OUTPUT

require generalsubs;

&get_date_time;

print("Loading files.....");

$binfile="input/sortedbirths.tsv";
$minfile="input/sortedmars.tsv";
$dinfile="input/sorteddeaths.tsv";
$b2dinfile="output/b2d.matches.tsv";
$b2minfile="output/b2m.mmatches.tsv";
$m2binfile="output/m2b.matches.tsv";
$m2minfile="output/m2m.matches.tsv";
#$mardatafile="output/croatmar.txt";
#$inddatafile="output/croatind.txt";
$fulldatafile="output/fulldata.tsv";
$detailfile="output/diagnostics/combine.diag.txt";
open (BIRIN,"<$binfile") || die ("cant open"." $binfile");
open (MARIN,"<$minfile") || die ("cant open"." $minfile");
open (DTHIN,"<$dinfile") || die ("cant open"." $dinfile");
open (B2D,"<$b2dinfile") || die ("cant open"." $b2dinfile");
open (B2M,"<$b2minfile") || die ("cant open"." $b2minfile");
open (M2B, "<$m2binfile") || die ("cant open $m2binfile");
open (M2M, "<$m2minfile") || die ("cant open $m2minfile");
#open (MAR, ">$mardatafile") || die ("cant open $mardatafile");
#open (IND, ">$inddatafile") || die ("cant open $inddatafile");
open (DATA, ">$fulldatafile") || die ("cant open $fulldatafile");
open (DETAIL, ">$detailfile") || die ("cant open $detailfile");

print(DETAIL "Detail file for create_initial_dataset.pl\n");
print(DETAIL "Program started on "."$daterun "."$yrrun"." at "."$timerun\n\n"); 

print("Done\n");

################
# SECTION 1 - In this section, I want to build hashes out of all
# six of my input files.

#I am having problems with leading white space in the keys.  At some point I may want to
#go through and change the ids in sortedbirths, sortedmars, and sorteddeaths.

&get_date_time;
print("Beginning Section 1: Building Hashes\n");
print(DETAIL "Section 1 started at $timerun\n");

%birth_hash=();
%mar_hash=();
%mardate_hash=();
%death_hash=();
%b2d_hash=();
%b2mbyb_hash=();
%b2mbym_hash=();
%m2b_hash=();
%remar_hash=();
%mother_hash=();
%father_hash=();
%isremar_hash=();
%birthage_hash=();

print("\tBuilding birth hash.....");

foreach $line(<BIRIN>) {

  chop $line;

  ($bpar,$bid1,$bid2,$uni,$bdate,$byyy,$bmm,$bdd,$bfn,$bsx,$bfnf,$blnf,$bfnm,
  $blnm,$bpob,$bfng,$blng,$bpog) = split("\t",$line);

  $bid2=&stripwhite($bid2);
  
  $birth_hash{$bid2} = $line;

  #also need just the birthdate information

  $birthdate_hash{$bid2} = $bdate;
  
}

print("Done\n");

print("\tBuilding marriage hash.....");

foreach $line(<MARIN>) {

  chop $line;

  ($mpar,$mi,$mid,$muni,$myrdate,$myyy,$mmm,$mdd,$mfnh,$mlnh,$mmstath,
   $mageh,$mpoh,$mfnhfa,$mfnw,$mlnw,$mmstatw,$magew,$mpow,$mfnwrel,
   $mtypwrel,$mfnwit1,$mlnwit1,$mpowit1,$mfnwit2,$mlnwit2,$mpowit2,
   $mlnhfull,$mlnwfull,$mlnwit1full,$mlnwit2full,$mnamef,$mnames,
   $mmatchflag)=split("\t", $line);
  
  $mid=&stripwhite($mid);

  $mar_hash {$mid} = $line;
  $mardate_hash{$mid}=$myrdate;

  if(&isnotnull($magew)) {

    $birthage_hash{$mid."f"}=$myrdate-$magew;

  }
  
  if(&isnotnull($mageh)) {

    $birthage_hash{$mid."m"}=$myrdate-$mageh;

  }
  
}

print("Done\n");

print("\tBuilding death hash.....");

foreach $line(<DTHIN>) {

  chop $line;
  
  ($dpar,$did1,$did2,$duni,$ddate,$dyyy,$dmm,$ddd,$dfn,$dsx,$dln,$dagey,$dagem,
  $daged,$fnr,$dtpr,$dpob,$dpor,$dpbur,$dmst,$lndu,$dfnf,
  $dfnh)=split("\t", $line);

  $did2=&stripwhite($did2);
  
  $death_hash {$did2} = $line;
  
}

print("Done\n");

print("\tBuilding b2d hash.....");

foreach $line(<B2D>) {

  chop $line;

  ($bid, $did, $score, $age, $ddate)=split("\t", $line);
    
  $b2d_hash {&stripwhite($bid)} = &stripwhite($did);

}

print("Done\n");

print("\tBuilding b2m hashes.....");

foreach $line(<B2M>) {

  chop $line;
  
  ($mid, $hbid, $wbid, $hage, $wage, $score)=split("\t", $line);
  
  $mid=&stripwhite($mid);
  $hbid=&stripwhite($hbid);
  $wbid=&stripwhite($wbid);

  $b2mbyb_hash{$hbid}=$mid;
  $b2mbyb_hash{$wbid}=$mid;
   
  $b2mbym_hash{$mid."m"} = $hbid;
  $b2mbym_hash{$mid."f"} = $wbid;
  
}

print("Done\n");

print("\tBuilding m2m hash.....");

foreach $line(<M2M>) {

  chop $line;
  
  ($mid,$spouse,$remarid,$score)=split("\t", $line);

  $mid=&stripwhite($mid);
  $remarid=&stripwhite($remarid);
  $spouse=&stripwhite($spouse);

  $spouse=~s/h/m/g;
  $spouse=~s/w/f/g;

  $remar_hash{$mid.$spouse} = $remarid;
  $isremar_hash{$remarid.$spouse}=1;

}

print("Done\n");

close (BIRIN);
close (MARIN);
close (DTHIN);
close (B2D);
close (B2M);
close (M2M);

&get_date_time;
print(DETAIL "Section 1 Complete at $timerun\n\n");
print("Section 1 Complete\n");


#######################################################
# SECTION 2

&get_date_time;
print(DETAIL "Section 2 started at $timerun\n");
print("Beginning Section 2: Building marriage data set\n");

#print out dimension names

#print(MAR "mid\thbid\twbid\tmyrdate\tidk1\tidk2\tidk3\tidk4\tidk5\tidk6\tidk7\tidk8\tidk9\tidk10\tidk11\tidk12\tidk13\tidk14\tdobk1\tdobk2\tdobk3\tdobk4\tdobk5\tdobk6\tdobk7\tdobk8\tdobk9\tdobk10\tdobk11\tdobk12\tdobk13\tdobk14\twifefirstmar\thusbfirstmar\n");

#loop through m2b so I can catch the imputed marriages

$missid=200001;
$imputeid=400001;
%mardata_hash=();

$missm_count=0;
$missf_count=0;
$imputem_count=0;
$imputef_count=0;

foreach $line (<M2B>) {

  chop $line;

  ($mid,$lastdate,$numkids,$idk1,$idk2,$idk3,$idk4,$idk5,$idk6,$idk7,$idk8,
  $idk9,$idk10,$idk11,$idk12,$idk13,$idk14)=split("\t", $line);

  @kids=($idk1,$idk2,$idk3,$idk4,$idk5,$idk6,$idk7,$idk8,$idk9,$idk10,$idk11,
         $idk12,$idk13,$idk14);

  $mid=&stripwhite($mid);

  $mar_info=$mar_hash{$mid};

  ($mpar,$mi,$marid,$muni,$myrdate,$myyy,$mmm,$mdd,$mfnh,$mlnh,$mmstath,
   $mageh,$mpoh,$mfnhfa,$mfnw,$mlnw,$mmstatw,$magew,$mpow,$mfnwrel,
   $mtypwrel,$mfnwit1,$mlnwit1,$mpowit1,$mfnwit2,$mlnwit2,$mpowit2,
   $mlnhfull,$mlnwfull,$mlnwit1full,$mlnwit2full,$mnamef,$mnames,
   $mmatchflag)=split("\t", $mar_info);

  #find out if it is a remarriage

  if($mmstatw eq "u") {
    $wiferemar=1;
  } else {
    $wiferemar=0;
  }

  if($mmstath eq "u" || $mmstath eq "y" || $mmstath eq "r") {
    $husbremar=1;
  } else {
    $husbremar=0;
  }

  #now get the spouse info

  $hbid=$b2mbym_hash{$mid."m"};
  $wbid=$b2mbym_hash{$mid."f"};

  #if either or both spouses are missing, then replace with new id

  if(&is_na($hbid)) {

    $hbid=$missid;

    $missid++;

    $missm_count++;

  } elsif (&isnull($hbid)) {

    $hbid=$imputeid;
    
    $imputeid++;

    $imputem_count++;

  }

  if(&is_na($wbid)) {

    $wbid=$missid;

    $missid++;

    $missf_count++;

  } elsif (&isnull($wbid)) {

    $wbid=$imputeid;
    
    $imputeid++;
    
    $imputef_count++;

  }

  #now get birthdates for these kids.

  $dobk1=$birthdate_hash{&stripwhite($idk1)};
  $dobk2=$birthdate_hash{&stripwhite($idk2)};
  $dobk3=$birthdate_hash{&stripwhite($idk3)};
  $dobk4=$birthdate_hash{&stripwhite($idk4)};
  $dobk5=$birthdate_hash{&stripwhite($idk5)};
  $dobk6=$birthdate_hash{&stripwhite($idk6)};
  $dobk7=$birthdate_hash{&stripwhite($idk7)};
  $dobk8=$birthdate_hash{&stripwhite($idk8)};
  $dobk9=$birthdate_hash{&stripwhite($idk9)};
  $dobk10=$birthdate_hash{&stripwhite($idk10)};
  $dobk11=$birthdate_hash{&stripwhite($idk11)};
  $dobk12=$birthdate_hash{&stripwhite($idk12)};
  $dobk13=$birthdate_hash{&stripwhite($idk13)};
  $dobk14=$birthdate_hash{&stripwhite($idk14)};
  
  

  $newline=join("\t",&na($mid),&na($hbid),&na($wbid),&na($myrdate),
		&na($idk1),&na($idk2),&na($idk3),&na($idk4),&na($idk5),&na($idk6),
		&na($idk7),&na($idk8),&na($idk9),&na($idk10),&na($idk11),&na($idk12),
		&na($idk13),&na($idk14),
		&na($dobk1),&na($dobk2),&na($dobk3),&na($dobk4),&na($dobk5),&na($dobk6),
		&na($dobk7),&na($dobk8),&na($dobk9),&na($dobk10),&na($dobk11),&na($dobk12),
    &na($dobk13),&na($dobk14),
		$wiferemar, $husbremar) ;

  #print and send to hash with marriage ID

  #print(MAR "$newline\n");

  $mardata_hash{$mid}=$newline;

  #do the hash stuff for later
  foreach $kid(@kids) {

    $mother_hash{$kid}=$wbid;
    $father_hash{$kid}=$hbid;

  }

}

close(M2B);

&get_date_time;
print(DETAIL "Section 2 complete at $timerun\n\n");
print("Section 2 Complete\n");

################################################
# SECTION 3 - reconstruct individuals

&get_date_time;
print(DETAIL "Section 3 started at $timerun\n");
print("Beginning Section 3: Building individual dataset\n");

%inddata_hash=();
%husbfound_hash=();
%wifefound_hash=();

#write out dimension names

#print(IND "bid\tbdate\tsex\tmotherid\tfatherid\tmid1\tmid2\tmid3\tmid4\tmid5\tmdate1\tmdate2\tmdate3\tmdate4\tmdate5\tdid\tddate\n");

@keys=keys %birth_hash;

foreach $key(@keys) {

  $birth= $birth_hash{$key};

  #get birth info

  ($bpar,$bid1,$bid2,$uni,$bdate,$byyy,$bmm,$bdd,$bfn,$bsx,$bfnf,$blnf,$bfnm,
  $blnm,$bpob,$bfng,$blng,$bpog) = split("\t",$birth);

  $bid=&stripwhite($bid2);
  $bsx=&stripwhite($bsx);

  #get marriage info

  #find the first marriage link

  $marlink=$b2mbyb_hash{$bid};

  if($bsx eq "f") {

    $wifefound_hash{$marlink}=$bid;

  }


  if($bsx eq "m") {

    $husbfound_hash{$marlink}=$bid;

  }

  #need to integrate remarriage info here
  
  #get remarriages

  @marriages=();
  @mardate=();

  push(@marriages, $marlink);
  push(@mardate, $mardate_hash{$marlink});

  $was_married=&isnotnull($marlink);

  $prevmid=$marlink;

  $num_mar=0;

  while($was_married) {

    $num_mar++;

    $remarid=$remar_hash{$prevmid.$bsx};
    
    if($remarid) {

      push(@marriages, $remarid);

      push(@mardate, $mardate_hash{$remarid});

      
      if($bsx eq "f") {
	
	$wifefound_hash{$remarid}=$bid;
	
      }
      
      
      if($bsx eq "m") {
	
	$husbfound_hash{$remarid}=$bid;
	
      }
      
      
      $prevmid=$remarid;

    } else {

      $was_married=0;

    }

  }

  ($mid1, $mid2, $mid3, $mid4, $mid5)=@marriages;
  ($mdate1, $mdate2, $mdate3, $mdate4, $mdate5)=@mardate;

  #get death info

  $deathlink=$b2d_hash{$bid};
  
  $death=$death_hash{$deathlink};

  ($dpar,$did1,$did2,$duni,$ddate,$dyyy,$dmm,$ddd,$dfn,$dsx,$dln,$dagey,$dagem,
  $daged,$fnr,$dtpr,$dpob,$dpor,$dpbur,$dmst,$lndu,$dfnf,
  $dfnh)=split("\t", $death);

  #now find parent link

  $motherid=$mother_hash{$bid};
  $fatherid=$father_hash{$bid};

  #Ok now put it all together

  $newline=join("\t", &na($bid), &na($bdate), &na($bsx), &na($motherid),
  &na($fatherid), &na($mid1), &na($mid2), &na($mid3), &na($mid4), &na($mid5),
  &na($mdate1), &na($mdate2), &na($mdate3), &na($mdate4), &na($mdate5),
  &na($did2), &na($ddate));

  #replace missing with nas

  $inddata_hash{$bid}=$newline;
  
  #print(IND "$newline\n");

}


#now we need to integrate information from marriage hash where individuals
#birth is missing - also need to connect remarriages to these first marriages

print"linking unlinked marriages\n";

@keys = keys %mardata_hash;

$imputem_ind=0;
$imputef_ind=0;

foreach $key(@keys) {

  $marriage=$mardata_hash{$key};

  ($mid,$hbid,$wbid,$myrdate,$idk1,$idk2,$idk3,$idk4,$idk5,$idk6,
   $idk7,$idk8,$idk9,$idk10,$idk11,$idk12,$idk13,$idk14,
   $dobk1, $dobk2, $dobk3, $dobk4, $dobk5, $dobk6, $dobk7, $dobk8, 
   $dobk9, $dobk10, $dobk11, $dobk12, $dobk13, $dobk14, $wiferemar,
   $husbremar)=split("\t", $marriage);

   if($mid==5) {
     $bob=1;
   }

  if($hbid>200000 && &isnull($husbfound_hash{$key}) && &isnull($isremar_hash{$key."m"})) {

    $imputem_ind++;

    #find remarriages

    @marriages=();
    @mardate=();

    push(@marriages, $mid);
    push(@mardate, $mardate_hash{$mid});
    
    $was_married=&isnotnull($marriage);
    
    $prevmid=$mid;
    
    while($was_married) {
      
      $remarid=$remar_hash{$prevmid."m"};
      
      if($remarid) {

	$prevmid=$remarid;
	
	push(@marriages, $remarid);
	
	push(@mardate, $mardate_hash{$remarid});
	
	$husbfound_hash{$remarid}=$bid;
	      
      } else {

	$was_married=0;

      }

    }
   
    ($mid1, $mid2, $mid3, $mid4, $mid5)=@marriages;
    ($mdate1, $mdate2, $mdate3, $mdate4, $mdate5)=@mardate;

    if(&isnotnull($birthage_hash{$mid1."m"})) {

      $bdate=$birthage_hash{$mid1."m"};

    } else {

      $bdate="NA";

    }

    $newline=join("\t", $hbid, $bdate, "m", "NA", "NA", 
		  $mid1, $mid2, $mid3, $mid4, $mid5,
		  $mdate1, $mdate2, $mdate3, $mdate4, $mdate5,	       
		  "NA", "NA");

    $inddata_hash{$hbid}=$newline;

  }

  if($wbid>200000 && &isnull($wifefound_hash{$key}) && &isnull($isremar_hash{$key."f"})) {

    $imputef_ind++;

    @marriages=();
    @mardate=();

    push(@marriages, $mid);
    push(@mardate, $mardate_hash{$mid});
    
    $was_married=&isnotnull($marriage);
    
    $prevmid=$mid;
    
    while($was_married) {
      
      $remarid=$remar_hash{$prevmid."f"};
      
      if($remarid) {

	$prevmid=$remarid;
	
	push(@marriages, $remarid);
	
	push(@mardate, $mardate_hash{$remarid});
		  
	$wifefound_hash{$remarid}=$bid;
	  
      } else {

	$was_married=0;

      }
      
    }

    ($mid1, $mid2, $mid3, $mid4, $mid5)=@marriages;
    ($mdate1, $mdate2, $mdate3, $mdate4, $mdate5)=@mardate;
     
    if(&isnotnull($birthage_hash{$mid1."f"})) {

      $bdate=$birthage_hash{$mid1."f"};

    } else {

      $bdate="NA";

    }
    
    $newline=join("\t", $wbid, $bdate, "f", "NA", "NA", 
		  $mid1, $mid2, $mid3, $mid4, $mid5,
		  $mdate1, $mdate2, $mdate3, $mdate4, $mdate5,	       
		  "NA", "NA");
    
    $inddata_hash{$wbid}=$newline;

  }

}

&get_date_time;
print(DETAIL "Section 3 complete at $timerun\n\n");
print("Section 3 Complete\n");

#######################################################
# SECTION 4 

#I will build two kinds of full datasets: one with marriages
#as the base like combodat, and one with individuals as the 
#base.

&get_date_time;
print(DETAIL "Section 4 started at $timerun\n");
print("Beginning Section 4: Combining datasets in individual format\n");

#print out column headings

print(DATA "bid\tbdate\tsex\tmotherid\tfatherid\tmid1\tmid2\tmid3\tmid4\tmid5\tsid1\tsid2\tsid3\tsid4\tsid5\tmdate1\tmdate2\tmdate3\tmdate4\tmdate5\tdid\tddate\tidk1\tidk2\tidk3\tidk4\tidk5\tidk6\tidk7\tidk8\tidk9\tidk10\tidk11\tidk12\tidk13\tidk14\tdobk1\tdobk2\tdobk3\tdobk4\tdobk5\tdobk6\tdobk7\tdobk8\tdobk9\tdobk10\tdobk11\tdobk12\tdobk13\tdobk14\tsidk1\tsidk2\tsidk3\tsidk4\tsidk5\tsidk6\tsidk7\tsidk8\tsidk9\tsidk10\tsidk11\tsidk12\tsidk13\tsidk14\tremark1\tremark2\tremark3\tremark4\tremark5\tremark6\tremark7\tremark8\tremark9\tremark10\tremark11\tremark12\tremark13\tremark14\tremarok1\tremarok2\tremarok3\tremarok4\tremarok5\tremarok6\tremarok7\tremarok8\tremarok9\tremarok10\tremarok11\tremarok12\tremarok13\tremarok14\tpark1\tpark2\tpark3\tpark4\tpark5\tpark6\tpark7\tpark8\tpark9\tpark10\tpark11\tpark12\tpark13\tpark14\n");

#start with individual one

@keys = keys %inddata_hash;

foreach $key(@keys) {

  $line=$inddata_hash{$key};

  ($bid, $bdate, $sex, $motherid, $fatherid, 
   $mid1, $mid2, $mid3, $mid4,$mid5, 
   $mdate1, $mdate2, $mdate3, $mdate4,$mdate5,
   $did, $ddate)=split("\t", $line);

  @marriages=($mid1, $mid2, $mid3, $mid4, $mid5);


  @allkids=();
  @alldob=();
  @allparish=();
  @otherid=();
  @remar=();
  @remarother=();
  @sid=();

  $total_kids=0;
  $len_kids=0;

  foreach $marriage(@marriages) {
    
    $mar_info=$mardata_hash{$marriage};
    
    ($mid,$hbid,$wbid,$myrdate,$idk1,$idk2,$idk3,$idk4,$idk5,$idk6,
     $idk7,$idk8,$idk9,$idk10,$idk11,$idk12,$idk13,$idk14,
     $dobk1, $dobk2, $dobk3, $dobk4, $dobk5, $dobk6, $dobk7, $dobk8, 
     $dobk9, $dobk10, $dobk11, $dobk12, $dobk13, $dobk14,
     $wiferemar, $husbremar)=split("\t", $mar_info);
    
    #determine who the spouse is
      
    $_=$sex;
    
    /f/i && do{$spouse=$hbid; $remar=$wiferemar; $remarother=$husbremar;};
    /m/i && do{$spouse=$wbid; $remar=$husbremar; $remarother=$wiferemar;};

    #get spouse id

    push(@sid, $spouse);
    
    #now add kids from this marriage to total kids and date of birth for person
    
    @kids=($idk1,$idk2,$idk3,$idk4,$idk5,$idk6,
	   $idk7,$idk8,$idk9,$idk10,$idk11,$idk12,$idk13,$idk14);
    
    $len = scalar @kids;
    
    $total_kids=$total_kids+$len_kids;
    $len_kids=0;
    
    $more_kids=1;
    
    while($more_kids & $len_kids<$len) {
      
      $_ = shift @kids;
      
      if(/NA/i) {
	
	$more_kids=0;
	
      } else {
	
	push(@allkids, $_);
	
	#get information about this birth
	#in case I want to add things at a later date

	$birth=$birth_hash{$_};
	
	($kbpar,$kbid1,$kbid2,$uni,$kbdate,$kbyyy, $kbmm,$kbdd,$kbfn,$kbsx,$kbfnf,
	 $kblnf,$kbfnm,$kblnm,$kbpob,$kbfng,$kblng,$kbpog) = split("\t",$birth);
	
	push(@alldob, $kbdate);
	
	push(@allparish, $kbpar);

	$len_kids++;
	  
      }
      
    }
    
    $i=1;
    
    while($i<=$len_kids) {
      
      push(@otherid, $spouse);
      push(@remar, $remar);
      push(@remarother, $remarother);
      
      $i++;
      
    }
    
  }
  
  ($idk1,$idk2,$idk3,$idk4,$idk5,$idk6,
   $idk7,$idk8,$idk9,$idk10,$idk11,$idk12,$idk13,$idk14)=@allkids;
  
  ($dobk1, $dobk2, $dobk3, $dobk4, $dobk5, $dobk6, $dobk7, $dobk8, 
   $dobk9, $dobk10, $dobk11, $dobk12, $dobk13, $dobk14)=@alldob;
  
  ($sidk1,$sidk2,$sidk3,$sidk4,$sidk5,$sidk6,
   $sidk7,$sidk8,$sidk9,$sidk10,$sidk11,$sidk12,$sidk13,$sidk14)=@otherid;

  ($remark1,$remark2,$remark3,$remark4,$remark5,$remark6,
   $remark7,$remark8,$remark9,$remark10,$remark11,$remark12,$remark13,
   $remark14)=@remar;

  ($remarok1,$remarok2,$remarok3,$remarok4,$remarok5,$remarok6,
   $remarok7,$remarok8,$remarok9,$remarok10,$remarok11,$remarok12,$remarok13,
   $remarok14)=@remarother;
  
  ($park1,$park2,$park3,$park4,$park5,$park6,$park7,
   $park8,$park9,$park10,$park11,$park12,$park13,$park14)=@allparish;

  ($sid1, $sid2, $sid3, $sid4, $sid5)=@sid;

  $newline=join("\t", &na($bid), &na($bdate), &na($sex), 
		&na($motherid), &na($fatherid), 
		&na($mid1), &na($mid2), &na($mid3), &na($mid4), &na($mid5),
		&na($sid1), &na($sid2), &na($sid3), &na($sid4), &na($sid5),
		&na($mdate1), &na($mdate2), &na($mdate3), &na($mdate4), &na($mdate5), 
		&na($did), &na($ddate),
		&na($idk1), &na($idk2), &na($idk3), &na($idk4), &na($idk5), &na($idk6),
    &na($idk7), &na($idk8), &na($idk9), &na($idk10), &na($idk11),& na($idk12),
    &na($idk13), &na($idk14),
		&na($dobk1), &na($dobk2), &na($dobk3), &na($dobk4), &na($dobk5),
    &na($dobk6), &na($dobk7), &na($dobk8), &na($dobk9), &na($dobk10),
    &na($dobk11), &na($dobk12), &na($dobk13), &na($dobk14), 
		&na($sidk1),&na($sidk2),&na($sidk3),&na($sidk4),&na($sidk5),&na($sidk6),
		&na($sidk7),&na($sidk8),&na($sidk9),&na($sidk10),&na($sidk11),&na($sidk12),
		&na($sidk13),&na($sidk14),
		&na($remark1), &na($remark2), &na($remark3), &na($remark4), &na($remark5), 
    &na($remark6), &na($remark7), &na($remark8),&na($remark9), &na($remark10),
    &na($remark11), &na($remark12), &na($remark13), &na($remark14), 
    &na($remarok1), &na($remarok2), &na($remarok3), &na($remarok4), 
    &na($remarok5), &na($remarok6), &na($remarok7), &na($remarok8), 
    &na($remarok9), &na($remarok10),&na($remarok11), &na($remarok12), 
    &na($remarok13), &na($remarok14),
		&na($park1), &na($park2), &na($park3), &na($park4), &na($park5), 
    &na($park6), &na($park7), &na($park8), &na($park9), &na($park10), 
    &na($park11), &na($park12), &na($park13), &na($park14));
  
  #put nas where there are missing values

  print(DATA "$newline\n");

}

print(DETAIL "Section 4 complete at $timerun\n\n");
print("Section 4 Complete\n");

#######################################################
# Section 5 - put it into a combodat like file

#######################################################

print(DETAIL "$missm_count men were imputed from missing data in an existing marriage\n");
print(DETAIL "$missf_count men were imputed from missing data in an existing marriage\n");
print(DETAIL "$imputem_count men were imputed from a nonexisting marriage\n");
print(DETAIL "$imputef_count women were imputed from a nonexisting marriage\n\n");

print(DETAIL "$imputem_ind men were imputed in the individual dataset\n");
print(DETAIL "$imputef_ind women were imputed in the individual dataset\n");
