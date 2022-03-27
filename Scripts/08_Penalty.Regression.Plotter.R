#load data and libs

#for data manipulation
library(tidyverse)

#for nfl plotting
library(nflplotR)

#load coeff data

Coefs <- read.csv("Derived_Data/ordinal.regression.coefs.csv")

#load player data (position and team and snaps)
player.index <- read_csv("Derived_Data/player.index.csv")

#first thing I need to set up is the snap counts for players and teams

player.snap.count <- player.index %>% 
  group_by(nflId, Team) %>% 
  count() %>% 
  rename("Snaps" = n)

#this shows how many snaps each player has with each team

#next we want to get everyones name, team, and position joined in

teams.coefs.ordinal <- left_join(Coefs, 
                               player.index %>% distinct(nflId, Name, Team, Position), 
                               by = "nflId") %>% 
  arrange(desc(Contribution)) %>% 
  #odd issue with the spelling of Devon Hamilton, we can just remove it
  filter(Name != "Davon Hamilton")


#I think we redo the join and only care about the players names so we have no doubles and can rank plaers

players.coefs.ordnial <- left_join(Coefs, 
                                 player.index %>% distinct(nflId, Name), 
                                 by = "nflId") %>% 
  arrange(desc(Contribution)) %>% 
  #odd issue with the spelling of Devon Hamilton, we can just remove it
  filter(Name != "Davon Hamilton")

#now we want to join both of these by the snap.counts

teams.final <- left_join(teams.coefs.ordinal, 
                         #here we join so the snaps are separate for the team the were on
                         player.snap.count, 
                         by = c("nflId", "Team")) %>% 
  select(nflId, Name, Team, Position, Snaps, Contribution)

players.final <- left_join(players.coefs.ordnial, 
                           #here we need to group the snaps all together regardless of their team
                           player.snap.count %>% 
                             group_by(nflId) %>% 
                             summarize(Snaps = sum(Snaps)), 
                           by = "nflId") %>% 
  select(nflId, Name, Snaps, Contribution)


#now we do the same thing as we did in epa

#lets deal with the teams first, I want to adjust their contribtuion by how many snaps they did for that team
#more snaps should be more contribution, lets first do a group by and summarize on the player and team level
#so we can get the percentage of snaps played for that team
#then we can rejoin and mutate

total.player.snaps <- player.snap.count %>% 
  group_by(nflId) %>% 
  summarize(Total.Snaps = sum(Snaps))

#now rejoin this to player.snap.counts and we can mutate to get percentages

percentage.snap.counts <- left_join(player.snap.count, total.player.snaps, by = "nflId") %>% 
  mutate(Snap.Percent = Snaps/Total.Snaps)

#now we join this back to teams.final on nflId and Team and just select snap percent then do a mutate
#and multiply the contribution to this

teams.final2 <- left_join(teams.final, 
                          percentage.snap.counts %>% select(nflId, Team, Snap.Percent), 
                          by = c("nflId", "Team")) %>% 
  mutate(Adjusted.Contribution = Contribution * Snap.Percent) %>% 
  arrange(desc(Adjusted.Contribution)) %>% 
  #now we can take a look at Teams overall...do we want to do sum or average?
  #lets first take out anyone who did less than 25 snaps..then take the average for the
  #teams
  filter(Snaps >= 25) %>% 
  group_by(Team) %>% 
  summarize(`Average Contribution` = mean(Adjusted.Contribution)) %>% 
  arrange(desc(`Average Contribution`)) %>% 
  #oakland does not exist anymore so lets just remove them
  filter(Team != "OAK")

#ok awesome, now we can just make the exact same plots as we did before for penalty contributions

graph1 <- teams.final2 %>% 
  ggplot(aes(x = reorder(Team, -`Average Contribution`), y = `Average Contribution`)) +
  geom_col(aes(color = Team, fill = Team), width = 0.5) +
  nflplotR::scale_color_nfl(type = "secondary") +
  nflplotR::scale_fill_nfl() +
  labs(title = "Average Penalty Contribution by Team") +
  theme_bw() +
  theme(axis.text.x = element_nfl_logo(), 
        axis.title.x = element_blank())

#amazing it looks exactly how I wanted it to look. I'm going to go ahead and save it here

ggsave("Regression_Plots/Team_Penalty_Contribution.png", plot = graph1)

#now we want to slightly change what we do here, lets only get the top 20 penalty contributors
#not the top and bottom 10, we only want to see which players are "causing" penalties

players.final2.top <- left_join(players.final, 
                                player.index %>% distinct(nflId, Position), 
                                by = "nflId") %>% 
  filter(Snaps >= 25) %>%
  #another issue simialr to Davon Hamilton, Da'Ron vs Daron
  filter(Name != "Daron Payne") %>% 
  head(20)

#lets save that dataframe

write.csv(players.final2.top, "Derived_Data/Top.20.Players.Penalty.csv", row.names = F)