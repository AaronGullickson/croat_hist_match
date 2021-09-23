##This script will correct the parent and spouse pointers that
## are mixed up due to m2m.  It should be run right after
## createdatasets.pl

#read in croat data
#use lib(qw(/home/davis/hdir1/aarong/projects/CROAT/MATCH));
require generalsubs;

$croatdatafile="output/croatdata.txt";
$m2mfile="output/m2m.matches.txt";
open (CROAT,"<$croatdatafile") || die ("cant open"." $croatdatafile");

open (M2M,"<$m2mfile") || die ("cant open"." $m2mfile");

%croat=();
%id2m_hash=();

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
   $remark1,$remark2,$remark3,$remark4,$remark5,$remark6,
   $remark7,$remark8,$remark9,$remark10,$remark11,$remark12,$remark13,$remark14,
   $remarok1,$remarok2,$remarok3,$remarok4,$remarok5,$remarok6,
   $remarok7,$remarok8,$remarok9,$remarok10,$remarok11,$remarok12,$remarok13,
   $remarok14,
   $park1,$park2,$park3,$park4,$park5,$park6,$park7,
   $park8,$park9,$park10,$park11,$park12,$park13,$park14)=split("\t", $line);


  if($bid==219466) {

    $bob=1;

  }

  #get the bids associated with first marriages
  $id2m_hash{"$mid1"."$sex"}=$bid if(&isnot_na($mid1));

  #identify cases that are going to need to be fixed later

  #any children where sidk doesn't match sid1

  if(&isnot_na($idk1)) {

    if($sex eq "m") {

      $kiddad_hash{$idk1}=$bid;
      $kiddad_hash{$idk2}=$bid;
      $kiddad_hash{$idk3}=$bid;
      $kiddad_hash{$idk4}=$bid;
      $kiddad_hash{$idk5}=$bid;
      $kiddad_hash{$idk6}=$bid;
      $kiddad_hash{$idk7}=$bid;
      $kiddad_hash{$idk8}=$bid;
      $kiddad_hash{$idk9}=$bid;
      $kiddad_hash{$idk10}=$bid;
      $kiddad_hash{$idk11}=$bid;
      $kiddad_hash{$idk12}=$bid;
      $kiddad_hash{$idk13}=$bid;
      $kiddad_hash{$idk14}=$bid;
       
    } else {

      $kidmom_hash{$idk1}=$bid;
      $kidmom_hash{$idk2}=$bid;
      $kidmom_hash{$idk3}=$bid;
      $kidmom_hash{$idk4}=$bid;
      $kidmom_hash{$idk5}=$bid;
      $kidmom_hash{$idk6}=$bid;
      $kidmom_hash{$idk7}=$bid;
      $kidmom_hash{$idk8}=$bid;
      $kidmom_hash{$idk9}=$bid;
      $kidmom_hash{$idk10}=$bid;
      $kidmom_hash{$idk11}=$bid;
      $kidmom_hash{$idk12}=$bid;
      $kidmom_hash{$idk13}=$bid;
      $kidmom_hash{$idk14}=$bid;
       
    } 

  }
   
  #some problem with spouse ids here as well - deal with that later

  #put line in a hash for later processing and output
      
  $croat{$bid}=$line;

}

#build a hash that associates remarriages with their birth ids


%m2m_hash=();

foreach $m2m(<M2M>) {

  chomp $m2m;

  ($mar, $sex, $remar, $junk)=split("\t", $m2m);

  $sx="m" if($sex eq "h");
  $sx="f" if($sex eq "w");

  $m2m_hash{"$remar"."$sx"}=$mar;

}

close(CROAT);
open (CROAT,">$croatdatafile") || die ("cant open"." $croatdatafile");

@id = keys %croat;
$dadreplaced=0;
$momreplaced=0;

