#laod data and libs
library(tidyverse)
library(nflfastR)

#take all the plays first
plays <- read.csv("Source_Data/plays.csv")

#we only need the punts
punts <- plays %>% 
  filter(specialTeamsPlayType == "Punt") %>% 
  # mutate(NetYardsGained = ifelse(specialTeamsResult == "Return", kickReturnYardage, 0)) %>% 
  # #we also dont want any muffs or fumbles, we only want when he catches it or doesn't try to catch it
  # filter(specialTeamsResult == "Return" | specialTeamsResult == "Touchback" | 
  #          specialTeamsResult == "Fair Catch" | specialTeamsResult == "Downed" |
  #          specialTeamsResult == "Out of Bounds") %>% 
  # #found a few odd plays that resulted in the team that punted getting the ball back, remove those
  # filter(!is.na(NetYardsGained)) %>% 
  #we found out they recycled playIds so we make a new ID for combined game and play
  unite(newId, c(gameId, playId), remove = F)

#After further consideration (thanks kubi), we actually do want fumbles. Fumbles are probably the most important game changin
#plays that can happen in special teams. Let's start brainstorming the situations we need and what should happen for our
#three response variables so we can keep our player coding the same (1s: offense, -1: defense)

#we can take a look at these plays completely separately, but we want it in the same script to avoid loading in tracking data
#more than once

# lets lay out of few play scenarios and we'll need to assess them all one by one:
#1. The team successfully punts the ball and the return team muffs it, this either results in the kicking team or return team getting the ball, 
#we'll have to do something different for both 
#2. The team gets the punt blocked, now this one is much much harder since so much can happen here, we need to be careful how we do this one


# 3/6/2022 - ok so game changer, it turns out we can join nflfastR data to this, in that case we can literally just use EPA as our metric of success, that is much much better and we can use every single punt play! I think I'm juts going to comment out what's above, and fix everything like that. I don't want to delete code I already did, but holy cow this is a game changer!

#we'll want to get those play ids in a similar way as above, once we know which plays we need to look at we can continue below

#now we need to iterate through the three seasons to get all the tracking data into one
szs <- seq(2018, 2020)

#blank dataframe to store tracking data
df_tracking <- data.frame()

#iterating through all seasons
for(s in szs) {
  
  #get temporary dataframe and bind one at a time
  df_tracking_temp <- read_csv(paste0("Source_Data/tracking",s,".csv"),
                               col_types = cols())
  
  #storing temporary dataframe in full season dataframe
  df_tracking <- bind_rows(df_tracking_temp, df_tracking)                            
  
}


#now lets get the nflfastr data

#initialize empty dataframe

df_pbp <- data.frame()

for (s in szs) {
  
  #get individual season pbp
  df_pbp_temp <- load_pbp(s) %>% 
    #and select all that we need
    select(old_game_id, play_id, play_type, epa) %>% 
    #and we only want punts
    filter(play_type == "punt") %>% 
    select(-play_type) %>% 
    unite(newId, c(old_game_id, play_id), remove = T)
  
  #store temp pbp in full dataframe
  df_pbp <- bind_rows(df_pbp_temp, df_pbp)
  
}


print("Data Loaded")

#turns out there are a few plays here where the play was not actually downed, it was a fumble, 
#this is really anoying and basically the data is wrong, I can try to fix it later
#I'll remove these plays manually
#lets find them now, these plays do not have tracking data so they should just be comepletely taken out

#now grab just the football

#get the downed plays, we can treat the plays that went out of bounds the exact same as downed punts
# downed.punts <- punts %>% 
#   filter(specialTeamsResult == "Downed" | specialTeamsResult == "Out of Bounds") %>% 
#   select(newId, gameId, playId)
# 
# football <- df_tracking %>% 
#   filter(displayName == "football") %>% 
#   filter(event == "punt_downed" | event == "out_of_bounds") %>% 
#   unite(newId, c(gameId, playId), remove = F) %>% 
# #it turns out there are a few plays where they coded that the ball went out of bounds and that it was downed...this causes
# #some duplicated newIds which is messing everything up. We need to solve this here. I'm going to try to groupby NewId and 
# #since we aren;t sure about the spot we can just take the avg spot and we need playdirection but it remains the same
#   group_by(newId) %>% 
#   summarize(x = mean(x), 
#             playDirection = head(playDirection, 1))
#   
# 
# #now joing with the plays
# 
# downed.football <- left_join(downed.punts, football, by = "newId")
# 
# #ok we found 14Nas, plays that were labeled as downed but actually were fumbles or penalties 
# #resulting in the offense remaining on the field
# 
# #lets get those
# 
# remove.plays <- downed.football %>% 
#   filter(is.na(x)) %>% 
#   select(newId)

