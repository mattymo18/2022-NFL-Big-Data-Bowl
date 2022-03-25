#EDA

#3/8/2022 now that we have changed up what we are doing for the thesis we'll want to redo a lot of this and comment a lot of it out

#lets load my library and the sparse data frame, we'll need the play data frame as well

library(tidyverse)
library(Matrix)
library(knitr)
library(kableExtra)
library(ggrepel)

Sparse.Df <- readMM("Derived_Data/Sparse.Matrix.txt")

punts <- read_csv("Derived_Data/clean.plays.csv")

player.index <- read_csv("Derived_Data/player.index.csv")

#first lets attach the unique newIds to the Sparse.Df as it's own column

#we need to convert the sparse matrix into a large data frame

Sparse.tib <- as.data.frame(as.matrix(Sparse.Df))

#now we can figure out which column corresponds to which player with the player.index

col.names <- player.index %>%
    arrange(ColIdx) %>%
    distinct(nflId, ColIdx) %>%
    select(nflId)

names(Sparse.tib) <- as.character(unlist(col.names))

#now we just put in all the variables we need

# Sparse.tib.named <- Sparse.tib %>% 
#   mutate(newId = unique(player.index$newId)) %>% 
#   mutate(NYG = punts$NetYardsGained) %>% 
#   mutate(Field.Pos = punts$field.pos) %>% 
#   mutate(Pen.Yrds = punts$penalty.yards.clean) %>% 
#   select(newId, NYG, Field.Pos, Pen.Yrds, everything())

Sparse.tib.named <- Sparse.tib %>% 
  mutate(newId = punts$newId) %>% 
  mutate(Penalty = punts$penalty.yards.clean) %>% 
  #here we use negative EPA since EPA is from the possession team perspective and I switched the variable of success 
  #to be from the return team perspective (-1 punters, 1 returners)
  mutate(EPA = -punts$epa) %>% 
  select(newId, EPA, Penalty, everything())

#ok, lets start making some plots just to see what we have

#start with histograms of responses, 3/8/2022 lets fix this rather than comment it out

#we can make all of those at once easily in ggplot
graph1 <- Sparse.tib.named %>%
  pivot_longer(cols = c(Penalty, EPA), 
               names_to = "Variable", values_to = "Value") %>% 
  select(Variable, Value) %>% 
  ggplot(aes(x = Value)) +
  geom_histogram(aes(fill = Variable), bins = 30) +
  theme_bw() +
  theme(legend.position = "none") +
  labs(y = "Count", 
       title = "Response Variable Histograms") +
  facet_wrap(~Variable)

#then we should save this in an EDA folder

ggsave("EDA_Plots/01_Response_Histograms.png", plot = graph1)

#great, we'll be able to do some boxplots of the same thing to get another look at it

#lets try to visualize the sparse matrix now

#it's quite difficult becasue it is so large, but we learn something useful

# graph2 <- player.index %>% 
#   mutate(Side = as.factor(ReturnTeam)) %>% 
#   ggplot(aes(x = ColIdx, y = RowIdx)) +
#   geom_tile(aes(fill = Side)) +
#   theme_dark() +
#   scale_fill_manual(values = c("#FFFFFF", "#800080"))
# 
# ggsave("EDA_Plots/02_Sparse_Mat_Vis.png", plot = graph2)

#lets do boxplots of the responses now
graph2 <- Sparse.tib.named %>%
  pivot_longer(cols = c(Penalty, EPA), 
               names_to = "Variable", values_to = "Value") %>% 
  select(Variable, Value) %>% 
  ggplot(aes(x = Variable, y = Value)) +
  geom_boxplot(aes(color = Variable)) +
  geom_jitter(aes(color = Variable), alpha = .07) +
  theme_bw() +
  theme(legend.position = "none") +
  labs(title = "Response Variable Boxplots")

ggsave("EDA_Plots/02_Response_Boxplots.png", plot = graph2)


#lets check out what some scatter plots of these variables look like together

