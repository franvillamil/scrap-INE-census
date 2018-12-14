Scraping INE census
===================

Downloading census data from the [INE website](http://www.ine.es/intercensal/).

* `scrap.R` : scraps municipality census data and saves province files for the population and municipality changes in two folders.
* `merge.R` : gets province files and merges them into a file called `INE_census.csv`.

It automatically selects the _de facto_ population data, but if the _de iure_ population is needed, it is just a small change in the code (line 12 in `merge.R`).

In addition, also including:

* `adapt_function.R` corrects and adapts Spanish characters to UTF-8 encoding
* `codelist.csv` a list of province and municipality codes. The list was obtained scrapping the INE website trying all municipality numbers 1-999 and 5001-5999.

**Note:** all four files should be in the same folder.
