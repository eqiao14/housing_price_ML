##### Random Forest practice ####
library(reshape2)
library(ggplot2)
library(boot)
library(dplyr)
library(boot)
library(randomForest)
library(xgboost)
library(corrplot)
library(rms)
library(car) 


train = read.csv('/Users/eqiao14/Desktop/Rpractice/housing/train.csv')
test = read.csv('test.csv')

# train = read.csv("C:/Users/Edmund/Desktop/housing/train.csv")
# test = read.csv("C:/Users/Edmund/Desktop/housing/test.csv")

head(train)
attach(train)

trained = train[c('Id','LotArea', 'LandContour','Neighborhood','BldgType','HouseStyle',
                  'OverallCond','YearBuilt','YearRemodAdd', 'ExterCond', 'TotalBsmtSF','BsmtFinSF1',
                  'BsmtFinType1', 'X1stFlrSF', 'X2ndFlrSF','GrLivArea', 'BsmtFullBath', 'BsmtHalfBath',
                  'FullBath','HalfBath','BedroomAbvGr','KitchenAbvGr', 'KitchenQual', 'GarageArea', 
                  'GarageCond', 'EnclosedPorch',
                  'GarageCars','WoodDeckSF','OpenPorchSF', 'TotRmsAbvGrd', 'Fireplaces',
                  'YrSold','SaleType','SaleCondition', 'SalePrice')]

trained = replace_na_mode(trained)

head(trained)
summary(trained)

colnames(train)

ggplot(data = melt(trained), mapping = aes(x = value)) + 
  geom_histogram(bins = 30) + facet_wrap(~variable, scales = 'free_x')

###Choose numeric vectors
numbers = which(sapply(train, is.numeric))
numbers_tbl = train[,numbers]

cor_numbers = cor(numbers_tbl, use="pairwise.complete.obs")

#sort on decreasing correlations with SalePrice
cor_sorted = as.matrix(sort(cor_numbers[,'SalePrice'], decreasing = TRUE))

#select only high corelations
CorHigh <- names(which(apply(cor_sorted, 1, function(x) abs(x)>0.5)))
cor_numVar <- cor_numbers[CorHigh, CorHigh]

corrplot.mixed(cor_numVar, tl.col="black", tl.pos = "lt")

numsaleprice = numbers_tbl[CorHigh]

###Data exploration for categorical variables

#create 2x2 plots
par(mfrow=c(2,2))

cats = train[,-numbers]

plot(cats[1], xlab  =names(cats[1]))

###saving old catsaleprice
# catsaleprice_holder = catsaleprice

catsaleprice = explorer(cats, c(2,2), train$SalePrice)
catsaleprice = cbind(catsaleprice, train$MiscFeature, train$SaleType, train$SaleCondition)
colnames(catsaleprice)[colnames(catsaleprice)=="train$MiscFeature"] <- "MiscFeature"
colnames(catsaleprice)[colnames(catsaleprice)=="train$SaleType"] <- "SaleType"
colnames(catsaleprice)[colnames(catsaleprice)=="train$SaleCondition"] <- "SaleCondition"

catsaleprice = cbind(catsaleprice, as.factor(train$MoSold))
colnames(catsaleprice)[colnames(catsaleprice)=="as.factor(train$MoSold)"] <- "MoSold"

##Deal with categorical NAs, mostly replacing w/ mode or deleting if majority NA
summary(catsaleprice)
catsaleprice$MasVnrType = replace_na_mode(catsaleprice$MasVnrType)
catsaleprice$BsmtCond = replace_na_mode(catsaleprice$BsmtCond)
catsaleprice$BsmtQual = replace_na_mode(catsaleprice$BsmtQual)
catsaleprice$BsmtFinType1 = replace_na_mode(catsaleprice$BsmtFinType1)
catsaleprice$BsmtFinType2 = replace_na_mode(catsaleprice$BsmtFinType2)
catsaleprice$BsmtExposure = replace_na_mode(catsaleprice$BsmtExposure)
catsaleprice$Electrical = replace_na_mode(catsaleprice$Electrical)
catsaleprice$GarageType = replace_na_mode(catsaleprice$GarageType)
catsaleprice$GarageCond = replace_na_mode(catsaleprice$GarageCond)
catsaleprice$GarageQual = replace_na_mode(catsaleprice$GarageQual)
catsaleprice$GarageFinish = replace_na_mode(catsaleprice$GarageFinish)
catsaleprice$Alley=NULL
catsaleprice$Utilities=NULL
catsaleprice$FireplaceQu = NULL
catsaleprice$PoolQC = NULL

