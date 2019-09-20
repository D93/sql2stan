#!/bin/bash
# the folder "SQL2STAN" has to be in the same parent directory as "libpg_query"!

#
# BEFORE YOU START!
# (assuming, you are now in the SQL2STAN directory):
#
# 0.1) Give needed permissions to work on the SQL2STAN directory content to the Unix user "sql2stan_user"  
# 	Two shell commands (execute as superuser, not as sql2stan_user; execute in the SQL2STAN directory): 	
#		sudo setfacl -R -d -m u:sql2stan_user:rwx .
#		sudo setfacl -R    -m u:sql2stan_user:rwx .
#		sudo setfacl -R -d -m u:sql2stan_user:rwx ../cmdstan-2.18.0
#		sudo setfacl -R    -m u:sql2stan_user:rwx ../cmdstan-2.18.0

# 0.2) Check, which Unix system user account you are currently working with. 
# 	Shell command: 	
#		whoami 
# 0.3) Now you have switch to your SQL2STAN Unix system account ("sql2stan_user"). 
# 	You will be asked for a password for it; type in the password you used when installing SQL2STAN.
# 	Shell command: 	
#		su - sql2stan_user
# 0.4) Go to you SQL2STAN directory. Please swap the "YOUR_ORIGINAL_SYSTEM_ACCOUNT_NAME" with the Unix user name from step 1.
# 	Shell command: 	
#		cd ../YOUR_ORIGINAL_SYSTEM_ACCOUNT_NAME/SQL2STAN


# HOW TO USE: 
# (assuming, you are now in the SQL2STAN directory)
#
# 0) Give needed permissions to work on the SQL2STAN directory content to the Unix user "sql2stan_user" and log in as "sql2stan_user" (see above in the "BEFORE YOU START" part).
# 1) Place your CREATE TABLE files (one for each table) into the subdirectory "createTable".
# 	Important note: place the topological order numbers in front of file names! Only then table dependencies can be recreated properly. 
# 	HINT: if you try out the model examples, use these shell commands to load the statements:
#		- for LDA example:
#			rm createTable/*
#			cp example_models/LDA/createTable/* createTable/
#		- for supervised naive Bayes example:
#			rm createTable/*
#			cp example_models/supervised_naive_Bayes/createTable/* createTable/
# 2) Place you log likelihood sum SQL statement into the subdirectory "logLikelihood".
# 	HINT: if you try out the model examples, use these shell commands to load the statements:
#		- for LDA example:
#			rm logLikelihood/*
#			cp example_models/LDA/logLikelihood/* logLikelihood/
#		- for supervised naive Bayes example:
#			rm logLikelihood/*
#			cp example_models/supervised_naive_Bayes/logLikelihood/* logLikelihood/
# 3) Start with script: ./start_workflow.sh 
# 4) Put the model data into your database tables. 
# 	HINT: if you try out the model examples, use a script which loads the example data into your DB:
#		- for LDA example:
#			example_models/LDA/insert_model_data_for_LDA_example.sh
#		- for supervised naive Bayes example:
#			example_models/supervised_naive_Bayes/insert_model_data_for_SUPERVISED_NAIVE_BAYES_example.sh
# 5) Continue with the script: ./continue_workflow.sh 
#
# optional, but could be important for integration SQL2Stan into another project: 
# accessing CREATE TABLE statements (among other infos) with the additional information after the workflow ended: 
# pg_dump -U sql2stan_user -d DATABASE_NAME_YOU_USED -s


echo 'Workflow started!' 
echo 'Please make sure you are logged in as SQL2STAN Unix system account "sql2stan_user".' 
echo 'Be sure you followed the directions in the "before you start" part (see the beginning of the file "start_workflow.sh").'


#################################
# PARSE CREATE TABLE STATEMENTS:
#################################
# parsing "CREATE TABLE" statements (one query in each *.sql) in the directory "createTable".
printf '\n\n'
echo "Now parsing CREATE TABLE statements..."
DIR="createTable"

