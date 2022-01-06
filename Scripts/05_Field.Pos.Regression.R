#load in data and libs

library(tidyverse)
library(Matrix)
library(knitr)
library(kableExtra)
library(caret)
library(glmnet)
library(reactable)
library(htmltools)
library(ggrepel)

Sparse.Df <- readMM("Derived_Data/Sparse.Matrix.txt")

punts <- read_csv("Derived_Data/clean.plays.csv")

player.index <- read_csv("Derived_Data/player.index.csv")

#need player data from source too for positions
player.positions <- read_csv("Source_Data/players.csv") %>% 
  select(nflId, Position)

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

#we're only going to use the full model, we want to see every player's "contribution"

#we don't want to bring in the entire summary, but lets find the relevant things

#first lets plot it

# plot(lm1)

#everything there seems fine to me honestly, there are a ton of points but nothing stood out to me

#lets find the adjusted r squared

summary <- summary(lm1)

# summary$adj.r.squared
#I think I expected this, we have lots of variables here and despite it being about normal this is a tough regression task for an lm

#lets find our top 10 for positive coeff, but we want them to have been in at least 25 snaps
#for some reason when we find the names of this summary object it adds in a ``, we can remove this with gsub, otherwise
#it will make NAs when we want it ot be a double, we'll just use sort

orderd.coefs <- tibble(
  nflId = as.numeric(gsub("`","", names(sort(summary$coefficients[, 1], decreasing = T)))), 
  Contribution = as.numeric(sort(summary$coefficients[, 1], decreasing = T))
)

#and we can get their name easily from player.index
#found something interesting about devon hamilton, but we can just remove him manually, it wont make a difference
#sometimes they used a capital DeVon and others they used Devon but the nflId was always the same

ordered.named <- left_join(na.omit(orderd.coefs), player.index %>% distinct(nflId, Name), by = "nflId") %>% 
  distinct(nflId, Name, Contribution) %>% 
  arrange(desc(Contribution)) %>% 
  filter(Name != "Davon Hamilton")


#now I want to add in how many plays they were part of, so we can have a good judge of how much effect they really had
#i think we should use ~25 snaps, this seems like a decent amount of plays for special teams, could be 3-4 games and we get returners more action


player.count <- player.index %>% 
  group_by(nflId) %>% 
  count()


ordered.final <- left_join(ordered.named, player.count, by = "nflId")

#lets do this just to show a problem when we dont do anything about snapcounts

lm.top20.final.snapcount <- ordered.final %>% 
  rename(Snaps = n) %>% 
  arrange(desc(Contribution)) %>% 
  head(20)

#and we can save it as a kable for now, maybe try to figure out reactable tomorrow, it seems easy
#but these are still useful and we should save them, they look nice in a table

kable(lm.top20.final.snapcount, caption = "Top 20 Linear Model") %>% 
  kable_styling(full_width = F) %>%
  save_kable(file = "Regression_Plots/01_Top20.FP.Table.SnapPrblm.png")

#now we can adjust it to fix issue with snapcounts

lm.top20.final <- ordered.final %>% 
  rename(Snaps = n) %>% 
  filter(Snaps >= 25) %>% 
  arrange(desc(Contribution)) %>% 
  head(20)

#now why dont we grab the pvals for these players as well

orderd.pvals <- tibble(
  nflId = as.numeric(gsub("`","", names(sort(summary$coefficients[, 4], decreasing = F)))), 
  Pvalue = as.numeric(sort(summary$coefficients[, 4], decreasing = F))
)

#and left join

lm.top20.final.pval <- left_join(lm.top20.final, orderd.pvals, by = "nflId") %>% 
  select(nflId, Name, Contribution, Pvalue)

#interestingly enough, this basically gave us a bunch of punters and long snappers, that's sort of cool I guess
#lets save it as a png

kable(lm.top20.final.pval, caption = "Top 20 Linear Model (> 25 snaps)") %>% 
  kable_styling(full_width = F) %>%
  save_kable(file = "Regression_Plots/02_Top20.FP.Table.png")


#now rather than ordering it by contribution lets look at p-values 
#I actualy don't think this is very useful, there is an obvious issue with this mehtod, but I still figured I could try it out, 
#and I honestly think there is something interesting here I can discuss

