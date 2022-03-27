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
  mutate(Penalty = punts$penalty.yards.clean) %>% 
  #here we use negative EPA since EPA is from the possession team perspective and I switched the variable of success 
  #to be from the return team perspective (-1 punters, 1 returners)
  mutate(EPA = -punts$epa) %>% 
  select(newId, EPA, Penalty, everything())

#in this script we are only doing the EPA regression, lets make our dataframe reflect that

Regress.df <- Sparse.tib.named %>% 
  select(-newId, -Penalty)

#we also will want to know snap counts for each player on each team, we can get that easily from the player index

player.snap.count <- player.index %>% 
  group_by(nflId, Team) %>% 
  count() %>% 
  rename("Snaps" = n)

#outstanding, now we can move on and try our different regressions. We already know the matrix is rank deficient
#so we can go ahead and scratch using a linear model. We need to have a penalty term in there and we don't want
#anyone to have a contribution of 0. so we are going to use ridge regression

#we'll use caret for all this so we can make sure it is all cross validated and we choose a good lambdas

set.seed(18) #great number

#no need to split into train and test, we are not predicting anything, rather we just want coeffecients

#initialize values of our penalty paramtere
lambda <- 10^seq(-3, 3, length = 50)

#and use caret to build the model

ridge <- train(
  #formula
  EPA ~., 
  #data
  data = Regress.df, 
  #using glmnet package
  method = "glmnet", 
  #setting 10 fold cv
  trControl = trainControl("cv", number = 10),
  #we know alpha should be 0 for ridge, and we set the sequence of lambdas here
  tuneGrid = expand.grid(alpha = 0, lambda = lambda)
)

#now we want to order everyone by their contribution

orderd.coefs.ridge <- tibble(
  nflId = as.numeric(gsub("`","", names(sort(coef(ridge$finalModel, ridge$bestTune$lambda)[, 1], decreasing = T)))), 
  Contribution = as.numeric(sort(coef(ridge$finalModel, ridge$bestTune$lambda)[, 1], decreasing = T))
)

#the NA is from the intercept, we don't want that...so in the next step we can just omit it

#next we want to get everyones name, team, and position joined in

teams.coefs.ridge <- left_join(na.omit(orderd.coefs.ridge), 
                               player.index %>% distinct(nflId, Name, Team, Position), 
                               by = "nflId") %>% 
  arrange(desc(Contribution)) %>% 
  #odd issue with the spelling of Devon Hamilton, we can just remove it
  filter(Name != "Davon Hamilton")

#next issue we have is when people changed teams, they end up having the same contribution but being on there 2x

#we aren't sure which team the contribution is for...so what we can do is weight their contribution by how
#many snaps they had for that team

#I think we redo the join and only care about the players names so we have no doubles and can rank plaers

players.coefs.ridge <- left_join(na.omit(orderd.coefs.ridge), 
                               player.index %>% distinct(nflId, Name), 
                               by = "nflId") %>% 
  arrange(desc(Contribution)) %>% 
  #odd issue with the spelling of Devon Hamilton, we can just remove it
  filter(Name != "Davon Hamilton")

#now we want to join both of these by the snap.counts

teams.final <- left_join(teams.coefs.ridge, 
                         player.snap.count, 
                         by = c("nflId", "Team")) %>% 
  select(nflId, Name, Team, Position, Snaps, Contribution)

players.final <- left_join(players.coefs.ridge, 
                           player.snap.count %>% 
                             group_by(nflId) %>% 
                             summarize(Snaps = sum(Snaps)), 
                           by = "nflId") %>% 
  select(nflId, Name, Snaps, Contribution)


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

#beautiful...I think this is working how I want it to. Basically we have each team ranked by the average player
#contribution adjusted by how many snaps they took for that team, minimum 25 snaps

#now I want to build that sweet plot to for the teams

graph1 <- teams.final2 %>% 
  ggplot(aes(x = reorder(Team, -`Average Contribution`), y = `Average Contribution`)) +
  geom_col(aes(color = Team, fill = Team), width = 0.5) +
  nflplotR::scale_color_nfl(type = "secondary") +
  nflplotR::scale_fill_nfl() +
  labs(title = "Average EPA Contribution by Team") +
  theme_bw() +
  theme(axis.text.x = element_nfl_logo(), 
        axis.title.x = element_blank())

#amazing it looks exactly how I wanted it to look. I'm going to go ahead and save it here

ggsave("Regression_Plots/Team_EPA_Contribution.png", plot = graph1)

#not sure if I really care about the positional analysis, lets move on to the player by player look

#ok lets just try to make the same plot as above, but with the top 10 and bottom 10 players with their headshots

#first lets filter the data down so everyone is 25 snaps min

#start woth top 10
players.final2.top <- left_join(players.final, 
                            player.index %>% distinct(nflId, Position), 
                            by = "nflId") %>% 
  filter(Snaps >= 25) %>%
  #another issue simialr to Davon Hamilton, Da'Ron vs Daron
  filter(Name != "Daron Payne") %>% 
  head(10)
  
#now bottom 10
players.final2.bot <- left_join(players.final, 
                                player.index %>% distinct(nflId, Position), 
                                by = "nflId") %>% 
  filter(Snaps >= 25) %>%
  filter(Name != "Daron Payne") %>% 
  tail(10)

#now bind those

players.final3 <- rbind(players.final2.top, players.final2.bot) %>% 
  select(nflId, Name, Position, Snaps, Contribution)

#now make the ggplot, we want the same style as the team one, lets split it in half for top and bottom 10

graph2 <- players.final3 %>% 
  ggplot(aes(x = reorder(Name, -Contribution), y = Contribution)) +
  geom_col(aes(fill = Position), width = 0.5) +
  #split in half
  geom_vline(aes(xintercept = 10.5), color = "red", linetype = "dashed") +
  #add labels for top and bottom
  geom_label(aes(x = 5.5, y = -0.01, label = "Top 10")) +
  geom_label(aes(x = 15.5, y = 0.01, label = "Bottom 10")) +
  labs(title = "Player EPA Contribution (Min 25 Snaps)", 
       x = "Player", 
       y = "EPA Contribution") +
  theme_bw() +
  #this is a bit tricky, I want to adjust the rotation for top and bottom separately
  theme(axis.text.x = element_text(angle = c(rep(45, 10), rep(315, 10)), 
                                   hjust = c(rep(1, 10), rep(0, 10)))) +
  scale_fill_brewer(palette = "Paired")
  
ggsave("Regression_Plots/Player_EPA_Contribution.png", plot = graph2)

#now the question is, do I want to make tables or am I good with these plots?

#tbh I think I'm ok with these plots for now, I may change these to be tables depending on what the class thinks
#I think it could be worth saving this top/bottom ten data frame so if I wanted to in the analysis RMD I could
#make a nice looking kable...can't do a reactable in a pdf

#lets save that dataframe

write.csv(players.final3, "Derived_Data/Top.10.Players.csv", row.names = F)

#this should conclude my EPA regression work, lets move on to penalty yards Wednesday

#lets see if we can make this gt table, turns out we need to do this in a different script?
#we don't but it makes it way easier if we do, so lets just do that

