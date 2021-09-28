#!/bin/bash

# This script will run the entire matching routine in Perl. The matches are 
# output as tab separated text files in the output directory and diagnostic
# reports are written to output/diagnostics. 

# First remove all prior output
rm -r output/*
mkdir output/diagnostics/

# do the initial matching to create full dataset
perl m2b.pl
perl b2m.pl
perl m2m.pl
perl b2d.pl
perl create_initial_dataset.pl

# correct pointers for remarriages
perl correctremar.pl

# link people without birth records to death records
perl p2d.pl

#  add the marriage to death hand links
perl m2d.pl

# match godparents and marriage witnesses to people
perl g2p.pl

# add the last event for the person, including godparentage and marriage
# witness
perl lastevent.pl
