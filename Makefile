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

#build genercic artifact called Artifact.csv with 
#dependencies Data_Source1, Data_source2, and Script.R
Artifact.csv:\
 Data_Source1.csv\
 Data_Source2.csv\
 Script.R
	Rscript Script.R