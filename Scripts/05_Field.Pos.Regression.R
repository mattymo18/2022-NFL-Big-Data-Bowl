#load in data and libs

library(tidyverse)
library(Matrix)
library(knitr)
library(kableExtra)

Sparse.Df <- readMM("Derived_Data/Sparse.Matrix.txt")

punts <- read_csv("Derived_Data/clean.plays.csv")

player.index <- read_csv("Derived_Data/player.index.csv")

#we need to do exactly what we did before in the EDA so we have the nice named data frame

Sparse.tib <- as.data.frame(as.matrix(Sparse.Df))

#now we can figure out which column corresponds to which player with the player.index

col.names <- player.index %>%
  arrange(ColIdx)  %>%
  distinct(nflId, ColIdx) %>%
  select(nflId)

names(Sparse.tib) <- as.character(unlist(col.names))

#now we just put in all the variables we need

Sparse.tib.named <- Sparse.tib %>% 
  mutate(newId = unique(player.index$newId)) %>% 
  mutate(NYG = punts$NetYardsGained) %>% 
  mutate(Field.Pos = punts$field.pos) %>% 
  mutate(Pen.Yrds = punts$penalty.yards.clean) %>% 
  select(newId, NYG, Field.Pos, Pen.Yrds, everything())

#ok, in this script we are only taking a look at Field position

Regress.df <- Sparse.tib.named %>% 
  select(-c(newId, NYG, Pen.Yrds))

#lets quickly visualize the response again, it seemed very normal before

# hist(Regress.df$Field.Pos)
#beatiful, it looks nice and normally distributed with mean -40

#ok, lets just go for a standard linear regression, we will likely try a penalized approach since we know this matrix doesn't have full rank

lm1 <- lm(Field.Pos ~., data = Regress.df)

#we don't want to bring in the entire summary, but lets find the relevant things

#first lets plot it

# plot(lm1)

#everything there seems fine to me honestly, there are a ton of points but nothing stood out to me

#lets find the adjusted r squared

summary <- summary(lm1)

# summary$adj.r.squared
#I think I expected this, we have lots of variables here

#lets find our top 10 for positive coeff, but we want them to have been in at least 25 snaps

orderd.coefs <- tibble(
  nflId = as.numeric(gsub("`","", names((sort(summary$coefficients[, 1], decreasing = T))))), 
  Contribution = as.numeric(sort(summary$coefficients[, 1], decreasing = T))
)
#and we can get their name easily from player.index
#found something interesting about devon hamilton, but we can just remove him manually, it wont make a difference
#sometimes they used a capital DeVon and others they used Devon

ordered.named <- left_join(na.omit(orderd.coefs), player.index %>% distinct(nflId, Name), by = "nflId") %>% 
  distinct(nflId, Name, Contribution) %>% 
  arrange(desc(Contribution)) %>% 
  filter(Name != "Davon Hamilton")


#now I want to add in how many plays they were part of, so we can have a good judge of how much effect they really had
#i think we should use ~25 snaps, this seems like a decent amount of plays for special teams, could be 3-4 games


player.count <- player.index %>% 
  group_by(nflId) %>% 
  count()


ordered.final <- left_join(ordered.named, player.count, by = "nflId")

lm.top10.final <- ordered.final %>% 
  rename(Snaps = n) %>% 
  filter(Snaps >= 25) %>% 
  arrange(desc(Contribution)) %>% 
  head(10)

#interestingly enough, this basically gave us a bunch of punters and long snappers, that's sort of cool I guess
#lets save it as a png

kable(lm.top10.final) %>% 
  kable_styling(full_width = F) %>%
  save_kable(file = "Regression_Plots/01_Top10.FP.Table.png")

#alright next we'll want to do a penalize regression and try that out as well, pretty decent results from the linear regression, finding 
#those punters and long snappers is useful
