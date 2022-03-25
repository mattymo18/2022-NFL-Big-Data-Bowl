#load in the data and libs

#for data manipulation
library(tidyverse)
library(Matrix)
#for models
library(caret)
library(ordinalNet)


#set a seed
set.seed(18) #great number

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

#we are only dealing witj pen yrds here so lets make a regression dataframe like that

Regress.df <- Sparse.tib.named %>% 
  select(-newId, -EPA)

print("Data Loaded")

#so in this case, positive contribution is now bad. Anyone with positive contribution is contributing to penalties

#emailed a few people to see what they think, not sure if this is going to workout so I may need to change up my plan, 
#I think I could just use

#seems like I may be able to use the cv.zipath model formula for cv lasso zip model, lasso is fine for the penalty yards model
#since a 0 coeff simply means that player does not signifcanlty contribute to penalties

#ok lets try this cv.zipath with 10 fold cv and the poisson family and just see what happens

#model1 <- cv.zipath(Pen.Yrds ~ . | ., data = Regress.df, family = "poisson", nlambda = 10)

#ok there's a imsple reason this wont work, there are negative values...these count distributions cannot have negatives...
#really not sure where to go with this now...man im silly, probably should just use ridge again here...

#alright here we go, we are going to do a Regularized Ordinal Logisitc Regression. I think it will have an elastic net
#penalty but im also pretty sure we can just use ridge. We use the ordinalNet package for this

#no need to split into train and test, we are not predicting anything, rather we just want coefficients

#initialize values of our penalty parameters, we can't do too many since this model is taking 4ever
lambda <- 10^seq(-3, 3, length = 10)

#now lets try to build this cv model

#we need to split up to covariate matrix and the response

# cov.mat <- as.matrix(Regress.df %>% select(-Penalty))
# 
# #the response needs to be an ordered factor
# 
# response <- factor(Regress.df$Penalty)

#here we fit the model, we do 10 fold cv and we'll try the ridge penalty

#we're going to try to use caret to run this ordinal net with ridge penalty
#we also use the logit link, parallel modeltype to ensure each column has one coeff, 
#and the cumulative probability family as default
#we use AIC and Accuracy for choosing best lambda

# model1 <- train(
#   cov.mat,
#   response,
#   method = "ordinalNet",
#   trControl = trainControl("cv", number = 5),
#   tuneGrid = expand.grid(alpha = 0,
#                          lambda = lambda,
#                          criteria = "aic",
#                          link = "logit",
#                          modeltype = "parallel",
#                          family = "cumulative")
# )

#alright this never worked looks like I need to try a different cv method, caret is struggling

#lets just try to ordinalNetcv with 5 fold and not worry about setting alpha. Elasticnet is fine

# model2 <- ordinalNetCV(
#   x = cov.mat, 
#   y = response, 
#   nFoldsCV = 5, 
#   tuneMethod = "aic"
# )

#well left that going all night with the loglik tuning method and it couldn't get off the first fold
#it never converged so we need to try something else, maybe doing manual CV is the only way? but im worried
#that won't ever converge either...need to try though

#so first we need to randomly split the data, we'll use caret's createdatapartition here

folds <- Regress.df$Penalty %>% 
  createFolds(k = 10)

#now actually split the data, this will be fore 10 fold cv

fold1 <- Regress.df[folds[[1]], ]
fold2 <- Regress.df[folds[[2]], ]
fold3 <- Regress.df[folds[[3]], ]
fold4 <- Regress.df[folds[[4]], ]
fold5 <- Regress.df[folds[[5]], ]
fold6 <- Regress.df[folds[[6]], ]
fold7 <- Regress.df[folds[[7]], ]
fold8 <- Regress.df[folds[[8]], ]
fold9 <- Regress.df[folds[[9]], ]
fold10 <- Regress.df[folds[[10]], ]

print("Folds Built")

#now we already have out 10 lambdas, so here how this will work, 
#1st. we will fit the ordinal net on folds 2-10 with lam1 then test it on fold 1 and check the diagnostics
#then we continue with folds 1, 3:10 and lam2 and test on fold 2 and so on

#we should be fine to just use the standard ordinal net function here, since we can specify lets use the LASSO
#penalty here

