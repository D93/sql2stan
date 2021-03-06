data {
int Total__ofTable__customer_class__asNumberOfDistinct__customer_class_id;
int Total__ofTable__product__asNumberOfDistinct__product_id;
int Total__ofTable__customer__asNumberOfDistinct__customer_id;
int Total__ofTable__product_purchase__asNumberOfDistinct__product_purchase_id;
int Total__ofTable__customer_class_product__asNumberOfDistinct__customer_class_id;
int Total__ofTable__customer_class_product__asNumberOfDistinct__product_id;
int customer_class_id__asColumnOfTable__customer_class[Total__ofTable__customer_class__asNumberOfDistinct__customer_class_id];
int product_id__asColumnOfTable__product[Total__ofTable__product__asNumberOfDistinct__product_id];
int customer_id__asColumnOfTable__customer[Total__ofTable__customer__asNumberOfDistinct__customer_id];
int product_purchase_id__asColumnOfTable__product_purchase[Total__ofTable__product_purchase__asNumberOfDistinct__product_purchase_id];
int customer_id__asColumnOfTable__product_purchase[Total__ofTable__product_purchase__asNumberOfDistinct__product_purchase_id];
int product_id__asColumnOfTable__product_purchase[Total__ofTable__product_purchase__asNumberOfDistinct__product_purchase_id];
int customer_class_id__asColumnOfTable__customer_class_product[Total__ofTable__customer_class_product__asNumberOfDistinct__customer_class_id,Total__ofTable__customer_class_product__asNumberOfDistinct__product_id];
int product_id__asColumnOfTable__customer_class_product[Total__ofTable__customer_class_product__asNumberOfDistinct__customer_class_id,Total__ofTable__customer_class_product__asNumberOfDistinct__product_id];
vector[Total__ofTable__customer_class__asNumberOfDistinct__customer_class_id] alpha__asColumnOfTable__customer_class;
vector[Total__ofTable__product__asNumberOfDistinct__product_id] beta__asColumnOfTable__product;
}
parameters {
simplex[Total__ofTable__customer_class__asNumberOfDistinct__customer_class_id] theta__asColumnOfTable__customer_class;
simplex[Total__ofTable__customer_class_product__asNumberOfDistinct__product_id] phi__asColumnOfTable__customer_class_product[Total__ofTable__customer_class_product__asNumberOfDistinct__customer_class_id];
}
model {
real gamma__for__customer_class_id__asColumnOfTable__customer_class[Total__ofTable__customer__asNumberOfDistinct__customer_id,Total__ofTable__customer_class__asNumberOfDistinct__customer_class_id];
target += dirichlet_lpdf(theta__asColumnOfTable__customer_class|alpha__asColumnOfTable__customer_class);
for (a in 1:Total__ofTable__customer_class__asNumberOfDistinct__customer_class_id) {
target += dirichlet_lpdf(phi__asColumnOfTable__customer_class_product[a]|beta__asColumnOfTable__product);
}
for (a in 1:Total__ofTable__customer__asNumberOfDistinct__customer_id) {
for (b in 1:Total__ofTable__customer_class__asNumberOfDistinct__customer_class_id) {
gamma__for__customer_class_id__asColumnOfTable__customer_class[a,b] = categorical_lpmf(b|theta__asColumnOfTable__customer_class);
}
}

for (a in 1:Total__ofTable__product_purchase__asNumberOfDistinct__product_purchase_id) {
for (b in 1:Total__ofTable__customer_class__asNumberOfDistinct__customer_class_id) {
gamma__for__customer_class_id__asColumnOfTable__customer_class[customer_id__asColumnOfTable__product_purchase[a],b] = gamma__for__customer_class_id__asColumnOfTable__customer_class[customer_id__asColumnOfTable__product_purchase[a],b] + categorical_lpmf(product_id__asColumnOfTable__product_purchase[a]|phi__asColumnOfTable__customer_class_product[b]);
}
}



for (a in 1:Total__ofTable__customer__asNumberOfDistinct__customer_id) {
target += log_sum_exp(gamma__for__customer_class_id__asColumnOfTable__customer_class[a]);
}
}