# ordered.pvals.named <- left_join(na.omit(orderd.pvals), player.index %>% distinct(nflId, Name), by = "nflId") %>% 
#   distinct(nflId, Name, Pvalue) %>% 
#   arrange(Pvalue) %>% 
#   #and we have to fix davon again
#   filter(Name != "Davon Hamilton")
# 
# 
# pvals.ordered.final <- left_join(ordered.pvals.named, player.count, by = "nflId")

#alright next we'll want to do a penalize regression and try that out as well, pretty decent results from the linear regression, finding 
#those punters and long snappers is useful, but this regression really can't be too correct, since the matrix is not invertible...

#there must still be some use in this, how else could I have found punters and long snappers first? Maybe I should look at top 20

#ok anyway, lets move on to some penalized regression, we want everyone to sill have a coeff, so that means we are going to use ridge

#we're going to use caret so we can do cv to choose a nice penalty paramter 

#first we want to partition the data in a nice way
set.seed(18) #great number

#now the question is, do I want a validation set too? I think I'm ok with just a train and test
train.samps <- Regress.df$Field.Pos %>% 
  createDataPartition(p = .8, list = F)

train <- Regress.df[train.samps, ]
test <- Regress.df[-train.samps, ]

#our data is already in a nice form and we don't need to form a model moatrix

#lets do out ridge regression, lets do 10 fold cv

#initialize values of our penalty paramtere
lambda <- 10^seq(-3, 3, length = 50)

#I expect this to take some time
ridge <- train(
  #formula
  Field.Pos ~., 
  #data
  data = train, 
  #using glmnet package
  method = "glmnet", 
  #setting 10 fold cv
  trControl = trainControl("cv", number = 10),
  #we know alpha should be 0 for ridge, and we set the sequence of lambdas here
  tuneGrid = expand.grid(alpha = 0, lambda = lambda)
)
#we should make some plots to take a look at the diagnostics

# Model coefficients
#we want ot use the bets lambda
# names(sort(coef(ridge$finalModel, ridge$bestTune$lambda)[, 1], decreasing = T))

#let do the same thing we did before to rank the top 20

orderd.coefs.ridge <- tibble(
  nflId = as.numeric(gsub("`","", names(sort(coef(ridge$finalModel, ridge$bestTune$lambda)[, 1], decreasing = T)))), 
  Contribution = as.numeric(sort(coef(ridge$finalModel, ridge$bestTune$lambda)[, 1], decreasing = T))
)

#now we need the names of all those players

ordered.named.ridge <- left_join(na.omit(orderd.coefs.ridge), player.index %>% distinct(nflId, Name), by = "nflId") %>% 
  distinct(nflId, Name, Contribution) %>% 
  arrange(desc(Contribution)) %>% 
  filter(Name != "Davon Hamilton")

#and we want to do the same snap count thing as before, this time lets use 50 since we have leveld the playing field significantly by shrinking
#all the estimates towards 0

ordered.final.ridge <- left_join(ordered.named.ridge, player.count, by = "nflId")

# we can make a nice little boxplot here

Contrib.boxplot <- ordered.final.ridge %>% 
  rename(Snaps = n) %>% 
  filter(Snaps >= 25) %>%
  ggplot(aes(x = "", y = Contribution)) +
  geom_boxplot(fill='#A4A4A4', color="purple") +
  geom_jitter(color = "purple", alpha = .2) +
  #lets use the top 1%
  geom_text_repel(aes(label = ifelse(Contribution >= 0 & Contribution >= as.numeric(quantile(
    ordered.final.ridge$Contribution, probs = .9)), Name, ""), 
    x = 1, y = Contribution), max.overlaps = 10) +
  theme_bw() +
  labs(title = "Contribution Boxplot")

ggsave("Regression_Plots/05_Contribution_Boxplot.png", plot = Contrib.boxplot)

#now I want to know their percentiles since we adjutsed snap counts

