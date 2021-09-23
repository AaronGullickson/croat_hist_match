########################
# m2m.pl               #
# Perl Program         #
# Aaron Gullickson     #
########################

######################################################################

# This perl script will link remarriages to marriages. We do this in 
# rounds - link first marriages to second marriages - then second to third, 
# and so on

require generalsubs;

&get_date_time;

print("m2m Program Starting\n");

#INPUT
$binfile="input/sortedbirths.tsv";
$minfile="input/sortedmars.tsv";
$m2binfile="output/m2b.matches.txt";
$b2minfile="output/b2m.mmatches.txt";
open (B2M,"<$b2minfile") || die ("cant open"." $b2minfile");
open (M2B,"<$m2binfile") || die ("cant open"." $m2binfile");
open (BIRIN, "<$binfile") || die ("cant open"." $binfile");
open (MARIN,"<$minfile") || die ("cant open"." $minfile");

$matchfile="output/m2m.matches.txt";
$detailfile="output/diagnostics/m2m.diag.txt";
open (FINAL,">$matchfile") || die ("cant open "."$matchfile");
open (DETAIL, ">$detailfile") || die ("cant open "."$detailfile");

print(DETAIL "Detail file for m2m.pl\n");
print(DETAIL "Program started on "."$daterun "."$yrrun"." at "."$timerun\n\n");

#Build up the hashes

%m2bhash=();
%mar_hash=();
%birthname=();
%maiden=();
@remar=();
%bdatehash=();
%b2mhash=();

foreach $line (<M2B>) {

  chop $line;

  ($mid,$lastdate,$numkids,$idk1,$idk2,$idk3,$idk4,$idk5,$idk6,$idk7,$idk8,
  $idk9,$idk10,$idk11,$idk12,$idk13,$idk14)=split("\t", $line);

  $m2bhash{$mid}=$line;

}

foreach $line(<BIRIN>) {

  ($bpar,$bid1,$bid2,$uni,$bdate,$byyy,$bmm,$bdd,$bfn,$bsx,$bfnf,$blnf,$bfnm,
  $blnm,$bpob,$bfng,$blng,$bpog) = split("\t",$line);

  $bid2=~s/\s//g;

  $birthname{$bid2}=$blnf;
  $bdatehash{$bid2}=$bdate;

}

#get maiden names of women in marriages

foreach $line(<B2M>) {

    chop $line;

    ($mid, $hbid, $wbid, $hage, $wage, $score)=split("\t", $line);

    $mid=&stripwhite($mid);
    $hbid=&stripwhite($hbid);
    $wbid=&stripwhite($wbid);

    $b2mhash{$mid."f"}=$wbid;
    $b2mhash{$mid."m"}=$hbid;

    if(&isnot_na($wbid)) {

	$maiden{$mid}=$birthname{$wbid};

    }

}

#now go through sortedmars and put marriages into hashes for each
#spouse based on first or remarriage with a hash based on name (allow
#multiple naming schemes?)

%firstmar_notdone=();

foreach $mar (<MARIN>) {

    ($mpar,$mi,$mid,$muni,$myrdate,$myyy,$mmm,$mdd,$mfnh,$mlnh,$mmstath,
     $mageh,$mpoh,$mfnhfa,$mfnw,$mlnw,$mmstatw,$magew,$mpow,$mfnwrel,
     $mtypwrel,$mfnwit1,$mlnwit1,$mpowit1,$mfnwit2,$mlnwit2,$mpowit2,
     $mlnhfull,$mlnwfull,$mlnwit1full,$mlnwit2full,$mnamef,$mnames,
     $mmatchflag)=split("\t", $mar);

    $mid=~s/\s//g;

    #husbands

    if($mmstath ne "u") {

	     $firstmar_notdone_h{$mid}=1;

	     $husbkey=&stripwhite($mfnh).&stripwhite($mlnh)."m";

	     push(@{$mar_hash {$husbkey}}, $mar);

    }

    #wives

    if($mmstatw ne "u") {

	     $firstmar_notdone_w{$mid}=1;

	     $wifekey=&stripwhite($mfnw).&stripwhite($mlnw)."f";

	     push(@{$mar_hash {$wifekey}}, $mar);

	     #wives are more complicated because their last names are more
	     #flexible.  Since these marriages are first marriages, the
	     #$mlnw is likely the women's maiden name.  I also need to give
	     #here a key based on her marriage name, because that may be
	     #how she is identified later.

	     $wifekey_new=&stripwhite($mfnw).&stripwhite($mlnh)."f";

	     push(@{$mar_hash {$wifekey_new}}, $mar);

	     #It might be that $mlnw is not her maiden name.  In that case
	     #I also need to add another key possibility.

	      $maidenname=&stripwhite($maiden{$mid1});

	       if(&isnotnull($maidenname) && $maidenname ne &stripwhite($mlnw)) {

	          $wifekey_maiden=&stripwhite($mfnw).&stripwhite($maidenname)."f";

	          push(@{$mar_hash {$wifekey_maiden}}, $mar);

	       }

    }

    #now throw remarriages onto an array so we can go through them later

    if($mmstath eq "u" | $mmstatw eq "u") {

	     push(@remar, $mar);

    }

}


