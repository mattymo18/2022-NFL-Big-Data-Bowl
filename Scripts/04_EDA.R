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