#############################
# generalsubs.pm            #
# Perl subroutine module    #
# Aaron Gullickson          #
# 1/10/2001                 #
#############################

#####################################
# This program holds general subroutines
# for the matching programs

sub na {

  $_ = shift @_;
  
  if(&isnull($_)) {

    return("NA") 

  } else {

    return($_) 

  }

}

sub stripwhite {
 
  $_ = shift @_;

  s/\s//g;

  return($_);

}

sub get_date_time {
  
  $wholedate=scalar localtime;
  $daterun=substr($wholedate,0,10);
  $timerun=substr($wholedate,11,8);
  $yrrun=substr($wholedate,20,23);
  
  return ($daterun,$yrrun,$timerun);
  
}

###############################
# is character an NA or not

sub isnot_na {

  $_ = shift @_;

  if(/NA/i) {

    return(0);

  } else {

    return(1);

  }

}

sub is_na {

  $_ = shift @_;

  if(/NA/i) {

    return(1);

  } else {

    return(0);

  }

}



sub sum {
    $sum=0;
    foreach $element (@_) {
	$sum = $sum + $element;
    }
    return $sum;
}

###returns max of a vector passed
sub max{
    $max=-10**32;
    foreach $element (@_){
       $max=$element if $element>$max;
    }
    return $max;
}

###returns min of a vector passed
sub min{
    $min=10**32;
    foreach $element (@_){
       $min=$element if $element<$min;
    }
    return $min;
}

sub roundage{
#pick closest rounded age in years
    if(($aam-$lobound)<($upbound-$aam)){
       $roundage=$lobound;
    }
   else{
       $roundage=$upbound;
   }
   return $roundage;
}

#####################
#create a random boolean

sub random {

  $number = rand()/.5;
  
  $number = sprintf("%6d",$number);

  return($number)

}


sub isnotnull{
  
  $what=0;
  $answer=0;
  
  foreach (@_){
    $answer=!($_=~m/^\s*$/);
    $what=$what+$answer;
  }
  
  if($what==scalar(@_)){
    
    $truth=1;
    
  }else{
    
    $truth=0;
  }
  
  return ($truth);
}

sub abs {

    $value = shift @_;

    if($value<0) {

	$value=$value*-1;

    }

    return($value);

}

sub isnull{
  
  $what=0;
  $answer=0;
  
  foreach (@_){
    $answer=!($_=~m/^\s*$/);
    $what=$what+$answer;
  }
  
  if($what==scalar(@_)){
    
    $truth=0;
    
  }else{
    
    $truth=1;
  }
  
  return ($truth);
}

return(1);

#if one return one, else return zero

sub dummy_up{ 

  $_ = shift @_;
  
  if($_==1) {

    return(1);

  } else {
    
    return(0);

  }

}
