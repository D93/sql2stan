#!/bin/bash

echo "So you've completed the model training workflow? This small script will help you classify a new customer"
echo "(example context: supervised naive Bayes for classifying sports shop customers)"
printf '\n\n'

read -p "Where is your trained classifier? Enter a database name (without special characters, and for the case sensitivity also double-quoted, e.g. \"supervisedNaiveBayes\"): " dbname_entered 

printf '\n\n'

read -p "Enter the products of interest of a customer to be classified (comma-separated, e.g. 1,2,3,4 ): " products_of_interest

printf '\n\n'

postgres_query="select
	customer_class_id, sum(log(phi))+log(theta) as log_probability
from
	customer_class_product
	join
	customer_class
	using (customer_class_id)
where
	product_id in ($products_of_interest)
group by
	customer_class_id,
	theta
order by 
	log_probability
desc
;" 

echo "Output: "
echo "the class in the first row is most likely to be the right for the customer interested in products ($products_of_interest)"
printf '\n\n'

psql -U sql2stan_user -d $dbname_entered -c "$postgres_query"