#one fore NYG vs. FP
# graph4 <- Sparse.tib.named %>%
#   rename("Net Yards Gained" = NYG, 
#          "Field Position" = Field.Pos) %>% 
#   ggplot(aes(x = `Net Yards Gained`, y = `Field Position`)) +
#   geom_point(color = "red", alpha = .75) +
#   theme_bw() +
#   labs(title = "Net Yards Gained Vs. Field Position", 
#        caption = "*Note: Lots of 0s for Net Yards Gained")
# 
# ggsave("EDA_Plots/04_Response_Scatterplot_NYG_FP.png", plot = graph4)
# 
# #one for NYG vs PY
# graph5 <- Sparse.tib.named %>%
#   rename("Net Yards Gained" = NYG, 
#          "Penalty Yards" = Pen.Yrds) %>% 
#   ggplot(aes(x = `Net Yards Gained`, y = `Penalty Yards`)) +
#   geom_point(color = "red", alpha = .75) +
#   coord_flip() +
#   theme_bw() +
#   labs(title = "Net Yards Gained Vs. Penalty Yards")
# 
# ggsave("EDA_Plots/05_Response_Scatterplot_NYG_PY.png", plot = graph5)
# 
# #finally one for FP vs PY
# graph6 <- Sparse.tib.named %>%
#   rename("Field Position" = Field.Pos, 
#          "Penalty Yards" = Pen.Yrds) %>% 
#   ggplot(aes(x = `Field Position`, y = `Penalty Yards`)) +
#   geom_point(color = "red", alpha = .75) +
#   coord_flip() +
#   theme_bw() +
#   labs(title = "Field Position Vs. Penalty Yards")
# 
# ggsave("EDA_Plots/06_Response_Scatterplot_FP_PY.png", plot = graph6)

#lets swich gears a bit here, why don't we try to summaruze our sparse matrix instead of visualizing it, maybe
#some table wiuld be nicer. 

#first lets take a look at the top 5 players with regard to proportion of total plays played, we can take some
#simple colmeans and rank them in order, for defense we want the closest to -1 and offense we want 1

#first we can look at the offense
return.prop <- head(sort(colMeans(Sparse.tib.named[, 5:ncol(Sparse.tib.named)]), decreasing = T), 5)

#next the defense
punting.prop <- head(sort(colMeans(Sparse.tib.named[, 5:ncol(Sparse.tib.named)]), decreasing = F), 5)

#now lets make these look like a nice table with the players real names and label for offense/defense

return.table <- tibble(
  nflId = as.numeric(names(return.prop)), 
  ProportionPlayed = abs(as.numeric(return.prop)), 
  Side = rep("Return", 5)
)

#and simply join it with the player.index

return.table.clean <- left_join(return.table, player.index %>% 
                                   distinct(nflId, Name), by = "nflId") %>% 
  select(Name, Side, ProportionPlayed)

#and do the same thing for defense


punting.table <- tibble(
  nflId = as.numeric(names(punting.prop)), 
  ProportionPlayed = abs(as.numeric(punting.prop)), 
  Side = rep("Punting", 5)
)

#and simply join it with the player.index

punting.table.clean <- left_join(punting.table, player.index %>% 
                                   distinct(nflId, Name), by = "nflId") %>% 
  select(Name, Side, ProportionPlayed)


#and finally we can put them together and reorder by Proportion played

Prop.table <- rbind(return.table.clean, punting.table.clean) %>% 
  arrange(desc(ProportionPlayed))

#now lets save this table as something we can bring back in later and look nice, we can use kable then save it
#as a png

kable(Prop.table) %>% 
  kable_styling(full_width = F) %>%
  save_kable(file = "EDA_Plots/03_player_prop_played_table.png")

#lets try to take a look at each players average for the three variables of interest and compare it 
#to the population average, we can visualize that


#first I think I'll need to build a function that will take their absolute value of each players column vector and
#and multiply it by the corresponding value in the three responses then I want to take an average, simply divide by 
#sum of the abs value of the col

#lets do three different functions, that should be pretty easy