#now run through remarriages and find links
$cases_w=0;
$multiple_w=0;
$zero_w=0;
$cases_h=0;
$multiple_h=0;
$zero_h=0;
%remar_notdone=();
%remar_hash;


foreach $remar (@remar) {

    @farray=();
    @marray=();

    ($rmpar,$rmi,$rmid,$rmuni,$rmyrdate,$rmyyy,$rmmm,$rmdd,$rmfnh,$rmlnh,
    $rmmstath,$rmageh,$rmpoh,$rmfnhfa,$rmfnw,$rmlnw,$rmmstatw,$rmagew,$rmpow,
    $rmfnwrel,$rmtypwrel,$rmfnwit1,$rmlnwit1,$rmpowit1,$rmfnwit2,$rmlnwit2,
    $rmpowit2,$rmlnhfull,$rmlnwfull,$rmlnwit1full,$rmlnwit2full,$rmnamef,
    $rmnames,$rmmatchflag)=split("\t", $remar);

    $remar_hash{$rmid}=$remar;

    #get the life history for this remarriage

    ($junk,$rlastdate,$rnumkids,$ridk1,$ridk2,$ridk3,$ridk4,$ridk5,$ridk6,
    $ridk7,$ridk8,$ridk9,$ridk10,$ridk11,$ridk12,$ridk13,
    $ridk14)=split("\t",$m2bhash{$rmid});

    #if there are no kids then make $rlastdate early enough that it
    #won't affect matching (I don't want to disqualify older women
    #from getting remarried after childbearing - although maybe I
    #should)

    if(&is_na($rlastdate)) {

	     $rlastdate=0;

    }

    #check if remarriage for each spouse

    #women first

    if($rmmstatw eq "u") {

	     $remar_notdone_w{$rmid}=1;
	     $cases_w++;
	     #make a key

	     $key=&stripwhite($rmfnw).&stripwhite($rmlnw)."f";

	      @farray = @{$mar_hash {$key}};

    }


    if($rmmstath eq "u") {

	     $remar_notdone_h{$rmid}=1;
	     $cases_h++;

	     $key=&stripwhite($rmfnh).&stripwhite($rmlnh)."m";

	     @marray = @{$mar_hash {$key}};

    }

    #now go through the possible links

    $num_links_w=0;

    foreach $link (@farray) {

	($mpar,$mi,$mid,$muni,$myrdate,$myyy,$mmm,$mdd,$mfnh,$mlnh,$mmstath,
	 $mageh,$mpoh,$mfnhfa,$mfnw,$mlnw,$mmstatw,$magew,$mpow,$mfnwrel,
	 $mtypwrel,$mfnwit1,$mlnwit1,$mpowit1,$mfnwit2,$mlnwit2,$mpowit2,
	 $mlnhfull,$mlnwfull,$mlnwit1full,$mlnwit2full,$mnamef,$mnames,
	 $mmatchflag)=split("\t", $link);

	#get the life history for this marriage
	($junk,$lastdate,$numkids,$idk1,$idk2,$idk3,$idk4,$idk5,$idk6,$idk7,$idk8,
  $idk9,$idk10,$idk11,$idk12,$idk13,$idk14)=split("\t",$m2bhash{$mid});

	#if lastdate is missing, then replace it with date of
	#marriage, because this will be used later in the scoring to
	#determine the distance in observed events between marriages

	if(&is_na($lastdate)) {

	    $lastdate=$myrdate;

	}

	#length of reproductive period
	$replength=$rlastdate-$myrdate;

	$mid=&stripwhite($mid);

	#find the approximate birthdate for wife
	$wbdate=$bdatehash{$b2mhash{$mid."f"}};

	#if this is missing, then approximate
	if(&isnull($wbdate)) {

	    #if there is an age on the birth certificate, use this
	    if(&isnotnull($magew)) {

		$wbdate=$myrdate-$magew;

	    } else {

		$wbdate=$myrdate-25;

	    }

	} else {

	    #if $magew is missing, then calculate it (for later use in scoring)

	    if(&isnull($magew)) {

		$magew=$myrdate-$wbdate;

	    }

	}

	$lastkidage=$rlastdate-$wbdate;

	#what conditions disqualify
	#if remarriage is before marriage
	#if remarriage happens before last childbirth from previous marriage

	if($rmyrdate>$myrdate && $rmyrdate>$lastdate && $replength<30
	   && $lastkidage<55) {

	    #then this is a possible link

	    $score=&scoreremarw;

	    if($score>10) {

		$num_links_w++;

		$line="$score\t$mid\t$rmid\t$myrdate\t$wbdate";
		push(@matchesw,$line);
		#print(FINAL "$line\n");

	    }

	}


    }

    #now go through husbands

    $num_links_h=0;

    foreach $link (@marray) {

	($mpar,$mi,$mid,$muni,$myrdate,$myyy,$mmm,$mdd,$mfnh,$mlnh,$mmstath,
	 $mageh,$mpoh,$mfnhfa,$mfnw,$mlnw,$mmstatw,$magew,$mpow,$mfnwrel,
	 $mtypwrel,$mfnwit1,$mlnwit1,$mpowit1,$mfnwit2,$mlnwit2,$mpowit2,
	 $mlnhfull,$mlnwfull,$mlnwit1full,$mlnwit2full,$mnamef,$mnames,
	 $mmatchflag)=split("\t", $link);

	#get the life history for this marriage
	($junk,$lastdate,$numkids,$idk1,$idk2,$idk3,$idk4,$idk5,$idk6,$idk7,$idk8,
   $idk9,$idk10,$idk11,$idk12,$idk13,$idk14)=split("\t",$m2bhash{$mid});

	#if lastdate is missing, then replace it with date of
	#marriage, because this will be used later in the scoring to
	#determine the distance in observed events between marriages

	if(&is_na($lastdate)) {

	    $lastdate=$myrdate;

	}

	#length of reproductive period
	$replength=$rlastdate-$myrdate;

	$mid=&stripwhite($mid);

	#find the approximate birthdate for husband
	$hbdate=$bdatehash{$b2mhash{$mid."m"}};

	#if this is missing, then approximate
	if(&isnull($hbdate)) {

	    #if there is an age on the birth certificate, use this
	    if(&isnotnull($mageh)) {

		$hbdate=$myrdate-$mageh;

	    } else {

		$hbdate=$myrdate-25;

	    }

	} else {

	    #if $mageh is missing, then calculate it (for later use in scoring)

	    if(&isnull($mageh)) {

		$mageh=$myrdate-$hbdate;

	    }

	}

	$lastkidage=$rlastdate-$hbdate;

	#what conditions disqualify
	#if remarriage is before marriage
	#if remarriage happens before last childbirth from previous marriage

	if($rmyrdate>$myrdate && $rmyrdate>$lastdate && $replength<40
	   && $lastkidage<65) {

	    #then this is a possible link

	    $score=&scoreremarh;

	    if($score>10) {

		$num_links_h++;

		$line="$score\t$mid\t$rmid\t$myrdate\t$hbdate";
		push(@matchesh,$line);

	    }

	}


    }

    #record cases with more than one possible link

    if($rmmstatw eq "u") {

	if($num_links_w>1) {

	    $multiple_w++;

	}

	if($num_links_w==0) {

	    $zero_w++;

	}

    }

    if($rmmstath eq "u") {

	if($num_links_h>1) {

	    $multiple_h++;

	}

	if($num_links_h==0) {

	    $zero_h++;

	}

    }

}

