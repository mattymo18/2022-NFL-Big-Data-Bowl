#load in the data and libs

#for data manipulation
library(tidyverse)
library(Matrix)
#for tables
library(knitr)
library(kableExtra)
#for models
library(caret)
library(glmnet)
#for nice nfl grpahics
library(nflplotR)

#now we want to load in all the relevant data and build to sparse matrix

Sparse.Df <- readMM("Derived_Data/Sparse.Matrix.txt")

punts <- read_csv("Derived_Data/clean.plays.csv")

player.index <- read_csv("Derived_Data/player.index.csv")

#we need to do exactly what we did before in the EDA so we have the nice named data frame

Sparse.tib <- as.data.frame(as.matrix(Sparse.Df))

#now we can figure out which column corresponds to which player with the player.index

col.names <- player.index %>%
  arrange(ColIdx) %>%
  distinct(nflId, ColIdx) %>%
  select(nflId)

names(Sparse.tib) <- as.character(unlist(col.names))

#now we just put in all the variables we need

Sparse.tib.named <- Sparse.tib %>% 
  mutate(newId = punts$newId) %>% 
  mutate(Pen.Yrds = punts$penalty.yards.clean) %>% 
  #here we use negative EPA since EPA is from the possession team perspective and I switched the variable of success 
  #to be from the return team perspective (-1 punters, 1 returners)
  mutate(EPA = -punts$epa) %>% 
  select(newId, EPA, Pen.Yrds, everything())

#we are only dealing witj pen yrds here so lets make a regression dataframe like that

Regress.df <- Sparse.tib.named %>% 
  select(-newId, -EPA)

#so in this case, positive contribution is now bad. Anyone with positive contribution is contributing to penalties

#first thing we need to do is figure out how to do a penalized version of a zero inflate poisson regression

#praying caret can do something like this...it can't. TBH the epa model includes info about penalites so this 
#might not be worth my time at all lol