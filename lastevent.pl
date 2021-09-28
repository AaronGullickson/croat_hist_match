#####################
# lastevent.pl      #
# Perl Script       #
# Aaron Gullickson  #
# 10/03/2001        #
#####################

##########################################
# This is the last program to be run to create the full dataset.  It will
# search each record for the last observed event.
##########################################

print "Getting last observed event.....";

require generalsubs;

$fulldatafile="output/fulldata.tsv";
$gpfile="output/godparent_dates.tsv";

open (FULL, "<$fulldatafile") || die ("cant open"." $fulldatafile");
open (GP, "<$gpfile") || die ("cant open "."$gpfile");

$replacedgp=0;

%gp_hash=();

foreach $gp (<GP>) {
  chop $gp;
  ($bid,$dates)=split("\t",$gp);
  $gp_hash{$bid}=$dates;
}

%croat=();

foreach $line(<FULL>) {

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
   $remarok7,$remarok8,$remarok9,$remarok10,$remarok11,$remarok12,$remarok13,$remarok14,
   $park1,$park2,$park3,$park4,$park5,$park6,$park7,
   $park8,$park9,$park10,$park11,$park12,$park13,$park14)=split("\t", $line);
  
   #is this the header line?
   if($bid eq "bid") {
     $header="$line\tloe";
     next;
   }
  
  #collect all the dates into an array

  @dates=($bdate, 
   $mdate1, $mdate2, $mdate3, $mdate4, $mdate5, 
   $dobk1, $dobk2, $dobk3, $dobk4, $dobk5, $dobk6, $dobk7, $dobk8, $dobk9, $dobk10, 
   $dobk11, $dobk12, $dobk13, $dobk14, 
   $ddate);

  $lastdate=&max(@dates);
  
  #check godparenting
  @godparenting=split(",",$gp_hash{$bid});

  $lastgpevent=&max(@godparenting);
  if($lastgpevent>$lastdate) {
    $replacedgp++;
    $lastdate=$lastgpevent;
  }

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
		 $park8,$park9,$park10,$park11,$park12,$park13,$park14,$lastdate);
  
  $croat{$bid}=$newline;
  
}

close FULL;
open (FULL,">$fulldatafile") || die ("cant open"." $fulldatafile");

#print the header line 
print(FULL "$header\n");

@bid =keys %croat;
foreach $bid (@bid) {
  $line=$croat{$bid};
  print(FULL "$line\n");
}

print "done\n\n";