# BEFORE PARSING: remove all the created files from the last code generation:
# remove SQL code text (*.txt) that was preprocessed for inserting into C code snippets  
rm ./createTable/*.txt
# 
rm ./createTable/CREATE_TABLE_statements_for_PostgreSQL_DB.sql
#
rm ./createTable/specific_types_and_functions_for_PostgreSQL_DB.sql

# remove C code for creating parse trees (*.C)
rm ./code_for_libpg_query/createTable/*
# remove parse trees (*.JSON)
rm ./parse_trees/createTable/*


# SQL code text (*.txt) that was preprocessed for inserting into C code snippets. 
# Preprocess the SQL statements for parsing:  
# 1) delete SQL comments from source files 
# 2) escape double quote characters 
# 3) replace tab characters with whitespaces
# 4) replace line breaks with whitespaces 
# 5) double quotes at the beginning and at the end 
for i in $DIR/*.sql; do ( sed 's/--.*$//g' $i | sed -e '/\-\-/d' | sed -e 's/"/\\"/g' | tr -s '\t' ' ' | tr -d "\r" |  tr -d "\n" | sed -e '1s/^/" /' | sed '$s/$/&\"/' > "$DIR/""$(basename $i)""_preprocessed_query".txt ) ; done

# Merge all the POSTGRES compliant CREATE TABLE statements to one single text file:
# 1) delete SQL comments from source files 
# 2) escape double quote characters 
# 3) replace tab characters with whitespaces
# 4) replace line breaks with whitespaces 
# 5) append it to a text file
for i in $DIR/*.sql; do ( if [ "$i" == "CREATE_TABLE_statements_for_PostgreSQL_DB.sql" ] ; then continue; fi ; sed 's/--.*$//g' $i | sed -e '/\-\-/d' | sed -e 's/"/\\"/g' | tr -s '\t' ' ' | tr -d "\r" |  tr -d "\n" >> $DIR/CREATE_TABLE_statements_for_PostgreSQL_DB.sql ) ; done

# Make a "code sandwich" in order to generate a C file which parses the SQL code:
for k in $DIR/*_preprocessed_query.txt; do ( cat codeTemplates/C_file_genPart_1.txt $k codeTemplates/C_file_genPart_2.txt > code_for_libpg_query/createTable/"$(basename $k)""__C_code_for_SQL_parsing".c ) ; done

# Parse the SQL code:
for l in code_for_libpg_query/createTable/*__C_code_for_SQL_parsing.c; do (cc -I../libpg_query -L../libpg_query $l -lpg_query ; ./a.out > parse_trees/createTable/"$(basename $l)""_parse_tree".json ) ; done

# Add Stan-specific user-defined dummy types and dummy functions:
echo 'CREATE OR REPLACE FUNCTION argument_column(argument text)
  RETURNS boolean AS 
$func$
   SELECT true;
$func$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION argument_table(argument text)
  RETURNS boolean AS 
$func$
   SELECT true;
$func$ LANGUAGE sql;

CREATE DOMAIN stan_parameter_int as INTEGER; 

CREATE DOMAIN stan_parameter_simplex_constrained as FLOAT; 

CREATE DOMAIN stan_parameter_real as FLOAT; 

CREATE DOMAIN stan_data_real as NUMERIC; 

' > $DIR/specific_types_and_functions_for_PostgreSQL_DB.sql

# You may've asked yourself about one detail above: 
# talking about the dummy types, why "CREATE DOMAIN" and not "CREATE TYPE"?
#
# The answer is simple: 
# such a domain doesn't need type casting when we want to import data.
# For example, we'd like to import numeric (non-integer) observable model data from a CSV file into out database table "topic" with columns "topic_id integer" and "alpha stan_data_real".
# We know for sure: the type "stan_data_real" is actually just a synonym for the "numeric" type, but PostgreSQL wouldn't know realize that even if we define a dummy type like that: 
# CREATE TYPE stan_data_real AS ( value NUMERIC ); 
# If we'd have created such a custom dummy type instead of a domain, we wouldn't be able to simply insert a row with values (1, 0.5) into the columns (topic_id,alpha). 
# The value 0.5 without any type cast would be seen by Postgres as a value of type NUMERIC, and not the type "stan_data_real" which is expected for the column "alpha" by the database system.
# So:
# Instead of implementing custom dummy type casts in addition to user-defined dummy data types, I just write handy "CREATE DOMAIN" one-liners which take care of the type problems. 


# remove temporary C output (*.out)
rm ./a.out

#################################
# PARSE LOG LIKELIHOOD SUM QUERY:
#################################
# parsing a model log likelihood sum query (one single query as *.sql) in the directory "logLikelihood".
printf '\n\n'
echo "Now parsing LOG LIKELIHOOD sum query..."
DIR="logLikelihood"

# BEFORE PARSING: remove all the created files from the last code generation:
# remove SQL code text (*.txt) that was preprocessed for inserting into C code snippets  
rm ./logLikelihood/*_preprocessed_query.txt
# remove C code for creating parse trees (*.C)
rm ./code_for_libpg_query/logLikelihood/*
# remove parse trees (*.JSON)
rm ./parse_trees/logLikelihood/*

# SQL code text (*.txt) that was preprocessed for inserting into C code snippets. 
# Preprocess the SQL statements for parsing:  
# 1) delete SQL comments from source files 
# 2) escape double quote characters 
# 3) replace tab characters with whitespaces
# 4) replace line breaks with whitespaces 
# 5) double quotes at the beginning and at the end 
for i in $DIR/*.sql; do ( sed -e '/\-\-/d' $i | sed -e 's/"/\\"/g' | tr -s '\t' ' ' | tr -d "\r\n" |  tr -d "\n" | sed -e '1s/^/" /' | sed '$s/$/&\"/' > "$DIR/""$(basename $i)""_preprocessed_query".txt ) ; done

for k in $DIR/*_preprocessed_query.txt; do ( cat codeTemplates/C_file_genPart_1.txt $k codeTemplates/C_file_genPart_2.txt > code_for_libpg_query/logLikelihood/"$(basename $k)""__C_code_for_SQL_parsing".c ) ; done

for l in code_for_libpg_query/logLikelihood/*__C_code_for_SQL_parsing.c; 
do 
	cc -I../libpg_query -L../libpg_query $l -lpg_query ; 
	./a.out > parse_trees/logLikelihood/"$(basename $l)""_parse_tree".json  ; 
done

# remove temporary C output (*.out)
rm ./a.out

#########################################
# CREATE "TOTAL" ENTRIES FOR STAN CODE
#########################################
# DEFITION of "total" in this context:
# TOTAL = variable for a number of distinct values in one primary key column of a table.
# Example: table "topic_word" has (topic_id,word_id) as a PK -> this table should have 2 totals 
# -> total for topic_id (number of distinct 'topic_id' values) and a total for word_id (number of distinct 'word_id' values).
# USE: as every data/parameter column will be an array or vector in Stan, we need "totals" to describe their dimensionality and size. 
printf '\n\n'
echo "Now creating Stan entries for 'TOTALS' (= numbers of distinct values in every primary key column of a table)..."

rm Stan_entries_collection/generated_total_entries.json
touch Stan_entries_collection/generated_total_entries.json

# create a dictionary with all the total entries derived from CREATE TABLE statements.
# Dictionary = a set of JSON entities, helps to look up some entries needed when translating from SQL to Stan. 
# We append dictionaries to parse trees in order to extend the available information. 
# Dictionary =/= valid JSON! If needed as a valid JSON, please put an opening square bracket at the beginning and closing square bracket at the end (like this: "[" ...dictionary... "]"). 
for m in parse_trees/createTable/*_parse_tree.json; do ( jfq --query-file codeTemplates/jfq_createTable_totals.txt $m >> Stan_entries_collection/generated_total_entries.json ) ; done

# remove empty lines with EOF chars at the end of the file and delete the last character (a comma) of the JSON file.
sed -i '/^$/d' Stan_entries_collection/generated_total_entries.json
truncate -s-2 Stan_entries_collection/generated_total_entries.json 

# ADD the "totals" dictionary to every single CREATE TABLE parse tree
for m in parse_trees/createTable/*_parse_tree.json; do {
	# delete some linebreaks before the EOF and remove the last ] character of the file.
	sed -i '/^$/d' $m  
	sed -i 's/\]$//' $m         
	# add a comma instead
	echo ',' >> $m
	# append the "totals" dictionary JSON data
	cat Stan_entries_collection/generated_total_entries.json >> $m
	# append the deleted last character (]) of the parse tree.
	echo ']' >> $m
} ; done


#########################################
# CREATE ARRAYS for INTEGER typed columns
#########################################
# INTEGER arrays consist of ID's for instances (e.g. topics, documents, words,...). 
printf '\n\n'
echo "Now creating Stan arrays/vectors for INTEGER typed columns..."

rm Stan_entries_collection/generated_integerCol_entries.json
touch Stan_entries_collection/generated_integerCol_entries.json

# Create a dictionary with all the integer array entries derived from CREATE TABLE statements.
# Dictionary = a set of JSON entities, helps to look up some entries needed when translating from SQL to Stan. 
# We append dictionaries to parse trees in order to extend the parse trees with the new available information. 
# Dictionary =/= valid JSON! If needed as a valid JSON, please put an opening square bracket at the beginning and closing square bracket at the end (like this: "[" ...dictionary... "]").  
for o in parse_trees/createTable/*_parse_tree.json; do ( jfq --query-file codeTemplates/jfq_createTable_integer_ID_columns.txt $o >> Stan_entries_collection/generated_integerCol_entries.json ) ; done

# remove empty lines with EOF chars at the end of the file and delete the last character (a comma) of the JSON file.
sed -i '/^$/d' Stan_entries_collection/generated_integerCol_entries.json
truncate -s-2 Stan_entries_collection/generated_integerCol_entries.json

########################################################################
# CREATE ARRAYS for NUMERIC/REAL typed columns (model DATA)
########################################################################
# NUMERIC/REAL typed columns are model input DATA (e.g. hyperparameter). 
printf '\n\n'
echo "Now creating Stan arrays/vectors numeric/real typed columns with MODEL DATA..."

rm Stan_entries_collection/generated_numericCol_DATA_entries.json
touch Stan_entries_collection/generated_numericCol_DATA_entries.json

# Create a dictionary with all the numeric model input data array/vector entries derived from CREATE TABLE statements.
# Dictionary = a set of JSON entities, helps to look up some entries needed when translating from SQL to Stan. 
# We append dictionaries to parse trees in order to extend the parse trees with the new available information. 
# Dictionary =/= valid JSON! If needed as a valid JSON, please put an opening square bracket at the beginning and closing square bracket at the end (like this: "[" ...dictionary... "]").  
for o in parse_trees/createTable/*_parse_tree.json; do ( jfq --query-file codeTemplates/jfq_createTable_numeric_DATA_columns.txt $o >> Stan_entries_collection/generated_numericCol_DATA_entries.json ) ; done

# remove empty lines with EOF chars at the end of the file and delete the last character (a comma) of the JSON file.
sed -i '/^$/d' Stan_entries_collection/generated_numericCol_DATA_entries.json
truncate -s-2 Stan_entries_collection/generated_numericCol_DATA_entries.json


########################################################################
# CREATE ARRAYS for NUMERIC/REAL typed columns (latent model PARAMETERS)
########################################################################
# NUMERIC/REAL typed columns are model PARAMETERS (e.g. latent parameters). 
printf '\n\n'
echo "Now creating Stan arrays/vectors numeric/real typed columns with MODEL PARAMETERS..."

rm Stan_entries_collection/generated_numericCol_PARAMETER_entries.json
touch Stan_entries_collection/generated_numericCol_PARAMETER_entries.json

# Create a dictionary with all the entries for UNCONSTRAINED model parameters derived from CREATE TABLE statements.
# Dictionary = a set of JSON entities, helps to look up some entries needed when translating from SQL to Stan. 
# We append dictionaries to parse trees in order to extend the parse trees with the new available information. 
# Dictionary =/= valid JSON! If needed as a valid JSON, please put an opening square bracket at the beginning and closing square bracket at the end (like this: "[" ...dictionary... "]").  
for o in parse_trees/createTable/*_parse_tree.json; do ( jfq --query-file codeTemplates/jfq_createTable_UNCONSTRAINED_PARAMETER_columns.txt $o >> Stan_entries_collection/generated_numericCol_PARAMETER_entries.json ) ; done

# remove empty lines with EOF chars at the end of the file
sed -i '/^$/d' Stan_entries_collection/generated_numericCol_PARAMETER_entries.json

# Create a dictionary with all the entries for CONSTRAINED model parameters derived from CREATE TABLE statements.
#
# Following SQL parameter constraints are defined:
# 1) simplex constraint, built like this:
#
#	CONSTRAINT stan_SimplexConstraint__data_sums_to_one_in_col CHECK (theta),
#	CONSTRAINT stan_SimplexConstraint__when_summed_over_col CHECK (topic_id),
#	CONSTRAINT stan_SimplexConstraint__when_grouped_by_col CHECK (document_id)
#
#	...and 'theta' column is typed as "stan_parameter_simplex_constrained" 
#
# 2) constraint, which shows that a column stands for a discrete model parameter (discrete means here integer-typed, not numeric-typed):
#
# 	CONSTRAINT stan_Constraint__int_parameter_refers_to_table CHECK (topic)
#
#	...which corresponds to the column 'topic_id' typed as "stan_parameter_int". 
#	In this case, the column topic_id is referencing a primary key column of a table 'topic', but we cannot just define it's type as 'integer REFERENCES token', 
#	...because it's a latent model parameter; we can't observe it's values. 
#	The type "integer REFERENCES token" is reserved for the integer columns we can fill with observed values, 
# 	the type "stan_parameter_int" is for those integer columns we cannot actually fill with something observable.

for o in parse_trees/createTable/*_parse_tree.json; do ( jfq --query-file codeTemplates/jfq_createTable_numeric_CONSTRAINED_PARAMETER_columns.txt $o >> Stan_entries_collection/generated_numericCol_PARAMETER_entries.json ) ; done

# remove empty lines with EOF chars at the end of the file and delete the last character (a comma) of the JSON file.
sed -i '/^$/d' Stan_entries_collection/generated_numericCol_PARAMETER_entries.json
truncate -s-2 Stan_entries_collection/generated_numericCol_PARAMETER_entries.json


#############################################################
# EXTEND PARSE TREE FOR THE LOG LIKELIHOOD SUM SQL QUERY:
#############################################################
# Append a dictionary to the log likelihood parse tree in order to extend the available information:
# ADD the "totals" dictionary to a parser tree of the log likelihood query
printf '\n\n'
echo "Now extending the parser tree of the LOG LIKELIHOOD query with the info from CREATE TABLE statements..."

for p in parse_trees/logLikelihood/*_parse_tree.json; do {
# delete last character (]) of the JSON file.
truncate -s-2 $p          
# add a comma instead
echo ',' >> $p
# append the "totals" dictionary JSON data
cat Stan_entries_collection/generated_total_entries.json >> $p
# add a comma
echo ',' >> $p
# append the "integer columns" dictionary JSON data
cat Stan_entries_collection/generated_integerCol_entries.json >> $p
# add a comma
echo ',' >> $p
# append the "numeric columns with model data" dictionary JSON data
cat Stan_entries_collection/generated_numericCol_DATA_entries.json >> $p
# add a comma
echo ',' >> $p
# append the "numeric columns with parameter data" dictionary JSON data
cat Stan_entries_collection/generated_numericCol_PARAMETER_entries.json >> $p        
# append the deleted last character (]) of the parse tree.
echo ']' >> $p
} ; done
#*

########################################################################
# CREATE STAN CODE FROM THE LOG LIKELIHOOD SUM SQL QUERY:
########################################################################
# every summand in the log likelihood sum query becomes a part of the model block in Stan code.
printf '\n\n'
echo "Now generating Stan code from the LOG LIKELIHOOD query..."

rm Stan_entries_collection/generated_logLikelihood_entries.txt
touch Stan_entries_collection/generated_logLikelihood_entries.txt

# Create a text file with all the entries for Stan MODEL block derived from the log likelihood sum query SQL statement:
for r in parse_trees/logLikelihood/*_parse_tree.json; do ( jfq --query-file codeTemplates/jfq_logLikelihood.txt $r >> Stan_entries_collection/generated_logLikelihood_entries.txt ) ; done

########################################################################
# CREATE STAN CODE OUTPUT:
########################################################################
# create an output file in the SQL2STAN directory with the generated Stan code
printf '\n\n'
echo "Now putting all the Stan code pieces together..."

rm generated_OUTPUT/generated_OUTPUT.stan
# rm generated_OUTPUT/inputData.data.R
touch generated_OUTPUT/generated_OUTPUT.stan

# DATA block
echo 'data {' >> generated_OUTPUT/generated_OUTPUT.stan 

# append an opening square bracket at the beginning of the "totals" dictionary
sed -i '1s/^/[ /' Stan_entries_collection/generated_total_entries.json
# append a closing square bracket at the end of the "totals" dictionary
echo ']' >> Stan_entries_collection/generated_total_entries.json
# append the "total" entries to the output
jfq 'total.Stan_total_entry' Stan_entries_collection/generated_total_entries.json >> generated_OUTPUT/generated_OUTPUT.stan 

# append an opening square bracket at the beginning of the "integer columns" dictionary
sed -i '1s/^/[ /' Stan_entries_collection/generated_integerCol_entries.json
# append a closing square bracket at the end of the "integer columns" dictionary
echo ']' >> Stan_entries_collection/generated_integerCol_entries.json
# append the "integer columns" entries to the output
jfq 'column.Stan_integer_array' Stan_entries_collection/generated_integerCol_entries.json >> generated_OUTPUT/generated_OUTPUT.stan 

# append an opening square bracket at the beginning of the "numeric columns with model data" dictionary
sed -i '1s/^/[ /' Stan_entries_collection/generated_numericCol_DATA_entries.json
# append a closing square bracket at the end of the "numeric columns with model data" dictionary
echo ']' >> Stan_entries_collection/generated_numericCol_DATA_entries.json
# append the "numeric columns with model data" entries to the output
jfq 'column.Stan_DATA_array' Stan_entries_collection/generated_numericCol_DATA_entries.json >> generated_OUTPUT/generated_OUTPUT.stan 

# END of the DATA block
echo '}' >> generated_OUTPUT/generated_OUTPUT.stan 

# PARAMETERS block
echo 'parameters {' >> generated_OUTPUT/generated_OUTPUT.stan 

# append an opening square bracket at the beginning of the "numeric columns with parameter data" dictionary
sed -i '1s/^/[ /' Stan_entries_collection/generated_numericCol_PARAMETER_entries.json
# append a closing square bracket at the end of the "numeric columns with parameter data" dictionary
echo ']' >> Stan_entries_collection/generated_numericCol_PARAMETER_entries.json
# append the "numeric columns with parameter data" entries to the output
jfq 'column.Stan_PARAMETER_array' Stan_entries_collection/generated_numericCol_PARAMETER_entries.json >> generated_OUTPUT/generated_OUTPUT.stan 

# END of the PARAMETERS block
echo '}' >> generated_OUTPUT/generated_OUTPUT.stan 

# MODEL block
echo 'model {' >> generated_OUTPUT/generated_OUTPUT.stan 

# add gamma entries = temporary arrays for discrete (integer-typed) model parameters
jfq 'column[$exists(Stan_integer_PARAMETER_array)].gamma_array' Stan_entries_collection/generated_numericCol_PARAMETER_entries.json >> generated_OUTPUT/generated_OUTPUT.stan 

# append a text file with all the "log likelihood sum query" entries to the output
cat Stan_entries_collection/generated_logLikelihood_entries.txt >> generated_OUTPUT/generated_OUTPUT.stan   

# END of the PARAMETERS block
echo '}' >> generated_OUTPUT/generated_OUTPUT.stan 


########################################################################
# GENERATE IMPORT INSTRUCTIONS FOR POSTGRES:
########################################################################
# create a text file with column import instruction in the "import_from_Postgres" directory
printf '\n\n'
echo "Now generating instructions for the data import from the PostgreSQL database system..."

rm Postgres_import_export/*
touch Postgres_import_export/postgres_import_commands.sql

# Data we need to import from DB is the data in either integer or numeric data typed columns!
# Generate and write data import commands for each column into a file:
jfq --query-file codeTemplates/jfq_data_column_import_INTEGER_MULTIDIMENSIONAL_data.txt Stan_entries_collection/generated_integerCol_entries.json >> Postgres_import_export/postgres_import_commands.sql 

jfq --query-file codeTemplates/jfq_data_column_import_NUMERIC_MULTIDIMENSIONAL_data.txt Stan_entries_collection/generated_numericCol_DATA_entries.json >> Postgres_import_export/postgres_import_commands.sql

jfq --query-file codeTemplates/jfq_data_column_import_INTEGER_ONEDIMENSIONAL_data.txt Stan_entries_collection/generated_integerCol_entries.json >> Postgres_import_export/postgres_import_commands.sql 

jfq --query-file codeTemplates/jfq_data_column_import_NUMERIC_ONEDIMENSIONAL_data.txt Stan_entries_collection/generated_numericCol_DATA_entries.json >> Postgres_import_export/postgres_import_commands.sql

jfq --query-file codeTemplates/jfq_data_column_import_TOTALS_data.txt Stan_entries_collection/generated_total_entries.json >> Postgres_import_export/postgres_import_commands.sql


########################################################################
# IMPORT MODEL DATA FROM POSTGRES DB AND CONVERT IT TO data.R FILE 
########################################################################
# Tables, which were defined in your CREATE TABLE statements, will be created in a Postgresql DB of your choice.
# WARNING: IT'S UP TO YOU HOW YOU FILL THE TABLES WITH DATA!

printf '\n\n'
echo "Tables, which were defined in your CREATE TABLE statements, will be created in a Postgresql DB of your choice automatically."

printf '\n'
read -p "To create a database (and all the database tables you've defined), enter a database name for your SQL2STAN project (without special characters, and for the case sensitivity also double-quoted, e.g. \"supervisedNaiveBayes\"): " dbname_entered 

printf '\n\n'
echo "Now trying to create a PostgreSQL database named \"$dbname_entered\"..."
psql -U sql2stan_user -d postgres -c "create database $dbname_entered"

printf '\n\n'
echo "Now trying to integrate specific data types and functions..."
psql -U sql2stan_user -d $dbname_entered -f createTable/specific_types_and_functions_for_PostgreSQL_DB.sql

printf '\n\n'
echo "Now trying to create tables in the DB \"$dbname_entered\")..."
psql -U sql2stan_user -d $dbname_entered -f createTable/CREATE_TABLE_statements_for_PostgreSQL_DB.sql

printf '\n\n'
echo "Now you have to fill the DB tables with model data. Feel free to work your magic on it, and don't forget about the topological order! :)"
echo "You are already in the PostgreSQL shell. If you want to exit the PostgreSQL shell, type \q and press Enter. "
echo "Don't forget to continue the workflow after inserting the model data into the DB (Hint: ./continue_workflow.sh)"
printf '\n'
echo "Hint: there's already some data for both example models! To load it into the DB tables simply start the corresponding command file \"insert_model_data_*.sh\"."

printf '\n\n'

psql -U sql2stan_user -d $dbname_entered

# NOW FILL THE TABLES WITH YOUR DATA. 
# DATA RELATIONS HAVE TO BE COMPLETE! 
# Example: if you have 4 topics and 10 words, your topic_word table (with topic_id and word_id as PK) should have 40 rows (every word_id with every topic_id).
#  
# When filling the data into your DB tables you can access the Postgresql shell (called psql) with following command:
# psql -U sql2stan_user -d $dbname_entered
# P.S. You can exit the Postgresql shell with a command \q 


# FILLING THE TABLES WITH DATA for "supervised naive Bayes" EXAMPLE:
# start the shell application "./insert_model_data_for_SUPERVISED_NAIVE_BAYES_example.sh"

# DB USER PRIVILEGES, a TROUBLESHOOTING REMARK: 
# If the user "sql2stan_user" doesn't have the right privileges to work on tables, you may try this:
# 1) log in as you original Uni system user (has to be in the sudoer group): 
# 	su - USERNAME
# 2) Grant some privileges to "sql2stan_user" in the Postgresql system:
# sudo -u postgres psql -c "GRANT CONNECT ON DATABASE $dbname_entered TO sql2stan_user"
# sudo -u postgres psql -c "GRANT USAGE ON SCHEMA public TO sql2stan_user"
# sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO sql2stan_user"