levels = levels(catsaleprice$Fence)
levels[length(catsaleprice$Fence) + 1] <- "None"

# refactor Species to include "None" as a factor level
# and replace NA with "None"
catsaleprice$Fence = factor(catsaleprice$Fence, levels = levels)
catsaleprice$Fence[is.na(catsaleprice$Fence)] = "None"

levels = levels(catsaleprice$MiscFeature)
levels[length(catsaleprice$MiscFeature) + 1] <- "None"

# refactor Species to include "None" as a factor level
# and replace NA with "None"
catsaleprice$MiscFeature = factor(catsaleprice$MiscFeature, levels = levels)
catsaleprice$MiscFeature[is.na(catsaleprice$MiscFeature)] = "None"


##Replace basement NAs w/ other
# catsaleprice$BsmtCond[which(is.na(catsaleprice$BsmtCond))] = as.factor('other')


##Test colinearity of categorical variables w/ vif function 

# ##Introduce scaled numbers 07/21/19#####
# 
# numsaleprice = as.data.frame(cbind(train$SalePrice,train$YearBuilt, train$YearRemodAdd, train$GarageYrBlt,
#                      scale(numsaleprice[-c(1,10:12)])))
# 
# colnames(numsaleprice)[1] <- 'SalePrice'; colnames(numsaleprice)[2] <- 'YearBuilt'
# colnames(numsaleprice)[3] <- 'YearRemodAdd'; colnames(numsaleprice)[4] <- 'GarageYrBlt'

# ###Replace some NAs
# 
# numsaleprice$GarageYrBlt = replace_na_mode(numsaleprice$GarageYrBlt)
# numsaleprice$MasVnrArea = replace_na_avg(numsaleprice$MasVnrArea)
# numsaleprice$LotFrontage = NULL


#YearBuilt = numsaleprice$YearBuilt; numsaleprice = numsaleprice[,-which(colnames(numsaleprice) == 'YearBuilt')]


combined = cbind(numsaleprice,catsaleprice)

vif_model = lm(combined$SalePrice~., data=combined)
alias(vif_model)
###ElectrcalMix is perf colinear, will remove
combined$Electrical = NULL

vif_model = lm(combined$SalePrice~., data=combined)
car::vif(vif_model)

##VIF cats to remove: TotalBsmtSF = 8.7, Condition2 = 8.5, RoofMat1 = 9.4, Heating = 7.3
combined$GarageArea = NULL; 
combined$TotalBsmtSF = NULL; combined$Condition2 = NULL; combined$RoofMatl = NULL; combined$Heating = NULL

combined = split_data_table(combined)

#####unscaled model########

##Create the test data with same cats

##scaling insertion 07/21/19#####
# numnames = colnames(numsaleprice); numnames = numnames[-1]
# testnumscale = test[numnames]
# testnumscale = as.data.frame(cbind(test$YearBuilt, test$YearRemodAdd, test$GarageYrBlt,
#                                    scale(testnumscale[-c(9:11)])))
# 
# colnames(testnumscale)[1] <- 'YearBuilt'
# colnames(testnumscale)[2] <- 'YearRemodAdd'; colnames(testnumscale)[3] <- 'GarageYrBlt'
# 
# tested = cbind(testnumscale,test[,colnames(catsaleprice)])
# 
trainnames = colnames(cbind(numsaleprice, catsaleprice))
trainnames = trainnames[-1]

#YearBuilt = as.factor(YearBuilt)

tested = cbind(test[,trainnames])
tested$Electrical = NULL; tested$GarageArea = NULL; 
tested$TotalBsmtSF = NULL; tested$Condition2 = NULL; tested$RoofMatl = NULL; tested$Heating = NULL
summary(tested)

levels = levels(tested$Fence)
levels[length(tested$Fence) + 1] <- "None"

# refactor Species to include "None" as a factor level
# and replace NA with "None"
tested$Fence = factor(tested$Fence, levels = levels)
tested$Fence[is.na(tested$Fence)] = "None"

levels = levels(tested$MiscFeature)
levels[length(tested$MiscFeature) + 1] <- "None"

# refactor Species to include "None" as a factor level
# and replace NA with "None"
tested$MiscFeature = factor(tested$MiscFeature, levels = levels)
tested$MiscFeature[is.na(tested$MiscFeature)] = "None"

