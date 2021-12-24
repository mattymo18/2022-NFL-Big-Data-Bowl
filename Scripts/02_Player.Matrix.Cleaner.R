#load libs
library(tidyverse)
library(Matrix)
#we can start with the play data, we can take out all the punts here
punts <- read.csv("Derived_Data/clean.plays.csv")

player.tracker <- read_csv("Derived_Data/Player.Tracking.csv")

games <- read_csv("Source_Data/games.csv")

#ok now this is simple, I can just join and mutate
player.tracker.temp1 <- left_join(player.tracker, games, by = "gameId")

#now we can mutate and clean up a bit

player.tracker.temp2 <- player.tracker.temp1 %>% 
  mutate(Team = ifelse(Side == "home", homeTeamAbbr, visitorTeamAbbr)) %>% 
  select(newId, nflId, Name, Side, Team)

#great now we can figure out who punted and who returned


#we can do the same join
player.tracker.temp3 <- left_join(player.tracker.temp2, punts, by = "newId")


#and do the same mutate and clean up

player.tracker.temp4 <- player.tracker.temp3 %>% 
  mutate(ReturnTeam = ifelse(Team == possessionTeam, -1, 1)) %>% 
  select(newId, nflId, Name, Side, Team, ReturnTeam)

#now we can build a sparse matrix by finding all the indices for where the nonzero entries are

plays.indx <- tibble(
  Index = 1:length(unique(player.tracker.temp4$newId)), 
  Play = unique(player.tracker.temp4$newId)
)

players.indx <- tibble(
  Index = 1:length(unique(player.tracker.temp4$nflId)), 
  Player = unique(player.tracker.temp4$nflId)
)

#then we can use match to place them into the dataframe

player.tracker.temp4$RowIdx <- match(player.tracker.temp4$newId, plays.indx$Play)
player.tracker.temp4$ColIdx <- match(player.tracker.temp4$nflId, players.indx$Player)

#we need to save player.tracker.temp4 to use later for the nflIds of all the players we need

write.csv(player.tracker.temp4, "Derived_Data/player.index.csv", row.names = F)

#finally we can use the sparseMatrix function and simply specify where the nonzero entries should be 
#and build the matrix

sparse.mat <- sparseMatrix(
  i = player.tracker.temp4$RowIdx, 
  j = player.tracker.temp4$ColIdx, 
  x = player.tracker.temp4$ReturnTeam,
  dims = c(nrow(plays.indx), nrow(players.indx)), 
  dimnames = list(plays.indx$Play, players.indx$Player)
)

#now we don't want to make this a dense matrix and save it, so we'll need to write the matrix in a special way

writeMM(sparse.mat, "Derived_Data/Sparse.Matrix.txt")
