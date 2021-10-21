#Phony target for cleaning repository
.PHONY: clean
#cleans entire repository of derived elements
clean:
	rm derived_data/*.csv

################################################

#builds final report	
Analysis.pdf:\
 Analysis.Rmd
	R -e "rmarkdown::render('Analysis.Rmd')"
	
#################################################

#build initial cleaned tracking data, this will show who is on the field for each play

Derived_Data/Player.Tracking.csv:\
 Source_Data/players.csv\
 Source_Data/tracking2018.csv\
 Source_Data/tracking2019.csv\
 Source_data/tracking2020.csv\
 Tracking.Cleaner.R
	Rscript Tracking.Cleaner.R
	