data {
  // training data
	int Total__ofTable__customer_class__asNumberOfDistinct__customer_class_id;
	int Total__ofTable__product__asNumberOfDistinct__product_id;
	int Total__ofTable__customer__asNumberOfDistinct__customer_id;
	int Total__ofTable__product_purchase__asNumberOfDistinct__product_purchase_id;
	int product_id__asColumnOfTable__product_purchase[Total__ofTable__product_purchase__asNumberOfDistinct__product_purchase_id];
	int customer_id__asColumnOfTable__product_purchase[Total__ofTable__product_purchase__asNumberOfDistinct__product_purchase_id];
  // hyperparameters
	vector[Total__ofTable__customer_class__asNumberOfDistinct__customer_class_id] alpha__asColumnOfTable__customer_class;
	vector[Total__ofTable__product__asNumberOfDistinct__product_id] beta__asColumnOfTable__product;
}
parameters {
	simplex[Total__ofTable__customer_class__asNumberOfDistinct__customer_class_id] theta__asColumnOfTable__customer_class;
	simplex[Total__ofTable__product__asNumberOfDistinct__product_id] phi__asColumnOfTable__customer_class_product[Total__ofTable__customer_class__asNumberOfDistinct__customer_class_id];
}
model {
	real gamma[Total__ofTable__customer__asNumberOfDistinct__customer_id,Total__ofTable__customer_class__asNumberOfDistinct__customer_class_id];
	
	theta__asColumnOfTable__customer_class ~ dirichlet(alpha__asColumnOfTable__customer_class);
	
	for (k in 1:Total__ofTable__customer_class__asNumberOfDistinct__customer_class_id)  
		phi__asColumnOfTable__customer_class_product[k] ~ dirichlet(beta__asColumnOfTable__product);
	
	for (m in 1:Total__ofTable__customer__asNumberOfDistinct__customer_id)
		for (k in 1:Total__ofTable__customer_class__asNumberOfDistinct__customer_class_id)  
			gamma[m,k] <- categorical_log(k,theta__asColumnOfTable__customer_class);
	
	for (n in 1:Total__ofTable__product_purchase__asNumberOfDistinct__product_purchase_id)
		for (k in 1:Total__ofTable__customer_class__asNumberOfDistinct__customer_class_id) 
			gamma[customer_id__asColumnOfTable__product_purchase[n],k] <- gamma[customer_id__asColumnOfTable__product_purchase[n],k] 
                          + categorical_log(product_id__asColumnOfTable__product_purchase[n],phi__asColumnOfTable__customer_class_product[k]);
	
	for (m in 1:Total__ofTable__customer__asNumberOfDistinct__customer_id)
		increment_log_prob(log_sum_exp(gamma[m]));
}