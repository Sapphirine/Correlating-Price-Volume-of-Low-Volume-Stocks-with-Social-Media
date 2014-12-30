#Jeff Ho
#General purpose data manipulation for finding leading indicators
#Data processing: Raw data -> Expand data -> Visualize data -> Feature Selection -> Naive Bayes classifier -> Strategy


expand <- function( raw_data )
{ 
  expand_data <- matrix( data=NA, nrow = nrow(raw_data), ncol = 3*n_features+1 )
  
  for( i in 1:nrow(raw_data))
  {
    expand_data[i,1] = raw_data[i,1]
  } 
  
  for( n in 1:(n_features) )
  {
    for( k in 1:3 )
    {
      for( i in 1:nrow(raw_data))
      {
        expand_data[i,n*3+k-2]=raw_data[i,n+1]
      }
    }     
  }
  
  
  for( n in 2:(3*n_features+1) )
  {      
    move=(n-1) %% 3
    
    if( move == 1)
    {
      expand_data[,n]=c(NA, expand_data[1:(nrow(raw_data)-1),n]) 
    }
    if( move == 2)
    {
      expand_data[,n]=c(NA, NA, expand_data[1:(nrow(raw_data)-2),n])    
    }
    if( move == 0)
    {
      expand_data[,n]=c(NA, NA, NA, expand_data[1:(nrow(raw_data)-3),n])    
    }
    
  }
  
  
  expand_data=expand_data[-c(1,2,3),] 
  expand_data = data.frame(expand_data)
  attach(expand_data)
  colnames(expand_data) <- c("y", colnames(expand_data)[1:(ncol(expand_data)-1)])
  
  
  return( expand_data )
}



plot_data <- function( expand_data )
{
  par(mfrow=c((ncol(expand_data)+1)/3, 3))
  
  for( n in 2:ncol(expand_data) )
  {
    plot( expand_data[,n], expand_data[,1], xlab=c("feature",(n-1)), ylab="label" )  
  }  
}




features <- function( expand_data )
{
  features <- c(1)
  
  model_features = as.numeric (readline(prompt="How many features you are gonna put in the model?"))
  for( i in 1:model_features)
  {
    x <- as.numeric (readline(prompt="What features are in the model? (Enter: 1, 2, 3...; enter 0 to end )"))
    
    features = cbind( features, x+1 )
  }
  select_data = expand_data[,features]
  
  return( select_data )
}


naive_bayes <- function( select_data, seed )
{
  
  for(i in 1:nrow(select_data))
  {
    
    if( as.numeric(select_data[i,1]) > 0 )
    {
      select_data[i,1]="abnormal"   
    }
    else
    {
      select_data[i,1]="normal"    
    }
  }
  
  print("Labled data:")
  print( select_data )
  cat("\n")
  
  #split the data into train(0.8) and test(0.2)
  smp_size <- floor(0.8 * nrow(select_data))
  
  set.seed(seed)
  train_ind <- sample(seq_len(nrow(select_data)), size = smp_size)
  
  train <- select_data[train_ind, ]
  test <- select_data[-train_ind, ]
  
  rownames(train) <- NULL
  rownames(test) <- NULL
  
  print("Train data:")
  print(train)
  cat("\n")
  print("Test data:")
  print(test)
  cat("\n")
  cat("\n")
  
  
  #Running Naive Bayes classifier
  library(e1071)
  
  model <- naiveBayes(as.factor(y) ~ ., data = train)
  print(model)
  
  print("Train result:")
  pred_train = predict( model, train )
  print( pred_train )
  cat("\n")
  print( table(pred_train, train[,1]) )
  cat("\n")
  
  
  print("Test result:")
  pred_test = predict( model, test )
  print( pred_test )
  cat("\n")
  print( table(pred_test, test[,1]) )
  cat("\n")
  
}





#Read data
raw_data <- read.csv("/Users/Jeff/Desktop/BigDataProject/Run/raw_data.csv", header=TRUE)
print(raw_data)
n_features = ncol(raw_data) - 1


#Expand data to -1, -2, and -3 periods
expand_data = expand( raw_data )
print(expand_data)


#Plot data
plot_data( expand_data )


#Select features into the model according to the plots
select_data = features( expand_data )
print(select_data)


#Perform naive bayes classifier
naive_bayes( select_data, seed=123 )



#END