#now sort and do final linking of second marriages

@matchesw = sort {$b<=>$a} @matchesw;
@matchesh = sort {$b<=>$a} @matchesh;

$linked_w=0;
%prevmar_hash=();
%dateinfo=();

foreach $match (@matchesw) {

    ($score,$mid,$rmid,$myrdate,$bdate)=split("\t",$match);

    if($firstmar_notdone_w{$mid} && $remar_notdone_w{$rmid}) {

	$newline=join("\t", $mid, "w", $rmid, $score, "1");

	print(FINAL "$newline\n");

	$firstmar_notdone_w{$mid}=0;
	$remar_notdone_w{$rmid}=0;

	$linked_w++;

	#put the important date info into a hash keyed by the
	#remarriage so this information is easily accessible when
	#looking at just the remarriage.

	$dateinfo{$rmid."f"}=join("\t",$myrdate,$bdate);

	#for later links this remarriage now becomes a "first" marriage
	$firstmar_notdone_w{$rmid}=1;

	#now if I linked this remarriage then it becomes a candidate
	#as a link for another remarriage later.  So I need to grab
	#this remarriage and put it in a hash keyed by name

	$rmar=$remar_hash{$rmid};

	($rmpar,$rmi,$rmid,$rmuni,$rmyrdate,$rmyyy,$rmmm,$rmdd,$rmfnh,$rmlnh,
  $rmmstath,$rmageh,$rmpoh,$rmfnhfa,$rmfnw,$rmlnw,$rmmstatw,$rmagew,$rmpow,
  $rmfnwrel,$rmtypwrel,$rmfnwit1,$rmlnwit1,$rmpowit1,$rmfnwit2,$rmlnwit2,
  $rmpowit2,$rmlnhfull,$rmlnwfull,$rmlnwit1full,$rmlnwit2full,$rmnamef,
  $rmnames,$rmmatchflag)=split("\t", $rmar);

	$wifekey=&stripwhite($rmfnw).&stripwhite($rmlnw)."f";

	push(@{$prevmar_hash {$wifekey}}, $rmar);

	#wives are more complicated because their last names are more
	#flexible.  Since these marriages are first marriages, the
	#$mlnw is likely the women's maiden name.  I also need to give
	#here a key based on her marriage name, because that may be
	#how she is identified later.

	if($rmlnw ne $rmlnh) {

	    $wifekey_new=&stripwhite($rmfnw).&stripwhite($rmlnh)."f";

	    push(@{$prevmar_hash {$wifekey_new}}, $rmar);

	}

	#It might be that $mlnw is not her maiden name.  In that case
	#I also need to add another key possibility.

	$maidenname=&stripwhite($maiden{$rmid1});

	if(&isnotnull($maidenname) && $maidenname ne &stripwhite($rmlnw)) {

	    $wifekey_maiden=&stripwhite($rmfnw).&stripwhite($maidenname)."f";

	    push(@{$prevmar_hash {$wifekey_maiden}}, $rmar);

	}


    }

}