#lets go ahead and join the punts with the epa data, this should fix my NA problem

#now we want to join these with the epa from df_pbp, we need to left join since we only have tracking for the pff plays

punts1 <- left_join(punts, df_pbp, by = "newId")

#summary(punts2)

#looks like we have 101 plays with no epa, that's fine lets remove them

punts2 <- punts1 %>% 
  filter(!is.na(epa))


#now take all the punt plays so we can filter the tracking data
punt.playId <- punts2$newId

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

#now remove the plays that have no tracking data

# punts.tracking.clean <- anti_join(punts.tracking, remove.plays, by = "newId")

#finally we can write this smaller dataset to disk so we can load it in faster later on

write.csv(punts.tracking, file = "Derived_Data/Player.Tracking.csv", row.names = F)

print("Tracking Data Cleaning Complete")

#now that we know who is on the field, we want to clean up the plays a bit to include everythin we need

#from here we want to add the rest of the variables of interest: field position and penalty yards

#we already have net yards gained

#lets try to do field position, first we need to deal with the plays when the ball was downed 
#we need to use the tracking data for this becasue we have no information about the ball rolling after
# it hits the ground, so we can use tracking data

#now we can just anti-join it

# downed.football1 <- anti_join(downed.football, remove.plays, by = "newId")
# 
# #the last play for each will be where the ball ended up
# 
# downed.football.final <- downed.football1 %>% 
#   filter(!is.na(x)) %>% 
#   #we need to check the play direction, since we want everything moving left to the right, 
#   #we can switch the plays that go right to left
#   mutate(downed.spot = ifelse(playDirection == "left", 100 - (x - 10), x - 10)) %>% 
#   select(newId, downed.spot)
# 
# #ok great, now we can just add that in
# 
# punts1 <- left_join(anti_join(punts, remove.plays, by = "newId"), downed.football.final, by = "newId")

#ok, there are a lot of NAs for downed.Spot, but that's fine it shouldn't affect anything

#now we can get the rest of this variable easily
#we can do it all in one step

# punts2 <- punts1 %>%
#   #we can use ifesle to make the yardline number in the right form for wehn we do the subtraction
#   #found the cases where teams punted at the 50, yardline side is NA
#   mutate(kickspot.clean = ifelse(possessionTeam == yardlineSide | is.na(yardlineSide), yardlineNumber, 100 - yardlineNumber)) %>%
#   #now we can add in where the ball ended up
#   mutate(returnspot.clean = ifelse(specialTeamsResult == "Touchback", 75,
#                                    ifelse(specialTeamsResult == "Fair Catch", kickspot.clean + kickLength,
#                                           ifelse(specialTeamsResult == "Return", kickspot.clean + kickLength - kickReturnYardage,
#                                                  #this last one needs to be kickspot.clean + kcikLength then + or - how the ball rolled while the team tried
#                                                  #do down it, this is a little tough
#                                                  ifelse(downed.spot - floor(downed.spot) > .5, ceiling(downed.spot), floor(downed.spot)
#                                                  )
#                                           )
#                                    )
#   )
#   ) %>%
#   #finally take the difference, most of these should be negative
#   mutate(field.pos = kickspot.clean - returnspot.clean)

#ok great, the final thing we want to do is get all the penalty yards
#for this we need to make sure we code it as negative if the kicking team does it, 
#that way they will have a positive coeff for contribution towards the penalty
#turns out they already do this for us, that is nice

punts3 <- punts2 %>% 
  mutate(penalty.yards.clean = ifelse(is.na(penaltyCodes), 0, penaltyYards))



#now we can write this to a csv so we don't have to do all this in the EDA, we can do a simple join

write.csv(punts3, "Derived_Data/clean.plays.csv", row.names = F)
