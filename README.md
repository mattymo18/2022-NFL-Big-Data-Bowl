2022 NFL Big Data Bowl
----------------------

## Adjusted Plus-Minus Net Return Yards Gained

## Usage

1. You'll need to install Docker [Here](https://www.docker.com/).

2. Once you've downloaded Docker you'll need to build the container. Think of the container as a virtual enviroment that already has every package you'll need downloaded. To build the environment open a terminal and find the directory this project is in. Then run the following command:

< docker build . -t 2022-NFL-BDB-env
    
This will likely take some time as many packages need to be downloaded

3. After the build is complete, you wil be able to open an rstudio server in a browser inside the container. This Docker container is based on rocker/verse. To run the rstudio server run the following command in the terminal:

< docker run -v `pwd`:/home/rstudio -p 8787:8787 -e PASSWORD=mypass -t 2022-NFL-BDB-env
      
Then in a browser go to *0.0.0.0:8787*. This will bring up an rstudio server to build artifacts, explore data, and continue my work. 

Username: rstudio \
Password: mypass

#### Make
Use Makefile as recipe book for building artifacts found in derived directories. 

##### Example:
In local project directory, to build artifact named Analysis.pdf go to the terminal and use the following command:

< make Analysis.pdf
    
Use artifacts before colon as make targets. Dependencies are listed after colon.

### Abstract

### Introduction

### Preliminary Figures
