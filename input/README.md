This directory contains the raw data collected across parishes on baptisms (births), marriages, and burials (deaths). The `original` subdirectory contains the original files with untokenized names by parish. 

The perl scripts depend on `sortedbirths.tsv`, `sortedmars.tsv`, and `sorteddeaths.tsv` which combine the records for births, marriages, and deaths across all parishes after tokenization of names. These files are text files in tab-separated values format.

In addition, `combined_data_handlinked.tsv` contains an earlier iteration of the linkage procedure that involved some handlinkage. The links from marriages to deaths are pulled from this file for the current linkage procedure.