foreach $id(@id) {

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
   $park8,$park9,$park10,$park11,$park12,$park13,$park14)=split("\t", $croat{$id});

  #pull out the parent ided from earlier

  if($bid==53949) {

    $bob=1;

  }

  ##########################################################################################
  #OK I've got to redo all of the spouse links for remarriages - this is a bit hairy

  #check each sid to make sure it is not a remarriage

  $osex="m" if($sex eq "f");
  $osex="f" if($sex eq "m");

  #######################
  # OK here we go
  if($bid==53024) {
    $bob=1;
  }

  if(&isnot_na($mid1)) {
    ##Marity 1
    $currentmar=();
    $prevmar=$mid1;
    #this script should (hopefully) pick out the earliest marriage
    while(&isnotnull($prevmar)) {
      $currentmar=$prevmar;
      $prevmar=$m2m_hash{"$prevmar"."$osex"};
    }
    #if there was a previous marriage, then find the spouse's bid from that earliest marriage
    if(&isnotnull($currentmar)) {
      $replacement=$id2m_hash{"$currentmar"."$osex"};
      @sidk=($sidk1,$sidk2,$sidk3,$sidk4,$sidk5,$sidk6,$sidk7,$sidk8,$sidk9,$sidk10,
	     $sidk11,$sidk12,$sidk13,$sidk14);
      @newsidk=();
      foreach $sidk(@sidk) {
	
	if($sid1==$sidk) {
	  
	  push(@newsidk,$replacement);
	  
	} else {
	  
	  push(@newsidk,$sidk);
	  
	}
	
      }
      ($sidk1,$sidk2,$sidk3,$sidk4,$sidk5,$sidk6,$sidk7,$sidk8,$sidk9,$sidk10,
       $sidk11,$sidk12,$sidk13,$sidk14)=@newsidk;
      $sid1=$replacement;
      #also need to replace the sidk's that correspond to that marriage - that's a bitch
    }
  }  

  if(&isnot_na($mid2)) {
    #Marity 2
    $currentmar=();
    $prevmar=$mid2;
    #this script should (hopefully) pick out the earliest marriage
    while(&isnotnull($prevmar)) {
      $currentmar=$prevmar;
      $prevmar=$m2m_hash{"$prevmar"."$osex"};
    }
    #if there was a previous marriage, then find the spouse's bid from that earliest marriage
    if(&isnotnull($currentmar)) {
      $replacement=$id2m_hash{"$currentmar"."$osex"};
      @sidk=($sidk1,$sidk2,$sidk3,$sidk4,$sidk5,$sidk6,$sidk7,$sidk8,$sidk9,$sidk10,
	     $sidk11,$sidk12,$sidk13,$sidk14);
      @newsidk=();
      foreach $sidk(@sidk) {
	
	if($sid2==$sidk) {
	  
	  push(@newsidk,$replacement);
	  
	} else {
	  
	  push(@newsidk,$sidk);
	  
	}

      }
      ($sidk1,$sidk2,$sidk3,$sidk4,$sidk5,$sidk6,$sidk7,$sidk8,$sidk9,$sidk10,
       $sidk11,$sidk12,$sidk13,$sidk14)=@newsidk;
      $sid2=$replacement;
      #also need to replace the sidk's that correspond to that marriage - that's a bitch
    }
  }    

  if(&isnot_na($mid3)) {
    #Marity 3
    $currentmar=();
    $prevmar=$mid3;
    #this script should (hopefully) pick out the earliest marriage
    while(&isnotnull($prevmar)) {
      $currentmar=$prevmar;
      $prevmar=$m2m_hash{"$prevmar"."$osex"};
    }
    #if there was a previous marriage, then find the spouse's bid from that earliest marriage
    if(&isnotnull($currentmar)) {
      $replacement=$id2m_hash{"$currentmar"."$osex"};
    @sidk=($sidk1,$sidk2,$sidk3,$sidk4,$sidk5,$sidk6,$sidk7,$sidk8,$sidk9,$sidk10,
	   $sidk11,$sidk12,$sidk13,$sidk14);
      @newsidk=();
      foreach $sidk(@sidk) {
	
	if($sid3==$sidk) {
	  
	  push(@newsidk,$replacement);
	  
	} else {
	  
	  push(@newsidk,$sidk);
	  
	}
	
      }
      ($sidk1,$sidk2,$sidk3,$sidk4,$sidk5,$sidk6,$sidk7,$sidk8,$sidk9,$sidk10,
       $sidk11,$sidk12,$sidk13,$sidk14)=@newsidk;
      $sid3=$replacement;
      #also need to replace the sidk's that correspond to that marriage - that's a bitch
    }
  }    

  if(&isnot_na($mid4)) {
    #Marity 4
    $currentmar=();
    $prevmar=$mid4;
    #this script should (hopefully) pick out the earliest marriage
    while(&isnotnull($prevmar)) {
      $currentmar=$prevmar;
      $prevmar=$m2m_hash{"$prevmar"."$osex"};
    }
    #if there was a previous marriage, then find the spouse's bid from that earliest marriage
    if(&isnotnull($currentmar)) {
      $replacement=$id2m_hash{"$currentmar"."$osex"};
      @sidk=($sidk1,$sidk2,$sidk3,$sidk4,$sidk5,$sidk6,$sidk7,$sidk8,$sidk9,$sidk10,
	     $sidk11,$sidk12,$sidk13,$sidk14);
      @newsidk=();
      foreach $sidk(@sidk) {
	
	if($sid4==$sidk) {
	  
	  push(@newsidk,$replacement);
	  
	} else {
	  
	  push(@newsidk,$sidk);
	  
	}
	
      }
      ($sidk1,$sidk2,$sidk3,$sidk4,$sidk5,$sidk6,$sidk7,$sidk8,$sidk9,$sidk10,
       $sidk11,$sidk12,$sidk13,$sidk14)=@newsidk;
      $sid4=$replacement;
      #also need to replace the sidk's that correspond to that marriage - that's a bitch
    }
  }    

  if(&isnot_na($mid5)) {
    #Marity 5
    $currentmar=();
    $prevmar=$mid5;
    #this script should (hopefully) pick out the earliest marriage
    while(&isnotnull($prevmar)) {
      $currentmar=$prevmar;
      $prevmar=$m2m_hash{"$prevmar"."$osex"};
    }
    #if there was a previous marriage, then find the spouse's bid from that earliest marriage
    if(&isnotnull($currentmar)) {
      $replacement=$id2m_hash{"$currentmar"."$osex"};
      @sidk=($sidk1,$sidk2,$sidk3,$sidk4,$sidk5,$sidk6,$sidk7,$sidk8,$sidk9,$sidk10,
	     $sidk11,$sidk12,$sidk13,$sidk14);
      @newsidk=();
      foreach $sidk(@sidk) {
	
	if($sid5==$sidk) {
	  
	  push(@newsidk,$replacement);
	  
	} else {
	  
	  push(@newsidk,$sidk);
	  
	}
	
      }
      ($sidk1,$sidk2,$sidk3,$sidk4,$sidk5,$sidk6,$sidk7,$sidk8,$sidk9,$sidk10,
       $sidk11,$sidk12,$sidk13,$sidk14)=@newsidk;
      $sid5=$replacement;
      #also need to replace the sidk's that correspond to that marriage - that's a bitch
    }
  }
    
    
  ##########################################################################################

  $momid=$kidmom_hash{$bid};
  $dadid=$kiddad_hash{$bid};

  if($momid!=$motherid) {

    $momreplaced++;
    #go into a few of these to make sure I understand problem
    $motherid=$momid;
    
  }

  if($dadid!=$fatherid) {

    $dadreplaced++;
    $fatherid=$dadid;
    
  }
    
  $newline=join("\t",$bid, $bdate, $sex, 
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
		$park8,$park9,$park10,$park11,$park12,$park13,$park14);

  print(CROAT "$newline\n");

}

print("$dadreplaced father and $momreplaced mother pointers were updated\n");
