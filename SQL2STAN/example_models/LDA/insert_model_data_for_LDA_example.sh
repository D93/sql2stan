
# FILLING THE TABLES WITH DATA for "latent Dirichlet allocation (LDA)" EXAMPLE:
# use the following commands to import the DB dump with the needed table data.
# Remark: cannot use a text file with COPY commands because "sql2stan_user" isn't a superuser.
#

read -p "To fill the database tables for the \"latent Dirichlet allocation (LDA)\" example with data, enter a database name for this SQL2STAN project (without special characters, and for the case sensitivity also double-quoted, e.g. \"LDA\"): " dbname_entered 
	
	cd example_models/LDA
	psql -U sql2stan_user -d $dbname_entered -c "\copy document(document_id) FROM 'LDA_DB_DUMP/DUMP_document.csv' DELIMITER ',' CSV HEADER;"
	psql -U sql2stan_user -d $dbname_entered -c "\copy word(word_id) FROM 'LDA_DB_DUMP/DUMP_word.csv' DELIMITER ',' CSV HEADER;"
	psql -U sql2stan_user -d $dbname_entered -c "\copy token(token_id) FROM 'LDA_DB_DUMP/DUMP_token.csv' DELIMITER ',' CSV HEADER;"
	psql -U sql2stan_user -d $dbname_entered -c "\copy topic(topic_id,alpha) FROM 'LDA_DB_DUMP/DUMP_topic.csv' DELIMITER ',' CSV HEADER;"
	psql -U sql2stan_user -d $dbname_entered -c "\copy document_token_topic(token_id,document_id) FROM 'LDA_DB_DUMP/DUMP_document_token_topic.csv' DELIMITER ',' CSV HEADER;"
	psql -U sql2stan_user -d $dbname_entered -c "\copy document_token_word(word_id,token_id,document_id) FROM 'LDA_DB_DUMP/DUMP_document_token_word.csv' DELIMITER ',' CSV HEADER;"
	psql -U sql2stan_user -d $dbname_entered -c "\copy document_topic(document_id,topic_id) FROM 'LDA_DB_DUMP/DUMP_document_topic.csv' DELIMITER ',' CSV HEADER;"
	psql -U sql2stan_user -d $dbname_entered -c "\copy topic_word(topic_id,word_id,beta) FROM 'LDA_DB_DUMP/DUMP_topic_word.csv' DELIMITER ',' CSV HEADER;"
	cd ../..


# DB USER PRIVILEGES, a TROUBLESHOOTING REMARK: 
# If the user "sql2stan_user" doesn't have the right privileges to work on tables, you may try this:
# 1) log in as you original Uni system user (has to be in the sudoer group): 
# 	su - USERNAME
# 2) Grant some privileges to "sql2stan_user" in the Postgresql system:
# sudo -u postgres psql -c "GRANT CONNECT ON DATABASE $dbname_entered TO sql2stan_user"
# sudo -u postgres psql -c "GRANT USAGE ON SCHEMA public TO sql2stan_user"
# sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO sql2stan_user"