#3/8/2022 lets revisit this later with the two variables of interest we have. Should be easy as making a new function for epa and removing
#the NYG and FP from this. 

player.avg.func.EPA <- function(x) {
  avg = abs(x)%*%Sparse.tib.named$EPA/sum(abs(x))
}

player.avg.func.PY <- function(x) {
  avg = abs(x)%*%Sparse.tib.named$Penalty/sum(abs(x))
}

#now we can do a similar excercise as above to make the tables for each player with their names

response.per.player.avg <- tibble(
  nflId = as.numeric(names(Sparse.tib.named[, 5:ncol(Sparse.tib.named)])), 
  EPA.AVG = apply(Sparse.tib.named[, 5:ncol(Sparse.tib.named)], 2, player.avg.func.EPA), 
  PY.AVG = apply(Sparse.tib.named[, 5:ncol(Sparse.tib.named)], 2, player.avg.func.PY)
)

#now we can simply add in the names and make some plots

response.per.player.avg.named <- left_join(response.per.player.avg, 
                                           player.index %>% 
                                           distinct(nflId, Name), 
                                           by = "nflId") %>% 
  select(nflId, Name, everything())


#now we want to compare these to the population means and visualize it

popmeans <- tibble(
  Variable = c("EPA", "Penalty"), 
  Value = c(mean(Sparse.tib.named$EPA), mean(Sparse.tib.named$Penalty))
)

graph3 <- response.per.player.avg.named %>% 
  #rename for convenience
  rename("Penalty" = PY.AVG, 
         "EPA" = EPA.AVG) %>% 
  #pivot so we can plot nicely
  pivot_longer(cols = c(EPA, Penalty), 
               names_to = "Variable", values_to = "Value") %>% 
  select(Variable, Value) %>% 
  ggplot(aes(x = Value, y = Variable, color = Variable)) +
  #we want to start with just points for each in 1dim per variable
  geom_point() +
  #now we can add in segments for the population averages
  geom_segment(aes(x = mean(Sparse.tib.named$EPA), xend = mean(Sparse.tib.named$EPA), 
                   y = 0.6, yend = 1.4, ), color = "black") +
  geom_segment(aes(x = mean(Sparse.tib.named$Penalty), xend = mean(Sparse.tib.named$Penalty), 
                   y = 1.6, yend = 2.4, ), color = "black") +
  #now we want to label a few of the players, but only the ones significantly different than the population avg
  #lets do 2 standard deviations, we can use ggrepel so there are no overlaps
  geom_text_repel(data = response.per.player.avg.named %>%
                    rename("Value" = EPA.AVG) %>%
                    mutate(Variable = "EPA") %>% 
                    filter(Value < mean(Sparse.tib.named$EPA) - 2*sd(Sparse.tib.named$EPA) | 
                             Value > mean(Sparse.tib.named$EPA) + 2*sd(Sparse.tib.named$EPA)), 
                  aes(x = Value, label = Name), 
                  color = "black", size = 2.5, segment.color = "gray", max.overlaps = 15) +
  geom_text_repel(data = response.per.player.avg.named %>%
                    rename("Value" = PY.AVG) %>%
                    mutate(Variable = "Penalty") %>% 
                    filter(Value < mean(Sparse.tib.named$Penalty) - 2*sd(Sparse.tib.named$Penalty) | 
                             Value > mean(Sparse.tib.named$Penalty) + 2*sd(Sparse.tib.named$Penalty)), 
                  aes(x = Value, label = Name), 
                  color = "black", size = 2.5, segment.color = "gray", max.overlaps = 15) +
  theme(plot.caption.position = "left") +
  coord_flip() +
  theme_bw() +
  labs(title = "Player Averages vs. Population Average", 
       caption = "*Black lines signify population means per variable") +
  theme(plot.caption = element_text(color = "red", face = "italic", hjust = 1.3))

ggsave("EDA_Plots/04_Player_Avg_Pop_Avg.png", plot = graph3)

#I think this could be it for the eda