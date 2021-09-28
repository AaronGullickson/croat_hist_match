#!/bin/bash

# This script will run the matching procedure and then package up a 
# compressed file containing the full data and the codebook

./runmatches.sh

# create directory
mkdir croat_linkage

# copy over data
cp output/fulldata.tsv croat_linkage/

# create the codebook
pandoc -o croat_linkage/fulldata_codebook.pdf codebooks/fulldata_codebook.md

# tarball it
tar -czf croat_linkage.tar.gz croat_linkage

# remove directory
rm -R croat_linkage
