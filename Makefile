#Phony target for cleaning repository
.PHONY: clean
#cleans entire repository of derived elements
clean:
	rm Derived_Data/*.csv
	rm Derived_Data/*.txt

################################################

#phony target to validate the player Matrix
.PHONY: validate

validate:\
 Derived_Data/Sparse.Matrix.txt\
 Derived_Data/player.index.csv\
 Scripts/Sparse.Mat.Validation.R
	Rscript Scripts/Sparse.Mat.Validation.R
	
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
 Scripts/Tracking.Cleaner.R
	Rscript Scripts/Tracking.Cleaner.R
	
#build sparse matrix of players in each play and player index with nflIds

Derived_Data/player.index.csv\
Derived_Data/Sparse.Matrix.txt:\
 Source_Data/plays.csv\
 Derived_Data/Player.Tracking.csv\
 Source_Data/games.csv\
 Scripts/Player.Matrix.Cleaner.R
	Rscript Scripts/Player.Matrix.Cleaner.R