data {
  // training data
	int Total__ofTable__customer_class__asNumberOfDistinct__customer_class_id;
	int Total__ofTable__product__asNumberOfDistinct__product_id;
	int Total__ofTable__customer__asNumberOfDistinct__customer_id;
	int Total__ofTable__product_purchase__asNumberOfDistinct__product_purchase_id;
	int customer_class_id__asColumnOfTable__customer[Total__ofTable__customer__asNumberOfDistinct__customer_id];
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
  // priors
  theta__asColumnOfTable__customer_class ~ dirichlet(alpha__asColumnOfTable__customer_class);
  for (k in 1:Total__ofTable__customer_class__asNumberOfDistinct__customer_class_id)  
    phi__asColumnOfTable__customer_class_product[k] ~ dirichlet(beta__asColumnOfTable__product);
	
  // likelihood, including latent category
  for (m in 1:Total__ofTable__customer__asNumberOfDistinct__customer_id)
    customer_class_id__asColumnOfTable__customer[m] ~ categorical(theta__asColumnOfTable__customer_class);
  for (n in 1:Total__ofTable__product_purchase__asNumberOfDistinct__product_purchase_id)
    product_id__asColumnOfTable__product_purchase[n] ~ categorical(phi__asColumnOfTable__customer_class_product[customer_class_id__asColumnOfTable__customer[customer_id__asColumnOfTable__product_purchase[n]]]);
}