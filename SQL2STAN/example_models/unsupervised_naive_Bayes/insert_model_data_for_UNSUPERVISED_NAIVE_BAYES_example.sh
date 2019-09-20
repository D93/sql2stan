
# FILLING THE TABLES WITH DATA for "unsupervised naive Bayes" EXAMPLE:
# use the following commands to import the DB dump with the needed table data.
# Remark: cannot use a text file with COPY commands because "sql2stan_user" isn't a superuser.
#

read -p "To fill the database tables for the \"unsupervised naive Bayes\" example with data, enter a database name for this SQL2STAN project (without special characters, and for the case sensitivity also double-quoted, e.g. \"unsupervisedNaiveBayes\"): " dbname_entered 

	cd example_models/unsupervised_naive_Bayes
	psql -U sql2stan_user -d $dbname_entered -c "\copy customer_class(customer_class_id,alpha) FROM 'unsupervisedNaiveBayes_DB_DUMP/DUMP_customer_class.csv' DELIMITER ',' CSV HEADER;"
	psql -U sql2stan_user -d $dbname_entered -c "\copy product(product_id,beta) FROM 'unsupervisedNaiveBayes_DB_DUMP/DUMP_product.csv' DELIMITER ',' CSV HEADER;"
	psql -U sql2stan_user -d $dbname_entered -c "\copy customer(customer_id) FROM 'unsupervisedNaiveBayes_DB_DUMP/DUMP_customer.csv' DELIMITER ',' CSV HEADER;"
	psql -U sql2stan_user -d $dbname_entered -c "\copy product_purchase(product_purchase_id,customer_id,product_id) FROM 'unsupervisedNaiveBayes_DB_DUMP/DUMP_product_purchase.csv' DELIMITER ',' CSV HEADER;"
	psql -U sql2stan_user -d $dbname_entered -c "\copy customer_class_product(customer_class_id,product_id) FROM 'unsupervisedNaiveBayes_DB_DUMP/DUMP_customer_class_product.csv' DELIMITER ',' CSV HEADER;"
	cd ../..


# DB USER PRIVILEGES, a TROUBLESHOOTING REMARK: 
# If the user "sql2stan_user" doesn't have the right privileges to work on tables, you may try this:
# 1) log in as you original Uni system user (has to be in the sudoer group): 
# 	su - USERNAME
# 2) Grant some privileges to "sql2stan_user" in the Postgresql system:
# sudo -u postgres psql -c "GRANT CONNECT ON DATABASE $dbname_entered TO sql2stan_user"
# sudo -u postgres psql -c "GRANT USAGE ON SCHEMA public TO sql2stan_user"
# sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO sql2stan_user"
