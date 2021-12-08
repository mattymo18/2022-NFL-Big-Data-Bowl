2022 NFL Big Data Bowl
----------------------

## Adjusted Plus-Minus Net Return Yards Gained

## Usage

You'll need to install Docker [Here](https://www.docker.com/).

Once you've downloaded Docker you'll need to build the container. Think of the container as a virtual environment that already has every package you'll need downloaded. To build the environment open a terminal and find the directory this project is in. Then run the following command:

     docker build . -t 2022-NFL-BDB-env
    
This will likely take some time as many packages need to be downloaded.

After the build is complete, you wil be able to open an rstudio server in a browser inside the container. This Docker container is based on rocker/verse. To run the rstudio server run the following command in the terminal:

     docker run -v `pwd`:/home/rstudio -p 8787:8787 -e PASSWORD=mypass -t 2022-NFL-BDB-env
      
Then click [Here](http://0.0.0.0:8787/). **Right-Click and Open in New Tab**. This will bring up an rstudio server to build artifacts, explore data, and continue my work. 

Username: rstudio \
Password: mypass

#### Make
Use Makefile as recipe book for building artifacts found in derived directories. 

##### Example:
In the virtual rstudio environment, to build artifact named Analysis.pdf go to the terminal and use the following command:

     make Analysis.pdf
    
Use artifacts before colon as make targets. Dependencies are listed after colon.

### Data

Data can be found [Here](https://www.kaggle.com/c/nfl-big-data-bowl-2022/data). You'll need to unzip the data and place the files directly into the Source_Data directory. 

### Abstract

### Introduction

### Preliminary Figures from EDA

Here are the boxplots for the three response variables. As you can see, there are a lot of 0s in the Net Yards Gained and Penalty Yards variables. Net Yards Gained has lots of 0s due to the touchbacks, downed balls, and fair catches. This leads us to believe a zero-inflate poisson model may be well suited for these two variables. From the field position boxplot, we suspect it may be approximately normally distributed. 

![](EDA_Plots/03_Response_Boxplots.png)

Below we can see that are suspicion about the field position was verified. It seems to follow an approximately normal distribution with a mean around -40. 

![](EDA_Plots/01_Response_Histograms.png)

Now we see Net Yards Gained plotted against Field Position. There is a clear positive trend after we disregard the inflated 0s in net yards gained.

![](EDA_Plots/04_Response_Scatterplot_NYG_FP.png)

We attempt to visualize the sparse matrix of players on the field during each punt. It is quite difficult to see because of the shear volume, but we see the players that have played in all three seasons are at the top, and the number of games played drops off as we move down. 

![](EDA_Plots/02_Sparse_Mat_Vis.png)
