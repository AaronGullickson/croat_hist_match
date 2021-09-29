# The UC Croatia Project

This repository contains original data on baptisms (at birth), marriages, and burials for seven parishes in Central Slavonia (part of Croatia) circa 1700-1900. The repository also includes perl scripts that link these records together to reconstitute individual life histories and kinship relationsips over the entire time period. 

## Usage

This final reconstituted dataset is available as a compressed file in the release section of this repository or directly in `output/fulldata.tsv`. The `codebook` directory also contains a codebook for the full dataset.

The full dataset is a plain test file in tab-separated values format which should be easy to read into any statistical software package. For example, it can be read into R with the command:

```r
library(readr)
fulldata <- read_tsv("fulldata.tsv", guess_max=170000)
```

To read in the data directly from GitHub, use the raw data link to the data:

```r
library(readr)
fulldata <- read_tsv("https://raw.githubusercontent.com/AaronGullickson/croat_hist_match/master/output/fulldata.tsv", 
                     guess_max=170000)
```

## Background

The UC Croatia Project was conceived by E. A. Hammel in the early 1980s with financial support at various points 1983-03 from the American Council of Learned Societies, the Center for Slavic and East European Studies at U. C. Berkeley, the Wenner-Gren Foundation for Anthropological Research, the National Science Foundation, the National Institute of Child Health and Human Development, and logistical support throughout from the Department of Demography at U. C. Berkeley.

The project was initiated in the spirit of comparative social analysis to explore the differences in demographic behavior between otherwise identical peasant populations living under civil vs. military serfdom before and and after emancipation, and between populations of different ethnicity but under the same feudal regime, on the Habsburg-Ottoman frontier c. 1700-1900.  Planning began with conversations between Hammel, Frank Dubinskas (an anthropology doctoral student at Stanford who had worked in the region under Hammel's supervision), and Dr. Olga Supek (then of the Institute for Ethnology and Folklore, Zagreb). In 1983 Hammel began work in archives in Vienna, Zagreb, and Budapest. This work was facilitated by the advice and cooperation of Michael Mitterauer, Rainer Münz, Wolfgang Lutz, Joseph Eimer, Rudolph Andorka, and Tamas Farago in Austria and Hungary. The majority of work unfolded in Zagreb, with the active assistance of the staff of the State Archive of Croatia, particularly Dr. Josip Kolanović (later Director of the Archive) and the encouragment of Vladimir Stipetić, Alica Wertheimer-Baletić, and Jakov Gelo of the Faculty of Economics. Most particularly it was assisted by staff and logistical support from the Institute of Ethnography and Folklore, under the directorship of Dr. Dunja Rihtman-Augustin, especially by Jasna Čapo (who later took her doctorate in Demography at Berkeley).  The basic collection of parish data took a number of years of effort, supervised by Čapo in Zagreb. Initial efforts at family reconstitution were undertaken in Fortran by Ruth Deuel, with assistance from Čapo, later modified by Marcia Feitel. Final efforts at reconstitution, using the Perl language, were begun by Hammel with the advice of Carl Mason about 1996 and improved and finalized by Aaron Gullickson starting about 1998.

## The Original Data

The original data collected from parish records are located in `input/original/` with additional documentation provided in the README there regarding the format of the files. Names from the original files are tokenized to standardize spelling. This tokenization was done not through formal “soundex” transformations but by project personnel conversant in Croatian, German, and Latin, combing through the data.

The `sortedbirths.tsv`, `sorteddeaths.tsv`, and `sortedmars.tsv` are the raw data files that form the basis of the automated reconstruction. These files combine the parish data together using tokenized names and sorted by id numbers.

## The Linking Programs

The perl programs use the raw data to perform linkages, constructing family histories.  In general, they follow a similar pattern.  Hashes are created of the relevant raw data sets using names as the keys.  These are then matched across two kinds of records and scored by various factors (same parish, age match, etc.).  In addition, some matches are rejected completely because they would conflict with previous matches (a woman dying before she gives birth for example). Each of the files are described below in the order they should be run below.

 The `runmatches.sh` bash script will also execute the entire reconstruction from the command line using the following command:
 
 ```bash
 ./runmatches.sh
 ```

### m2b.pl: linking marriages to births

This script looks at birth records and attempts to find the corresponding marriage from which each birth was produced.  It attempts to match at least three of the four names of the spouses in the marriage to the names of the parents of the birth.  It is run first because the matches here are the most reliable given that name combinations of three or four names are seldom repeated.  This scripts also links together children for which a marriage cannot be found but who likely share the same parent into the same kin set.

### b2m.pl: linking births to marriages 

This scripts attempts to match births to their subsequent marriage.  It matches on names and scores individuals on a variety of factors.  In addition, it rejects matches if they occur before and after a certain age and rejects them if they contradict the matches from m2b.pl (although we do allow some "shotgun" weddings if they occur within a reasonably short span before marriage).

### m2m.pl: link remarriages to previous marriages

This original files indicate whether the marriage is a remarriage for a given spouse. This script pulls out those remarriages and attempts to link them to a previous marriage. It allows for up to five remarriages.

### b2d.pl: link births to deaths

This script attempts to match births to their own deaths.  It rejects matches that lead to a death before a marriage or the end of childbearing (or 9 months before the end of childbearing for men). It also uses information from the b2m links to match women by both maiden and married name.

### create_initial_datasets.pl: combining the data

This script takes the matching output from previous four scripts and combines them together to generate individual life histories for all individuals referenced in the raw data. The final dataset uses individuals as the unit of analysis and links each person to their birth, marriage, death, and childbearing records and dates. 

In addition to including individuals with real birth records, this dataset also contains individuals identified only by their marriage record, and individuals who can only be inferred as parents from connected kin sets of births.

Because of a technical issue, this script will not produce the correct id for spouses in a remarriage. The immediately following script will correct those ids.

### correctremar.pl

This script corrects the remarriage ids that are misidentified in the prior script.

### p2d.pl: link person record to death record

This full dataset contains many people who were identified not through a birth record but through a marriage record or as a parent of a kin set. This script attempts to link these individuals to a death record.

### m2d.pl: link marriages to deaths

Linking marriages to deaths in an automated fashion because of a lack of age in most marriage records. However, we do add marriage to death links here that were made by hand linkage in a previous iteration of the linkage procedure.

### g2p.pl: link godparents and witnesses to a person record

Birth and marriage records contain information on godparents and witnesses respectively. This information can be valuable in increasing the last observed event of individuals for whom there is no death record. This script links those godparents and witnesses to a person record from the full dataset.

### lastevent.pl: Add a last event

This script loops through the full data and identifies the last observed event for each person. It also incorporates the information on godparentage and marriage witnesses in deriving a last observed event.


## Output Files

The files in the `output` directory are generated by the perl matching programs. All `.tsv` files are plain text files in tab separated values format. Each of the matching routine produces its own matching file, as wll as a final `fulldata.tsv` that contains the reconstituted life history data. The `diagnostics` subdirectory contains a report for each perl script.
