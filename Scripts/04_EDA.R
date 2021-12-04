#EDA

#lets load my library and the sparse data frame, we'll need the play data frame as well

library(tidyverse)
library(Matrix)

Sparse.Df <- readMM("Derived_Data/Sparse.Matrix.txt")

punts <- read_csv("Derived_Data/clean.plays.csv")

player.index <- read_csv("Derived_Data/player.index.csv")

# and we can find out punts again easily using the same code as in the cleaning scripts

#first lets attach the unique newIds to the Sparse.Df as it's own column

#we need to convert the sparse matrix into a large data frame

Sparse.tib <- as.data.frame(as.matrix(Sparse.Df))

#now we can figure out which column corresponds to which player with the player.index

col.names <- player.index %>%
    arrange(ColIdx) %>%
    select(nflId, ColIdx) %>%
    distinct(nflId, ColIdx) %>%
    select(nflId)

names(Sparse.tib) <- as.character(unlist(col.names))

#now we just put in all the variables we need

Sparse.tib.named <- Sparse.tib %>% 
  mutate(newId = unique(punts$newId)) %>% 
  mutate(NYG = punts$NetYardsGained) %>% 
  mutate(Field.Pos = punts$field.pos) %>% 
  mutate(Pen.Yrds = punts$penalty.yards.clean) %>% 
  select(newId, NYG, Field.Pos, Pen.Yrds, everything())

#fond some NAS in NYG and Field.Pos, need to fix this
#turns out the issue is becasue some of the plays labeled downed were actually fumbles, we can remove these manually