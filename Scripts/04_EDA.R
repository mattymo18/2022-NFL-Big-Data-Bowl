#EDA

#lets load my library and the sparse data frame, we'll need the play data frame as well

library(tidyverse)
library(Matrix)
library(knitr)
library(kableExtra)

Sparse.Df <- readMM("Derived_Data/Sparse.Matrix.txt")

punts <- read_csv("Derived_Data/clean.plays.csv")

player.index <- read_csv("Derived_Data/player.index.csv")

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

#ok, lets start making some plots just to see what we have

#start with histograms of responses

#we can make all of those at once easily in ggplot
graph1 <- Sparse.tib.named %>% 
  rename("Net Yards Gained" = NYG, 
         "Field Position" = Field.Pos, 
         "Penalty Yards" = Pen.Yrds) %>% 
  pivot_longer(cols = c(`Net Yards Gained`, `Field Position`, `Penalty Yards`), 
               names_to = "Variable", values_to = "Value") %>% 
  select(Variable, Value) %>% 
  ggplot(aes(x = Value)) +
  geom_histogram(aes(fill = Variable)) +
  theme_bw() +
  labs(y = "Count", 
       title = "Response Variable Histograms") +
  facet_wrap(~Variable)

#then we should save this in an EDA folder

ggsave("EDA_Plots/01_Response_Histograms.png", plot = graph1)

#great, we'll be able to do some boxplots of the same thing to get another look at it

#lets try to visualize the sparse matrix now

#it's quite difficult becasue it is so large, but we learn something useful

graph2 <- player.index %>% 
  mutate(Side = as.factor(ReturnTeam)) %>% 
  ggplot(aes(x = ColIdx, y = RowIdx)) +
  geom_tile(aes(fill = Side)) +
  theme_dark() +
  scale_fill_manual(values = c("#FFFFFF", "#800080"))

ggsave("EDA_Plots/02_Sparse_Mat_Vis.png", plot = graph2)

#lets do boxplots of the responses now
graph3 <- Sparse.tib.named %>% 
  rename("Net Yards Gained" = NYG, 
         "Field Position" = Field.Pos, 
         "Penalty Yards" = Pen.Yrds) %>% 
  pivot_longer(cols = c(`Net Yards Gained`, `Field Position`, `Penalty Yards`), 
               names_to = "Variable", values_to = "Value") %>% 
  select(Variable, Value) %>% 
  ggplot(aes(x = Variable, y = Value)) +
  geom_boxplot(aes(color = Variable)) +
  geom_jitter(aes(color = Variable), alpha = .07) +
  theme_bw() +
  labs(title = "Response Variable Boxplots")

ggsave("EDA_Plots/03_Response_Boxplots.png", plot = graph3)


#lets check out what some scatter plots of these variables look like together

#one fore NYG vs. FP
graph4 <- Sparse.tib.named %>%
  rename("Net Yards Gained" = NYG, 
         "Field Position" = Field.Pos) %>% 
  ggplot(aes(x = `Net Yards Gained`, y = `Field Position`)) +
  geom_point(color = "red", alpha = .75) +
  theme_bw() +
  labs(title = "Net Yards Gained Vs. Field Position", 
       caption = "*Note: Lots of 0s for Net Yards Gained")

ggsave("EDA_Plots/04_Response_Scatterplot_NYG_FP.png", plot = graph4)

#one for NYG vs PY
graph5 <- Sparse.tib.named %>%
  rename("Net Yards Gained" = NYG, 
         "Penalty Yards" = Pen.Yrds) %>% 
  ggplot(aes(x = `Net Yards Gained`, y = `Penalty Yards`)) +
  geom_point(color = "red", alpha = .75) +
  coord_flip() +
  theme_bw() +
  labs(title = "Net Yards Gained Vs. Penalty Yards")

ggsave("EDA_Plots/05_Response_Scatterplot_NYG_PY.png", plot = graph5)

#finally one for FP vs PY
graph6 <- Sparse.tib.named %>%
  rename("Field Position" = Field.Pos, 
         "Penalty Yards" = Pen.Yrds) %>% 
  ggplot(aes(x = `Field Position`, y = `Penalty Yards`)) +
  geom_point(color = "red", alpha = .75) +
  coord_flip() +
  theme_bw() +
  labs(title = "Field Position Vs. Penalty Yards")

ggsave("EDA_Plots/06_Response_Scatterplot_FP_PY.png", plot = graph6)

#lets swich gears a bit here, why don't we try to summaruze our sparse matrix instead of visualizing it, maybe
#some table wiuld be nicer. 

#first lets take a look at the top 5 players with regard to proportion of total plays played, we can take some
#simple colmeans and rank them in order, for defense we want the closest to -1 and offense we want 1

#first we can look at the offense
offense.prop <- head(sort(colMeans(Sparse.tib.named[, 5:ncol(Sparse.tib.named)]), decreasing = T), 5)

#next the defense
defense.prop <- head(sort(colMeans(Sparse.tib.named[, 5:ncol(Sparse.tib.named)]), decreasing = F), 5)

#now lets make these look like a nice table with the players real names and label for offense/defense

offense.table <- tibble(
  nflId = as.numeric(names(offense.prop)), 
  ProportionPlayed = abs(as.numeric(offense.prop)), 
  Side = rep("Offense", 5)
)

#and simply join it with the player.index

offense.table.clean <- left_join(offense.table, player.index %>% 
                                   distinct(nflId, Name), by = "nflId") %>% 
  select(Name, Side, ProportionPlayed)

#and do the same thing for defense


defense.table <- tibble(
  nflId = as.numeric(names(defense.prop)), 
  ProportionPlayed = abs(as.numeric(defense.prop)), 
  Side = rep("Defense", 5)
)

#and simply join it with the player.index

defense.table.clean <- left_join(defense.table, player.index %>% 
                                   distinct(nflId, Name), by = "nflId") %>% 
  select(Name, Side, ProportionPlayed)


#and finally we can put them together and reorder by Proportion played

Prop.table <- rbind(offense.table.clean, defense.table.clean) %>% 
  arrange(desc(ProportionPlayed))

#now lets save this table as something we can bring back in later and look nice, we can use kable then save it
#as a png

kable(Prop.table) %>% 
  kable_styling(full_width = F) %>%
  save_kable(file = "EDA_Plots/07_player_prop_played_table.png")