$linked_h=0;

foreach $match (@matchesh) {

    ($score,$mid,$rmid,$myrdate,$bdate)=split("\t",$match);

    if($firstmar_notdone_h{$mid} && $remar_notdone_h{$rmid}) {

	$newline=join("\t", $mid, "h", $rmid, $score, "1");

	print(FINAL "$newline\n");

	$firstmar_notdone_h{$mid}=0;
	$remar_notdone_h{$rmid}=0;

	$linked_h++;
	#put the important date info into a hash keyed by the
	#remarriage so this information is easily accessible when
	#looking at just the remarriage.

	$dateinfo{$rmid."m"}=join("\t",$myrdate,$bdate);

	#for later links this remarriage now becomes a "first" marriage
	$firstmar_notdone_h{$rmid}=1;

	#now if I linked this remarriage then it becomes a candidate
	#as a link for another remarriage later.  So I need to grab
	#this remarriage and put it in a hash keyed by name

	$rmar=$remar_hash{$rmid};

	($rmpar,$rmi,$rmid,$rmuni,$rmyrdate,$rmyyy,$rmmm,$rmdd,$rmfnh,$rmlnh,
  $rmmstath,$rmageh,$rmpoh,$rmfnhfa,$rmfnw,$rmlnw,$rmmstatw,$rmagew,$rmpow,
  $rmfnwrel,$rmtypwrel,$rmfnwit1,$rmlnwit1,$rmpowit1,$rmfnwit2,$rmlnwit2,
  $rmpowit2,$rmlnhfull,$rmlnwfull,$rmlnwit1full,$rmlnwit2full,$rmnamef,
  $rmnames,$rmmatchflag)=split("\t", $rmar);

	$husbkey=&stripwhite($rmfnh).&stripwhite($rmlnh)."m";

	push(@{$prevmar_hash {$husbkey}}, $rmar);

    }

}