ordered.final.ridge.percent <- ordered.final.ridge %>% 
  filter(Contribution >= 0) %>%
  arrange(desc(Contribution)) %>% 
  mutate(Percentile = case_when(
    Contribution >= as.numeric(quantile(ordered.final.ridge$Contribution, probs = .90)) &
      Contribution <= as.numeric(quantile(ordered.final.ridge$Contribution, probs = .91)) ~ "10",
    Contribution >= as.numeric(quantile(ordered.final.ridge$Contribution, probs = .91)) &
      Contribution <= as.numeric(quantile(ordered.final.ridge$Contribution, probs = .92)) ~ "9",
    Contribution >= as.numeric(quantile(ordered.final.ridge$Contribution, probs = .92)) &
      Contribution <= as.numeric(quantile(ordered.final.ridge$Contribution, probs = .93)) ~ "8",
    Contribution >= as.numeric(quantile(ordered.final.ridge$Contribution, probs = .93)) &
      Contribution <= as.numeric(quantile(ordered.final.ridge$Contribution, probs = .94)) ~ "7",
    Contribution >= as.numeric(quantile(ordered.final.ridge$Contribution, probs = .94)) &
      Contribution <= as.numeric(quantile(ordered.final.ridge$Contribution, probs = .95)) ~ "6",
    Contribution >= as.numeric(quantile(ordered.final.ridge$Contribution, probs = .95)) &
      Contribution <= as.numeric(quantile(ordered.final.ridge$Contribution, probs = .96)) ~ "5",
    Contribution >= as.numeric(quantile(ordered.final.ridge$Contribution, probs = .96)) &
      Contribution <= as.numeric(quantile(ordered.final.ridge$Contribution, probs = .97)) ~ "4",
    Contribution >= as.numeric(quantile(ordered.final.ridge$Contribution, probs = .97)) &
      Contribution <= as.numeric(quantile(ordered.final.ridge$Contribution, probs = .98)) ~ "3",
    Contribution >= as.numeric(quantile(ordered.final.ridge$Contribution, probs = .98)) &
      Contribution <= as.numeric(quantile(ordered.final.ridge$Contribution, probs = .99)) ~ "2",
    Contribution >= as.numeric(quantile(ordered.final.ridge$Contribution, probs = .99)) &
      Contribution <= as.numeric(quantile(ordered.final.ridge$Contribution, probs = 1)) ~ "1",
    TRUE ~ "10+")) %>% 
  filter(n >= 25)

#before I make the top 20, lets filter out for 25 snaps and make a nice plot for showing how people stack up to the mean

top20.final.ridge <- ordered.final.ridge.percent %>% 
  rename(Snaps = n) %>% 
  filter(Snaps >= 25) %>% 
  arrange(desc(Contribution)) %>% 
  select(nflId, Name, Contribution, Snaps, Percentile) %>% 
  head(20)

#now finally I can join with their position

top20.final.ridge.pos <- left_join(top20.final.ridge, player.positions %>% distinct(nflId, Position), by = "nflId")

#now since reactable is insane and I can't save it, we need to save this as derived data

write.csv(top20.final.ridge.pos, "Derived_Data/top20.csv", row.names = F)

#wow this is extremely encouraging. We found some players that are on special teams very often and seemingly do well
#this time it is not just the punters, we also find players more "behind the scenes" and we also find some star punt returners
#as well as punters too

#we kind of get exactly what we want here, it seems almost evden the type of player that is represented, and it gives us a way to evaluate 
#and compare them in the same setting
#this is cool, lets save it as a kable, for the bdb submission maybe i can make a reactable of this as well, I think this is my major find

kable(top20.final.ridge, caption = "Top 20 Ridge Model (> 25 snaps)") %>% 
  kable_styling(full_width = F) %>%
  save_kable(file = "Regression_Plots/03_Top20.FP.Ridge.Table.png")
#lets find the worst players too

bot20.final.ridge <- ordered.final.ridge %>% 
  rename(Snaps = n) %>% 
  filter(Snaps >= 50) %>% 
  arrange(Contribution) %>% 
  select(nflId, Name, Contribution, Snaps) %>% 
  head(20)

kable(bot20.final.ridge, caption = "Bottom 20 Ridge Model (> 25 snaps)") %>% 
  kable_styling(full_width = F) %>%
  save_kable(file = "Regression_Plots/04_Bot20.FP.Ridge.Table.png")

# Make predictions
predictions <- ridge %>% predict(test)
# Model prediction performance
data.frame(
  RMSE = RMSE(predictions, test$Field.Pos),
  Rsquare = R2(predictions, test$Field.Pos)
)

#well, we don't have great accuracy here but that's almost expected when you have 2000+ predictors,
#but I think this model is still absolutely useful I like where I'm at now, I think since this is what litersture suggests I do I should ride with it
#here are my main findings