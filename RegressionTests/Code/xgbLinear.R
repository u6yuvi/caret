timestamp <- Sys.time()
library(caret)
library(xgboost)

model <- "xgbLinear"

#########################################################################

xgbGrid <- expand.grid(nrounds = c(1, 10),
                       lambda = c(.01, .1),
                       alpha = c(.01, .1),
                       eta = .3)

set.seed(2)
training <- twoClassSim(100, linearVars = 2)
testing <- twoClassSim(500, linearVars = 2)
trainX <- training[, -ncol(training)]
trainY <- training$Class

train_sparse <- xgb.DMatrix(as.matrix(trainX))

cctrl1 <- trainControl(method = "cv", number = 3, returnResamp = "all",
                       classProbs = TRUE, 
                       summaryFunction = twoClassSummary)
cctrl2 <- trainControl(method = "LOOCV",
                       classProbs = TRUE, summaryFunction = twoClassSummary)
cctrl3 <- trainControl(method = "oob")
cctrl4 <- trainControl(method = "none",
                       classProbs = TRUE, summaryFunction = twoClassSummary)
cctrlR <- trainControl(method = "cv", number = 3, returnResamp = "all", search = "random")

set.seed(849)
test_class_cv_model <- train(trainX, trainY, 
                             method = "xgbLinear", 
                             trControl = cctrl1,
                             metric = "ROC", 
                             preProc = c("center", "scale"),
                             tuneGrid = xgbGrid)

set.seed(849)
test_class_cv_model_sp <- train(train_sparse, trainY, 
                                method = "xgbLinear", 
                                trControl = cctrl1,
                                metric = "ROC", 
                                tuneGrid = xgbGrid)


set.seed(849)
test_class_cv_form <- train(Class ~ ., data = training, 
                            method = "xgbLinear", 
                            trControl = cctrl1,
                            metric = "ROC", 
                            preProc = c("center", "scale"),
                            tuneGrid = xgbGrid)

test_class_pred <- predict(test_class_cv_model, testing[, -ncol(testing)])
test_class_prob <- predict(test_class_cv_model, testing[, -ncol(testing)], type = "prob")
test_class_pred_form <- predict(test_class_cv_form, testing[, -ncol(testing)])
test_class_prob_form <- predict(test_class_cv_form, testing[, -ncol(testing)], type = "prob")

set.seed(849)
test_class_rand <- train(trainX, trainY, 
                         method = "xgbLinear", 
                         trControl = cctrlR,
                         tuneLength = 4)

set.seed(849)
test_class_loo_model <- train(trainX, trainY, 
                              method = "xgbLinear", 
                              trControl = cctrl2,
                              metric = "ROC", 
                              preProc = c("center", "scale"),
                              tuneGrid = xgbGrid)

set.seed(849)
test_class_none_model <- train(trainX, trainY, 
                               method = "xgbLinear", 
                               trControl = cctrl4,
                               tuneGrid = xgbGrid[nrow(xgbGrid),],
                               metric = "ROC", 
                               preProc = c("center", "scale"))
test_class_none_pred <- predict(test_class_none_model, testing[, -ncol(testing)])
test_class_none_prob <- predict(test_class_none_model, testing[, -ncol(testing)], type = "prob")

test_levels <- levels(test_class_cv_model)
if(!all(levels(trainY) %in% test_levels))
  cat("wrong levels")

#########################################################################

SLC14_1 <- function(n = 100) {
  dat <- matrix(rnorm(n*20, sd = 3), ncol = 20)
  foo <- function(x) x[1] + sin(x[2]) + log(abs(x[3])) + x[4]^2 + x[5]*x[6] + 
    ifelse(x[7]*x[8]*x[9] < 0, 1, 0) +
    ifelse(x[10] > 0, 1, 0) + x[11]*ifelse(x[11] > 0, 1, 0) + 
    sqrt(abs(x[12])) + cos(x[13]) + 2*x[14] + abs(x[15]) + 
    ifelse(x[16] < -1, 1, 0) + x[17]*ifelse(x[17] < -1, 1, 0) -
    2 * x[18] - x[19]*x[20]
  dat <- as.data.frame(dat)
  colnames(dat) <- paste0("Var", 1:ncol(dat))
  dat$y <- apply(dat[, 1:20], 1, foo) + rnorm(n, sd = 3)
  dat
}

set.seed(1)
training <- SLC14_1(75)
testing <- SLC14_1(100)
trainX <- training[, -ncol(training)]
trainY <- training$y
testX <- trainX[, -ncol(training)]
testY <- trainX$y 

train_sparse <- xgb.DMatrix(as.matrix(trainX))

rctrl1 <- trainControl(method = "cv", number = 3, returnResamp = "all")
rctrl2 <- trainControl(method = "LOOCV")
rctrl3 <- trainControl(method = "oob")
rctrl4 <- trainControl(method = "none")
rctrlR <- trainControl(method = "cv", number = 3, returnResamp = "all", search = "random")

set.seed(849)
test_reg_cv_model <- train(trainX, trainY, 
                           method = "xgbLinear", 
                           trControl = rctrl1,
                           preProc = c("center", "scale"),
                           tuneGrid = xgbGrid)
test_reg_pred <- predict(test_reg_cv_model, testX)

set.seed(849)
test_reg_cv_model_sp <- train(train_sparse, trainY, 
                              method = "xgbLinear", 
                              trControl = rctrl1,
                              tuneGrid = xgbGrid)
test_reg_pred_sp <- predict(test_reg_cv_model_sp, testX)


set.seed(849)
test_reg_cv_form <- train(y ~ ., data = training, 
                          method = "xgbLinear", 
                          trControl = rctrl1,
                          preProc = c("center", "scale"),
                          tuneGrid = xgbGrid)
test_reg_pred_form <- predict(test_reg_cv_form, testX)

set.seed(849)
test_reg_rand <- train(trainX, trainY, 
                       method = "xgbLinear", 
                       trControl = rctrlR,
                       tuneLength = 4)

set.seed(849)
test_reg_loo_model <- train(trainX, trainY, 
                            method = "xgbLinear",
                            trControl = rctrl2,
                            preProc = c("center", "scale"),
                            tuneGrid = xgbGrid)

set.seed(849)
test_reg_none_model <- train(trainX, trainY, 
                             method = "xgbLinear", 
                             trControl = rctrl4,
                             tuneGrid = xgbGrid[nrow(xgbGrid),],
                             preProc = c("center", "scale"))
test_reg_none_pred <- predict(test_reg_none_model, testX)

#########################################################################

test_class_predictors1 <- predictors(test_class_cv_model)
test_reg_predictors1 <- predictors(test_reg_cv_model)

#########################################################################

test_class_imp <- varImp(test_class_cv_model)
test_reg_imp <- varImp(test_reg_cv_model)

#########################################################################

tests <- grep("test_", ls(), fixed = TRUE, value = TRUE)

sInfo <- sessionInfo()
timestamp_end <- Sys.time()

save(list = c(tests, "sInfo", "timestamp", "timestamp_end"),
     file = file.path(getwd(), paste(model, ".RData", sep = "")))

if(!interactive()) q("no")