tested$MasVnrType = replace_na_mode(tested$MasVnrType)
tested$BsmtCond = replace_na_mode(tested$BsmtCond)
tested$BsmtQual = replace_na_mode(tested$BsmtQual)
tested$BsmtFinType1 = replace_na_mode(tested$BsmtFinType1)
tested$BsmtFinType2 = replace_na_mode(tested$BsmtFinType2)
tested$BsmtExposure = replace_na_mode(tested$BsmtExposure)
tested$GarageCond = replace_na_mode(tested$GarageCond)
tested$GarageQual = replace_na_mode(tested$GarageQual)
tested$GarageFinish = replace_na_mode(tested$GarageFinish)
tested$GarageCars = replace_na_mode(tested$GarageCars)
tested$GarageArea = replace_na_mode(tested$GarageArea) ##should have replaced w/ mean but it was only 1 value
tested$GarageYrBlt = replace_na_mode(tested$GarageYrBlt)
tested$MasVnrArea = replace_na_avg(tested$MasVnrArea)

tested$BsmtFinSF1 = replace_na_avg(tested$BsmtFinSF1)

tested$GarageType = replace_na_mode(tested$GarageType)
tested$KitchenQual = replace_na_mode(tested$KitchenQual)
tested$Exterior1st = replace_na_mode(tested$Exterior1st)
tested$TotalBsmtSF = replace_na_avg(tested$TotalBsmtSF)

##too many NAs in LotFrontage
combined$LotFrontage = NULL; tested$LotFrontage = NULL; 
tested$MSZoning = replace_na_mode(tested$MSZoning)
tested$Exterior2nd = replace_na_mode(tested$Exterior2nd)
tested$Functional = replace_na_mode(tested$Functional)
tested$SaleType = replace_na_mode(tested$SaleType)

###MoSold was later added in the catsaleprice, must change to factor here too
tested$MoSold = as.factor(tested$MoSold)
tested = split_data_table(tested)

####Make any illegal names legal
####ie years like '2008'
names(combined) = make.names(names(combined))
names(tested) = make.names(names(tested))

###Figure out which names are in the training and testing data in new splittables
trainingnames = sort(names(combined)); testingnames = sort(names(tested))
trainingnames[which(trainingnames %!in% testingnames)]

# BrkSide = rep(0,1459)
# ClyTile = rep(0,1459)
# Floor = rep(0,1459)
# Membran = rep(0,1459)
# Metal = rep(0,1459)
# OthW = rep(0,1459)
# Roll = rep(0,1459)
# RRAe = rep(0,1459)
# RRAn = rep(0,1459)
# RRNn = rep(0,1459)
Ex.5 =rep(0,1459)
Other = rep(0,1459)
TenC =rep(0,1459)
X2.5Fin = rep(0,1459)
SalePrice =rep(0,1459)

Ex.3 = rep(0,1459)
ImStucc.1 = rep(0,1459)
RRAe.1 = rep(0,1459)
RRAn.1 = rep(0,1459)
RRNn.1 = rep(0,1459)
Stone.2 = rep(0,1459)

x = cbind(tested, Ex.5, Other, TenC, X2.5Fin, SalePrice)

x = cbind(test, Ex.3, ImStucc.1, Other, RRAe.1, RRAn.1, RRNn.1, SalePrice, Stone.2, TenC, X2.5Fin)

clean_test = as.matrix(x)

clean_train = as.matrix(combined)
clean_test = as.matrix(tested)

y = as.data.frame(clean_train)

##Reordering dataframes
x = x[,order(names(x))]
y = y[,order(names(y))]


###Add missing columns to testing data 

rbind(x,y)

z = rbind (x,y)

which(z$SalePrice == 0)

a = z[1:1459,]
b = z[1460:nrow(z),]
a$SalePrice = NA 

clean_test = as.matrix(a); clean_train = as.matrix(b)

labels = b[,which(colnames(z) == 'SalePrice')]
clean_train = b[,-(which(colnames(z) == 'SalePrice'))]
clean_train = as.matrix(clean_train)
clean_test = a[,-(which(colnames(z) == 'SalePrice'))]
clean_test = as.matrix(clean_test)

dtrain = xgb.DMatrix(data = clean_train, label = labels)
dtest = xgb.DMatrix(data = clean_test)

model <- xgboost(data = dtrain, # the data   
                 nround = 500,  # max number of boosting iterations
                 early_stopping_rounds = 5
) 

pred = predict(model, dtest)

#Training error of 4336.48 correlates with error of 0.221 on the scoreboard

csv = as.data.frame(cbind(1461:2919, pred))
colnames(csv) = c('Id', 'SalePrice')

write.csv(csv, 'housing_predictions.csv')
