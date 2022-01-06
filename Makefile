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
 Scripts/03_Sparse.Mat.Validation.R
	Rscript Scripts/03_Sparse.Mat.Validation.R
	
################################################

#builds final report	
Analysis.pdf:\
 Analysis.Rmd
	R -e "rmarkdown::render('Analysis.Rmd')"
	
#################################################

#builds data bowl submission
BDB_Submission.html:\
 Regression_Plots/05_Contribution_Boxplot.png\
 Derived_Data/top20.csv\
 BDB_Submission.Rmd
	R -e "rmarkdown::render('BDB_Submission.Rmd')"
	
################################################# Cleaning

#build initial cleaned tracking data, this will show who is on the field for each play

Derived_Data/clean.plays.csv\
Derived_Data/Player.Tracking.csv:\
 Source_Data/plays.csv\
 Source_Data/tracking2018.csv\
 Source_Data/tracking2019.csv\
 Source_data/tracking2020.csv\
 Scripts/01_Tracking.Cleaner.R
	Rscript Scripts/01_Tracking.Cleaner.R
	
#build sparse matrix of players in each play and player index with nflIds

Derived_Data/player.index.csv\
Derived_Data/Sparse.Matrix.txt:\
 Derived_Data/clean.plays.csv\
 Derived_Data/Player.Tracking.csv\
 Source_Data/games.csv\
 Scripts/02_Player.Matrix.Cleaner.R
	Rscript Scripts/02_Player.Matrix.Cleaner.R
	
################################################# EDA

EDA_Plots/08_Player_Avg_Pop_Avg.png\
EDA_Plots/07_player_prop_played_table.png\
EDA_Plots/06_Response_Scatterplot_FP_PY.png\
EDA_Plots/05_Response_Scatterplot_NYG_PY.png\
EDA_Plots/04_Response_Scatterplot_NYG_FP.png\
EDA_Plots/03_Response_Boxplots.png\
EDA_Plots/02_Sparse_Mat_Vis.png\
EDA_Plots/01_Response_Histograms.png:\
 Derived_Data/Sparse.Matrix.txt\
 Derived_Data/clean.plays.csv\
 Derived_Data/player.index.csv\
 Scripts/04_EDA.R
	Rscript Scripts/04_EDA.R
	
################################################# Regression Field Position
	
Regression_Plots/05_Contribution_Boxplot.png\
Derived_Data/top20.csv\
Regression_Plots/04_Bot20.FP.Ridge.Table.png\
Regression_Plots/03_Top20.FP.Ridge.Table.png\
Regression_Plots/02_Top20.FP.Table.png\
Regression_Plots/01_Top20.FP.Table.SnapPrblm.png:\
 Derived_Data/Sparse.Matrix.txt\
 Derived_Data/clean.plays.csv\
 Derived_Data/player.index.csv\
 Scripts/05_Field.Pos.Regression.R
	Rscript Scripts/05_Field.Pos.Regression.R