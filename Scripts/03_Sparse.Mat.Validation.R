#In this script we will back test our sparse data matrix of players on the field during plays

#we will ensure that all rows add up to 0
#we will ensure that there are 22 non-zero values in each row
#we will test random plays to ensure the correct plaers are coded

#first laod the data and the relavant libraries
library(tidyverse)
library(Matrix)
set.seed(18)

Sparse.df <- readMM("Derived_Data/Sparse.Matrix.txt")
player.indx <- read_csv("Derived_Data/player.index.csv")

Sparse.tib <- as_tibble(as.matrix(Sparse.df))

#check that all rows add to 0
print("check that all rows add to 0")
all(rowSums(Sparse.tib) == 0)

#check to make sure there are 22 non-zero values in each row
print("check to make sure there are 22 non-zero values in each row")
all(rowSums(abs(Sparse.tib)) == 22)

#Random play check

Sparse.tib$playId <- unique(player.indx$newId)

colnames(Sparse.tib) <- c(unique(player.indx$nflId), "playId")

#lets choose 500 random plays and run a loop to make sure the correct players are there
x <- as.integer(runif(500, 1, nrow(Sparse.tib)))

#set up vector for results
y <- vector(length = 500)

for (i in 1:length(x)) {
#get test row
test.row <- Sparse.tib[x[i], ]

#get players that should be nonzero
truth.player.set <- player.indx %>% 
  filter(newId == test.row$playId) %>% 
  select(nflId)

#find columns of test row that are nonzero
test.row.cols <- test.row[, which(test.row!=0)]

#build testing vector that will yield logical for each play, true if all players in sparse.df are correctly on the field
y[i] = all(sort(as.numeric(unlist(truth.player.set))) == sort(as.numeric(names(test.row.cols[, -23]))))

}

print("finally, randomly check 500 plays to ensure correct players are on the field")
all(y)