# OK, that does the first linking from marriage to remarriage, now I need to
# link remarriages to subsequent remarriages, This needs to be done up to five
# times.

@links_w=();

for($i=2;$i<5;$i++) {

    @remarw= keys %remar_notdone_w;
    @matchesw=();
    @remarh= keys %remar_notdone_h;
    @matchesh=();

    foreach $remarw (@remarw) {

	if($remar_notdone_w{$remarw}) {

	    #then this needs to be linked

	    @farray=();

	    ($rmpar,$rmi,$rmid,$rmuni,$rmyrdate,$rmyyy,$rmmm,$rmdd,$rmfnh,$rmlnh,
      $rmmstath,$rmageh,$rmpoh,$rmfnhfa,$rmfnw,$rmlnw,$rmmstatw,$rmagew,$rmpow,
      $rmfnwrel,$rmtypwrel,$rmfnwit1,$rmlnwit1,$rmpowit1,$rmfnwit2,$rmlnwit2,
      $rmpowit2,$rmlnhfull,$rmlnwfull,$rmlnwit1full,$rmlnwit2full,$rmnamef,
      $rmnames,$rmmatchflag)=split("\t", $remar_hash{$remarw});


	    #get the life history for this remarriage

	    ($junk,$rlastdate,$rnumkids,$ridk1,$ridk2,$ridk3,$ridk4,$ridk5,$ridk6,
       $ridk7,$ridk8,$ridk9,$ridk10,$ridk11,$ridk12,$ridk13,
       $ridk14)=split("\t",$m2bhash{$rmid});

	    #if there are no kids then make $rlastdate early enough that it
	    #won't affect matching (I don't want to disqualify older women
	    #from getting remarried after childbearing - although maybe I
	    #should)

	    if(&is_na($rlastdate)) {

		$rlastdate=0;

	    }

	    #check if remarriage for each spouse

	    #women first

	    if($rmmstatw eq "u") {

		#make a key

		$key=&stripwhite($rmfnw).&stripwhite($rmlnw)."f";

		@farray = @{$prevmar_hash {$key}};

	    }

	    foreach $link (@farray) {

		($mpar,$mi,$mid,$muni,$myrdate,$myyy,$mmm,$mdd,$mfnh,$mlnh,$mmstath,
		 $mageh,$mpoh,$mfnhfa,$mfnw,$mlnw,$mmstatw,$magew,$mpow,$mfnwrel,
		 $mtypwrel,$mfnwit1,$mlnwit1,$mpowit1,$mfnwit2,$mlnwit2,$mpowit2,
		 $mlnhfull,$mlnwfull,$mlnwit1full,$mlnwit2full,$mnamef,$mnames,
		 $mmatchflag)=split("\t", $link);

		#get the life history for this marriage
		($junk,$lastdate,$numkids,$idk1,$idk2,$idk3,$idk4,$idk5,$idk6,$idk7,$idk8,
    $idk9,$idk10,$idk11,$idk12,$idk13,$idk14)=split("\t",$m2bhash{$mid});

		#if lastdate is missing, then replace it with date of
		#marriage, because this will be used later in the scoring to
		#determine the distance in observed events between marriages

		if(&is_na($lastdate)) {

		    $lastdate=$myrdate;

		}


		($firstmyrdate,$wbdate)=split("\t",$dateinfo{$mid."f"});

		$replength=$lastdate-$firstmyrdate;

		if(&isnull($magew)) {

		    $magew=$myrdate-$wbdate;

		}

		$lastkidage=$rlastdate-$wbdate;

		#what conditions disqualify
		#if remarriage is before marriage
		#if remarriage happens before last childbirth from previous marriage

		if($rmyrdate>$myrdate && $rmyrdate>$lastdate && $replength<30
		   && $lastkidage<55) {

		    #then this is a possible link

		    $score=&scoreremarw;

		    if($score>10) {

			$line="$score\t$mid\t$rmid\t$myrdate\t$wbdate";
			push(@matchesw,$line);

		    }

		}

	    }

	}

    }

    #do the same thing for men here

    foreach $remarh (@remarh) {

	     if($remar_notdone_h{$remarh}) {

	        #then this needs to be linked

	         @marray=();

	          ($rmpar,$rmi,$rmid,$rmuni,$rmyrdate,$rmyyy,$rmmm,$rmdd,$rmfnh,
            $rmlnh,$rmmstath,$rmageh,$rmpoh,$rmfnhfa,$rmfnw,$rmlnw,$rmmstatw,
            $rmagew,$rmpow,$rmfnwrel,$rmtypwrel,$rmfnwit1,$rmlnwit1,$rmpowit1,
            $rmfnwit2,$rmlnwit2,$rmpowit2,$rmlnhfull,$rmlnwfull,$rmlnwit1full,
            $rmlnwit2full,$rmnamef,$rmnames,
            $rmmatchflag)=split("\t", $remar_hash{$remarh});


	           #get the life history for this remarriage

	          ($junk,$rlastdate,$rnumkids,$ridk1,$ridk2,$ridk3,$ridk4,$ridk5,
            $ridk6,$ridk7,$ridk8,$ridk9,$ridk10,$ridk11,$ridk12,$ridk13,
            $ridk14)=split("\t",$m2bhash{$rmid});

	          #if there are no kids then make $rlastdate early enough that it
	          #won't affect matching (I don't want to disqualify older women
	          #from getting remarried after childbearing - although maybe I
	          #should)

	          if(&is_na($rlastdate)) {

		            $rlastdate=0;

	          }

	          if($rmmstath eq "u") {

		            #make a key

		              $key=&stripwhite($rmfnh).&stripwhite($rmlnh)."m";

		                @marray = @{$prevmar_hash {$key}};

	          }

	           foreach $link (@marray) {

		             ($mpar,$mi,$mid,$muni,$myrdate,$myyy,$mmm,$mdd,$mfnh,$mlnh,
                 $mmstath,$mageh,$mpoh,$mfnhfa,$mfnw,$mlnw,$mmstatw,$magew,
                 $mpow,$mfnwrel,$mtypwrel,$mfnwit1,$mlnwit1,$mpowit1,$mfnwit2,
                 $mlnwit2,$mpowit2,$mlnhfull,$mlnwfull,$mlnwit1full,
                 $mlnwit2full,$mnamef,$mnames,$mmatchflag)=split("\t", $link);

		             #get the life history for this marriage
		             ($junk,$lastdate,$numkids,$idk1,$idk2,$idk3,$idk4,$idk5,$idk6,
                 $idk7,$idk8,$idk9,$idk10,$idk11,$idk12,$idk13,
                 $idk14)=split("\t",$m2bhash{$mid});

		             #if lastdate is missing, then replace it with date of
		             #marriage, because this will be used later in the scoring to
		             #determine the distance in observed events between marriages

		             if(&is_na($lastdate)) {

		                 $lastdate=$myrdate;

		             }

		             ($firstmyrdate,$hbdate)=split("\t",$dateinfo{$mid."m"});

		             $replength=$lastdate-$firstmyrdate;

		             if(&isnull($mageh)) {

		                 $mageh=$myrdate-$hbdate;

		             }

		             $lastkidage=$rlastdate-$hbdate;

		             #what conditions disqualify
		             #if remarriage is before marriage
		             #if remarriage happens before last childbirth from previous marriage

		            if($rmyrdate>$myrdate && $rmyrdate>$lastdate && 
                $replength<40 && $lastkidage<65) {

		                #then this is a possible link

		                  $score=&scoreremarh;

		                    if($score>10) {

			                       $line="$score\t$mid\t$rmid\t$myrdate\t$hbdate";
			                       push(@matchesh,$line);

		                    }

		            }

	         }

	      }

    }


    #now put these links into final matches

    @matchesw = sort {$b<=>$a} @matchesw;
    @matchesh = sort {$b<=>$a} @matchesh;
    %prevmar_hash=();
    $linked_w2=0;
    $linked_h2=0;

    foreach $match (@matchesw) {

	($score,$mid,$rmid,$myrdate,$bdate)=split("\t",$match);

	if($firstmar_notdone_w{$mid} && $remar_notdone_w{$rmid}) {

	    $newline=join("\t", $mid, "w", $rmid, $score, $i);

	    print(FINAL "$newline\n");

	    $firstmar_notdone_w{$mid}=0;
	    $remar_notdone_w{$rmid}=0;

	    $linked_w2++;

	    #put the important date info into a hash keyed by the
	    #remarriage so this information is easily accessible when
	    #looking at just the remarriage.

	    $dateinfo{$rmid."f"}=join("\t",$myrdate,$bdate);

	    #for later links this remarriage now becomes a "first" marriage
	    $firstmar_notdone_w{$rmid}=1;

	    #now if I linked this remarriage then it becomes a candidate
	    #as a link for another remarriage later.  So I need to grab
	    #this remarriage and put it in a hash keyed by name

	    $rmar=$remar_hash{$rmid};

	    ($rmpar,$rmi,$rmid,$rmuni,$rmyrdate,$rmyyy,$rmmm,$rmdd,$rmfnh,$rmlnh,
      $rmmstath,$rmageh,$rmpoh,$rmfnhfa,$rmfnw,$rmlnw,$rmmstatw,$rmagew,$rmpow,
      $rmfnwrel,$rmtypwrel,$rmfnwit1,$rmlnwit1,$rmpowit1,$rmfnwit2,$rmlnwit2,
      $rmpowit2,$rmlnhfull,$rmlnwfull,$rmlnwit1full,$rmlnwit2full,$rmnamef,
      $rmnames,$rmmatchflag)=split("\t", $rmar);

	    $wifekey=&stripwhite($rmfnw).&stripwhite($rmlnw)."f";

	    push(@{$prevmar_hash {$wifekey}}, $rmar);

	    #wives are more complicated because their last names are more
	    #flexible.  Since these marriages are first marriages, the
	    #$mlnw is likely the women's maiden name.  I also need to give
	    #here a key based on her marriage name, because that may be
	    #how she is identified later.

	    if($rmlnw ne $rmlnh) {

		$wifekey_new=&stripwhite($rmfnw).&stripwhite($rmlnh)."f";

		push(@{$prevmar_hash {$wifekey_new}}, $rmar);

	    }

	    #It might be that $mlnw is not her maiden name.  In that case
	    #I also need to add another key possibility.

	    $maidenname=&stripwhite($maiden{$rmid1});

	    if(&isnotnull($maidenname) && $maidenname ne &stripwhite($rmlnw)) {

		$wifekey_maiden=&stripwhite($rmfnw).&stripwhite($maidenname)."f";

		push(@{$prevmar_hash {$wifekey_maiden}}, $rmar);

	    }


	}

    }

    foreach $match (@matchesh) {

	($score,$mid,$rmid,$myrdate,$bdate)=split("\t",$match);

	if($firstmar_notdone_h{$mid} && $remar_notdone_h{$rmid}) {

	    $newline=join("\t", $mid, "h", $rmid, $score, $i);

	    print(FINAL "$newline\n");

	    $firstmar_notdone_h{$mid}=0;
	    $remar_notdone_h{$rmid}=0;

	    $linked_h2++;
	    #put the important date info into a hash keyed by the
	    #remarriage so this information is easily accessible when
	    #looking at just the remarriage.

	    $dateinfo{$rmid."m"}=join("\t",$myrdate,$bdate);

	    #for later links this remarriage now becomes a "first" marriage
	    $firstmar_notdone_h{$rmid}=1;

	    #now if I linked this remarriage then it becomes a candidate
	    #as a link for another remarriage later.  So I need to grab
	    #this remarriage and put it in a hash keyed by name

	    $rmar=$remar_hash{$rmid};

	    ($rmpar,$rmi,$rmid,$rmuni,$rmyrdate,$rmyyy,$rmmm,$rmdd,$rmfnh,$rmlnh,
      $rmmstath,$rmageh,$rmpoh,$rmfnhfa,$rmfnw,$rmlnw,$rmmstatw,$rmagew,$rmpow,
      $rmfnwrel,$rmtypwrel,$rmfnwit1,$rmlnwit1,$rmpowit1,$rmfnwit2,$rmlnwit2,
      $rmpowit2,$rmlnhfull,$rmlnwfull,$rmlnwit1full,$rmlnwit2full,$rmnamef,
      $rmnames,$rmmatchflag)=split("\t", $rmar);

	    $husbkey=&stripwhite($mfnh).&stripwhite($mlnh)."m";

	    push(@{$prevmar_hash {$husbkey}}, $rmar);

	}

    }

    push(@links_w,$linked_w2);
    push(@links_h,$linked_h2);

}

