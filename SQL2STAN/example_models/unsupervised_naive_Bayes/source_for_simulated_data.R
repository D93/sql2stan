# Author of the original data generator: 
# Bob Carpenter
# Source of the original data generator: 
# https://github.com/stan-dev/example-models/blob/master/misc/cluster/naive-bayes/sim-naive-bayes.R
# 
# Changed: some variable names 
#
# How to start:
# R CMD BATCH source_for_simulated_data.R


library('gtools')

skewed_simplex <- function(k) {
  result <- (1/(2:(1+k)))^2;
  result <- result / sum(result);
  return(result);
}

K <- 6; # number of customer classes
V <- 350; # number of products
theta <- skewed_simplex(K);
phi <- matrix(NA,nrow=K,ncol=V)
for (k in 1:K)
  phi[k,] <- permute(skewed_simplex(V));

M <- 100;  # number of customers involved in model training
avg_number_of_purchases_done_by_a_customer <- 5; # average number of product purchases per customer
number_of_purchases_done_by_a_customer <- rpois(M,avg_number_of_purchases_done_by_a_customer);
N <- sum(number_of_purchases_done_by_a_customer);  # number of purchases: one purchase = one product bought. 
# Our only interest when classifying customers: which products did a customer buy in our shop. 
# In this context, orders (how multiple products are brought together when bought in a single purchase) aren't relevant.

z <- rep(NA,M);
w <- rep(NA,N);
customer_purchases <- rep(NA,N);
n <- 1;
for (m in 1:M) {
  z[m] <- which(rmultinom(1,1,theta) == 1);
  for (i in 1:number_of_purchases_done_by_a_customer[m]) {
    w[n] <- which(rmultinom(1,1,phi[z[m],]) == 1);
    customer_purchases[n] <- m;
    n <- n + 1;
  }
}
alpha <- rep(1,K);
beta <- rep(0.1,V);  # prior count < 1 for products

dump(c("K","V","M","N","z","w","customer_purchases","alpha","beta"),file="sportsshop_customers_classifier.data.R");