# ################################################################# fold 1
# 
# df.cv1 <- rbind(
#   fold2,
#   fold3, 
#   fold4, 
#   fold5, 
#   fold6, 
#   fold7, 
#   fold8, 
#   fold9, 
#   fold10
# )
# 
# #nowe we need the first covariate matrix and response vector
# 
# cov.mat1 <- as.matrix(df.cv1[, -1])
# response1 <- as.factor(df.cv1$Penalty)
# 
# #finally build mod1, hopefully it doesn't take forever since we need to do this 10 times
# 
# mod1 <- ordinalNet(
#   x = cov.mat1, 
#   y = response1, 
#   alpha = 1, 
#   lambdaVals = lambda[1], 
#   family = "cumulative", 
#   link = "logit", 
#   parallelTerms = T
# )
# 
# #holy shit it actually worked...hell yes now we can just use AIC as our model measure to figure out what lam
# #value is best, lets continue with fold 2-10
# 
# #next test the model on the fold left out
# 
# preds1 <- tibble(
#   preds = predict(mod1, newx = as.matrix(fold1[, -1]), type = "class")) %>% 
#   mutate(preds = case_when(
#     preds == 1 ~ -1, 
#     preds == 2 ~ 0, 
#     preds == 3 ~ 1
#   ))
# obs1 <- as.factor(fold1[, 1])
# 
# postResample(preds1$preds, obs1) #accuracy: .884
# 
# ################################################################# fold 2
# 
# df.cv2 <- rbind(
#   fold1,
#   fold3, 
#   fold4, 
#   fold5, 
#   fold6, 
#   fold7, 
#   fold8, 
#   fold9, 
#   fold10
# )
# 
# #nowe we need the first covariate matrix and response vector
# 
# cov.mat2 <- as.matrix(df.cv2[, -1])
# response2 <- as.factor(df.cv2$Penalty)
# 
# #finally build mod1, hopefully it doesn't take forever since we need to do this 10 times
# 
# mod2 <- ordinalNet(
#   x = cov.mat2, 
#   y = response2, 
#   alpha = 1, 
#   lambdaVals = lambda[2], 
#   family = "cumulative", 
#   link = "logit", 
#   parallelTerms = T
# )
# 
# #test the model
# 
# preds2 <- tibble(
#   preds = predict(mod2, newx = as.matrix(fold2[, -1]), type = "class")) %>% 
#   mutate(preds = case_when(
#     preds == 1 ~ -1, 
#     preds == 2 ~ 0, 
#     preds == 3 ~ 1
#   ))
# obs2 <- as.factor(fold2[, 1])
# 
# postResample(preds2$preds, obs2) #accuracy: .906
# 
# ################################################################# fold 3
# 
# df.cv3 <- rbind(
#   fold2,
#   fold1, 
#   fold4, 
#   fold5, 
#   fold6, 
#   fold7, 
#   fold8, 
#   fold9, 
#   fold10
# )
# 
# #nowe we need the first covariate matrix and response vector
# 
# cov.mat3 <- as.matrix(df.cv3[, -1])
# response3 <- as.factor(df.cv3$Penalty)
# 
# #finally build mod1, hopefully it doesn't take forever since we need to do this 10 times
# 
# mod3 <- ordinalNet(
#   x = cov.mat3, 
#   y = response3, 
#   alpha = 1, 
#   lambdaVals = lambda[3], 
#   family = "cumulative", 
#   link = "logit", 
#   parallelTerms = T
# )
# 
# #test the model
# 
# preds3 <- tibble(
#   preds = predict(mod3, newx = as.matrix(fold3[, -1]), type = "class")) %>% 
#   mutate(preds = case_when(
#     preds == 1 ~ -1, 
#     preds == 2 ~ 0, 
#     preds == 3 ~ 1
#   ))
# obs3 <- as.factor(fold3[, 1])
# 
# postResample(preds3$preds, obs3) #accuracy: .906
# 
# ################################################################# fold 4
# 
# df.cv4 <- rbind(
#   fold2,
#   fold3, 
#   fold1, 
#   fold5, 
#   fold6, 
#   fold7, 
#   fold8, 
#   fold9, 
#   fold10
# )
# 
# #nowe we need the first covariate matrix and response vector
# 
# cov.mat4 <- as.matrix(df.cv4[, -1])
# response4 <- as.factor(df.cv4$Penalty)
# 
# #finally build mod1, hopefully it doesn't take forever since we need to do this 10 times
# 
# mod4 <- ordinalNet(
#   x = cov.mat4, 
#   y = response4, 
#   alpha = 1, 
#   lambdaVals = lambda[4], 
#   family = "cumulative", 
#   link = "logit", 
#   parallelTerms = T
# )
# 
# #test the model
# 
# preds4 <- tibble(
#   preds = predict(mod4, newx = as.matrix(fold4[, -1]), type = "class")) %>% 
#   mutate(preds = case_when(
#     preds == 1 ~ -1, 
#     preds == 2 ~ 0, 
#     preds == 3 ~ 1
#   ))
# obs4 <- as.factor(fold4[, 1])
# 
# postResample(preds4$preds, obs4) #accuracy: .908
# 
# ################################################################# fold 5
# 
# df.cv5 <- rbind(
#   fold2,
#   fold3, 
#   fold4, 
#   fold1, 
#   fold6, 
#   fold7, 
#   fold8, 
#   fold9, 
#   fold10
# )
# 
# #nowe we need the first covariate matrix and response vector
# 
# cov.mat5 <- as.matrix(df.cv5[, -1])
# response5 <- as.factor(df.cv5$Penalty)
# 
# #finally build mod1, hopefully it doesn't take forever since we need to do this 10 times
# 
# mod5 <- ordinalNet(
#   x = cov.mat5, 
#   y = response5, 
#   alpha = 1, 
#   lambdaVals = lambda[5], 
#   family = "cumulative", 
#   link = "logit", 
#   parallelTerms = T
# )
# 
# #test the model
# 
# preds5 <- tibble(
#   preds = predict(mod5, newx = as.matrix(fold5[, -1]), type = "class")) %>% 
#   mutate(preds = case_when(
#     preds == 1 ~ -1, 
#     preds == 2 ~ 0, 
#     preds == 3 ~ 1
#   ))
# obs5 <- as.factor(fold5[, 1])
# 
# postResample(preds5$preds, obs5) #accuracy: .898
# 
# ################################################################# fold 6
# 
# df.cv6 <- rbind(
#   fold2,
#   fold3, 
#   fold4, 
#   fold5, 
#   fold1, 
#   fold7, 
#   fold8, 
#   fold9, 
#   fold10
# )
# 
# #nowe we need the first covariate matrix and response vector
# 
# cov.mat6 <- as.matrix(df.cv6[, -1])
# response6 <- as.factor(df.cv6$Penalty)
# 
# #finally build mod1, hopefully it doesn't take forever since we need to do this 10 times
# 
# mod6 <- ordinalNet(
#   x = cov.mat6, 
#   y = response6, 
#   alpha = 1, 
#   lambdaVals = lambda[6], 
#   family = "cumulative", 
#   link = "logit", 
#   parallelTerms = T
# )
# 
# #test the model
# 
# preds6 <- tibble(
#   preds = predict(mod6, newx = as.matrix(fold6[, -1]), type = "class")) %>% 
#   mutate(preds = case_when(
#     preds == 1 ~ -1, 
#     preds == 2 ~ 0, 
#     preds == 3 ~ 1
#   ))
# obs6 <- as.factor(fold6[, 1])
# 
# postResample(preds6$preds, obs6) #accuracy: .903
# 
# ################################################################# fold 7
# 
# df.cv7 <- rbind(
#   fold2,
#   fold3, 
#   fold4, 
#   fold5, 
#   fold6, 
#   fold1, 
#   fold8, 
#   fold9, 
#   fold10
# )
# 
# #nowe we need the first covariate matrix and response vector
# 
# cov.mat7 <- as.matrix(df.cv7[, -1])
# response7 <- as.factor(df.cv7$Penalty)
# 
# #finally build mod1, hopefully it doesn't take forever since we need to do this 10 times
# 
# mod7 <- ordinalNet(
#   x = cov.mat7, 
#   y = response7, 
#   alpha = 1, 
#   lambdaVals = lambda[7], 
#   family = "cumulative", 
#   link = "logit", 
#   parallelTerms = T
# )
# 
# #test the model
# 
# preds7 <- tibble(
#   preds = predict(mod7, newx = as.matrix(fold7[, -1]), type = "class")) %>% 
#   mutate(preds = case_when(
#     preds == 1 ~ -1, 
#     preds == 2 ~ 0, 
#     preds == 3 ~ 1
#   ))
# obs7 <- as.factor(fold7[, 1])
# 
# postResample(preds7$preds, obs7) #accuracy: .901
# 
# ################################################################# fold 8
# 
# df.cv8 <- rbind(
#   fold2,
#   fold3, 
#   fold4, 
#   fold5, 
#   fold6, 
#   fold7, 
#   fold1, 
#   fold9, 
#   fold10
# )
# 
# #nowe we need the first covariate matrix and response vector
# 
# cov.mat8 <- as.matrix(df.cv8[, -1])
# response8 <- as.factor(df.cv8$Penalty)
# 
# #finally build mod1, hopefully it doesn't take forever since we need to do this 10 times
# 
# mod8 <- ordinalNet(
#   x = cov.mat8, 
#   y = response8, 
#   alpha = 1, 
#   lambdaVals = lambda[8], 
#   family = "cumulative", 
#   link = "logit", 
#   parallelTerms = T
# )
# 
# #test the model
# 
# preds8 <- tibble(
#   preds = predict(mod8, newx = as.matrix(fold8[, -1]), type = "class")) %>% 
#   mutate(preds = case_when(
#     preds == 1 ~ -1, 
#     preds == 2 ~ 0, 
#     preds == 3 ~ 1
#   ))
# obs8 <- as.factor(fold8[, 1])
# 
# postResample(preds8$preds, obs8) #accuracy: .903
# 
# ################################################################# fold 9
# 
# df.cv9 <- rbind(
#   fold2,
#   fold3, 
#   fold4, 
#   fold5, 
#   fold6, 
#   fold7, 
#   fold8, 
#   fold1, 
#   fold10
# )
# 
# #nowe we need the first covariate matrix and response vector
# 
# cov.mat9 <- as.matrix(df.cv9[, -1])
# response9 <- as.factor(df.cv9$Penalty)
# 
# #finally build mod1, hopefully it doesn't take forever since we need to do this 10 times
# 
# mod9 <- ordinalNet(
#   x = cov.mat9, 
#   y = response9, 
#   alpha = 1, 
#   lambdaVals = lambda[9], 
#   family = "cumulative", 
#   link = "logit", 
#   parallelTerms = T
# )
# 
# #test the model
# 
# preds9 <- tibble(
#   preds = predict(mod9, newx = as.matrix(fold9[, -1]), type = "class")) %>% 
#   mutate(preds = case_when(
#     preds == 1 ~ -1, 
#     preds == 2 ~ 0, 
#     preds == 3 ~ 1
#   ))
# obs9 <- as.factor(fold9[, 1])
# 
# postResample(preds9$preds, obs9) #accuracy: .895
# 
# ################################################################# fold 10
# 
# df.cv10 <- rbind(
#   fold2,
#   fold3, 
#   fold4, 
#   fold5, 
#   fold6, 
#   fold7, 
#   fold8, 
#   fold9, 
#   fold1
# )
# 
# #nowe we need the first covariate matrix and response vector
# 
# cov.mat10 <- as.matrix(df.cv10[, -1])
# response10 <- as.factor(df.cv10$Penalty)
# 
# #finally build mod1, hopefully it doesn't take forever since we need to do this 10 times
# 
# mod10 <- ordinalNet(
#   x = cov.mat10, 
#   y = response10, 
#   alpha = 1, 
#   lambdaVals = lambda[10], 
#   family = "cumulative", 
#   link = "logit", 
#   parallelTerms = T
# )
# 
# #test the model
# 
# preds10 <- tibble(
#   preds = predict(mod10, newx = as.matrix(fold10[, -1]), type = "class")) %>% 
#   mutate(preds = case_when(
#     preds == 1 ~ -1, 
#     preds == 2 ~ 0, 
#     preds == 3 ~ 1
#   ))
# obs10 <- as.factor(fold10[, 1])
# 
# postResample(preds10$preds, obs10) #accuracy: .900