($linked_w2,$linked_w3,$linked_w4)=@links_w;
($linked_h2,$linked_h3,$linked_h4)=@links_h;

print(DETAIL "There were $cases_w remarriages for women.  $zero_w cases had no links.  $multiple_w cases had more than one link.\n\n$linked_w final links made. $linked_w2 final links made for 3rd marriages. $linked_w3 final links for 4th marriages.  $linked_w4 final links for 5th marriages.\n\n");
print(DETAIL "There were $cases_h remarriages for men.  $zero_h cases had no links.  $multiple_h cases had more than one link.\n\n$linked_h final  links made. $linked_h2 final links made for 3rd marriages. $linked_h3 final links for 4th marriages.  $linked_h4 final links for 5th marriages.\n");

sub scoreremarw {

    #things we might score on
    #- age at remarriage
    #- distance between last event of marriage and remarriage
    #- plausibility of length of reproductive period
    #- parish and place of last event in marriage and remarriage
    #- witnesses
    #- observed death of prior spouse

    #find time between last event and new marriage

    $distance=$rmyrdate-$lastdate;

    if($distance<5) {

	$dist_sc=20;

    } else {

	if($distance<25) {

	    $dist_sc=20-($distance-5);

	} else {

	    $sc=0;
	    return $sc;

	}

    }

    #same parish
    if($rmpar eq $mpar) {

	$par_sc=10;

    } else {

	$par_sc=0;

    }

    #same village - greater pref for first husband's village than own village

    if($rmpow eq $mpoh) {

	$pom_sc=10;

    } else {

	if($rmpow eq $mpow) {

	    $pom_sc=5;

	} else {

	    $pom_sc=0;

	}

    }

    #deal with age matching if the first and second marriage both have
    #an age for the wife then see if they are consistent.  If there
    #are no ages given, then still give some points.  Otherwise,
    #better records will get too much preference.

    if(&isnotnull($magew) && &isnotnull($rmagew)) {

	$agediff=$rmagew-$magew;

	#time difference
	$timediff=$rmyrdate-$myrdate;

	if($agediff<0) {

	    $sc=0;
	    return $sc;

	}

	$diff=&abs($agediff-$timediff);

	if($diff>10) {

	    $sc=0;
	    return $sc;

	} else {

	    $age_sc=10-$diff;

	}

    } else {

	$age_sc=5;

    }

    $sc=$dist_sc+$par_sc+$pom_sc+$age_sc;
    return $sc;

}


