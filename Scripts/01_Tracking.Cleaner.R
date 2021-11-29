#laod data and libs
library(tidyverse)

#take all the plays first
plays <- read.csv("Source_Data/plays.csv")

#we only need the punts
punts <- plays %>% 
  filter(specialTeamsPlayType == "Punt") %>% 
  mutate(NetYardsGained = ifelse(specialTeamsResult == "Return", kickReturnYardage, 0)) %>% 
  #we also dont want any muffs or fumbles, we only want when he catches it or doesn't try to catch it
  filter(specialTeamsResult == "Return" | specialTeamsResult == "Touchback" | 
           specialTeamsResult == "Fair Catch" | specialTeamsResult == "Downed") %>% 
  #we found out they recycled playIds so we make a new ID for combined game and play
  unite(newId, c(gameId, playId), remove = F)

#now we need to iterate through the three seasons to get all the tracking data into one
szs <- seq(2018, 2020)

#blank dataframe to store tracking data
df_tracking <- data.frame()

#iterating through all seasons
for(s in szs){
  
  #get temporary dataframe and bind one at a time
  df_tracking_temp <- read_csv(paste0("Source_Data/tracking",s,".csv"),
                               col_types = cols())
  
  #storing temporary dataframe in full season dataframe
  df_tracking <- bind_rows(df_tracking_temp, df_tracking)                            
  
}

print("Data Loaded")

#now take all the punt plays so we can filter the tracking data
punt.playId <- punts$newId

#now we can make the tracking data much smaller and just look at each player that is on the field
punts.tracking <- df_tracking %>% 
  #we need to first combine gameId and playId into our newId
  unite(newId, c(gameId, playId), remove = F) %>% 
  #filter out the right plays
  filter(newId %in% punt.playId) %>% 
  #take out the football, we only care about the players on the field
  filter(displayName != "football") %>% 
  #group by the game, play, and player name so we have 1 row per layer
  group_by(newId, nflId, gameId, playId) %>% 
  #now we want to know who they are and if they are home or away
  summarize(Name = head(displayName, 1), 
            Side = head(team, 1))

#finally we can write this smaller dataset to disk so we can load it in faster later on

write.csv(punts.tracking, file = "Derived_Data/Player.Tracking.csv", row.names = F)

print("Tracking Data Cleaning Complete")