################################################################# build the model with the best lam on full data

#lets also check all the AICs

# mod1$aic
# mod2$aic
# mod3$aic
# mod4$aic
# mod5$aic
# mod6$aic
# mod7$aic
# mod8$aic
# mod9$aic
# mod10$aic

#alright since all the accuracies are about the same we are going to ride with AIC too, that means we choose
#lam9 as the best one since it has the lowest AIC

#ok that's fine lets build the model with that lam on the full set

cov.mat.final <- as.matrix(Regress.df[, -1])
response.final <- as.factor(Regress.df$Penalty)

mod.final <- ordinalNet(
  x = cov.mat.final, 
  y = response.final, 
  alpha = 1, 
  lambdaVals = lambda[2], 
  family = "cumulative", 
  link = "logit", 
  parallelTerms = T
)

print("10 fold CV Regression Complete")

#then we can finally get the coefficients and we're guna save them as a data frame because we'll build all the plots
#in a different script

#alright we'll we have a problem, turns out the penalites get too high after mod2 and everything becomes 0...
#thats fine, lets just pick between them 2, mode 2 has a lower AIC and higher accuracy, that's the one we'll use

orderd.coefs.ordinal <- na.omit(tibble(
  nflId = as.numeric(gsub("`","", names(sort(coef(mod.final), decreasing = T)))), 
  Contribution = as.numeric(sort(coef(mod.final), decreasing = T))
))

#and finallly lets save this as a csv so we can do the plots somewhere else, the plots and procedure
#will be the same as the EPA model

write.csv(orderd.coefs.ordinal, "Derived_Data/ordinal.regression.coefs.csv", row.names = F)

print("Coefficient Data Saved")