sub scoreremarh {

    #things we might score on
    #age at remarriage
    #distance between last event of marriage and remarriage
    #plausibility of length of reproductive period
    #parish and place of last event in marriage and remarriage
    #witnesses
    #observed death of prior spouse

    #find time between last event and new marriage

    $distance=$rmyrdate-$lastdate;

    if($distance<5) {

	$dist_sc=20;

    } else {

	if($distance<25) {

	    $dist_sc=20-($distance-5);

	} else {

	    $sc=0;
	    return $sc;

	}

    }

    #same parish
    if($rmpar eq $mpar) {

	$par_sc=10;

    } else {

	$par_sc=0;

    }

    #same village

    if($rmpoh eq $mpoh) {

	$pom_sc=10;

    } else {

	$pom_sc=0;

    }

    #deal with age matching if the first and second marriage both have
    #an age for the wife then see if they are consistent.  If there
    #are no ages given, then still give some points.  Otherwise,
    #better records will get too much preference.

    if(&isnotnull($mageh) && &isnotnull($rmageh)) {

	$agediff=$rmageh-$mageh;

	#time difference
	$timediff=$rmyrdate-$myrdate;

	if($agediff<0) {

	    $sc=0;
	    return $sc;

	}

	$diff=&abs($agediff-$timediff);

	if($diff>10) {

	    $sc=0;
	    return $sc;

	} else {

	    $age_sc=10-$diff;

	}

    } else {


	#if there is a date of birth for the husband, then I can use this instead,
	#but how do I keep track of non-imputed cases?

	$age_sc=5;

    }

    $sc=$dist_sc+$par_sc+$pom_sc+$age_sc;
    return $sc;

}
