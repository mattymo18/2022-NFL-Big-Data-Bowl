#lets load the packages I think I need for right now

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
library(ggrepel)

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

#in this script we are only doing the EPA regression, lets make our dataframe reflect that

Regress.df <- Sparse.tib.named %>% 
  select(-newId, Pen.Yrds)

#outstanding, now we can move on and try our different regressions. We already know the matrix is rank deficient
#so we can go ahead and scratch using a linear model. We need to have a penalty term in there and we don't want
#anyone to have a contribution of 0. so we are going to use ridge regression

#we'll use caret for all this so we can make sure it is all cross validated and we choose a good lambdas

#first we want to partition the data in a nice way
set.seed(18) #great number

train.samps <- Regress.df$EPA %>% 
  createDataPartition(p = .8, list = F)

train <- Regress.df[train.samps, ]
test <- Regress.df[-train.samps, ]

#initialize values of our penalty paramtere
lambda <- 10^seq(-3, 3, length = 50)

#and use caret to build the model

ridge <- train(
  #formula
  EPA ~., 
  #data
  data = train, 
  #using glmnet package
  method = "glmnet", 
  #setting 10 fold cv
  trControl = trainControl("cv", number = 10),
  #we know alpha should be 0 for ridge, and we set the sequence of lambdas here
  tuneGrid = expand.grid(alpha = 0, lambda = lambda)
)

#lets stop here for now...im very hungry and don't want to get too deep in the modeling right now