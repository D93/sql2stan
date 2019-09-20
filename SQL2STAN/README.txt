
##################################################
########  README ON SQL2STAN DIRECTORIES #########
##################################################

General notes:

- User interacts with directories "SQL2STAN/createTable" and "SQL2STAN/logLikelihood". 
You may feel free to clean them up (delete all the contained files) after the workflow completion if you want to. 

- After the workflow, you may find it interesting to check the contents of the "generated_OUTPUT" directory. 
The generated Stan code ("generated_OUTPUT.stan") as much as the array representation of your relational data ("inputData.data.R") and the summarized inference output ("summarized_inference_output.txt") are sitting there. 

- DO-NOTs:
	Please DO NOT DELETE FILES in the "codeTemplates" directory,
	DO NOT DELETE WHOLE DIRECTORIES OR CHANGE THEIR NAMES,
	DO NOT DELETE the scripts "start_workflow.sh" and "continue_workflow.sh".
Any of those action will render the SQL2Stan prototype useless, as the directories' structure has to remain unchanged -- and you also don't want to delete the scripts that work for you ;). 

- Don't worry about the notifications like "cannot remove stuff, it's not there" when starting a workflow on a newly imported example model. 
Every time you execute ./start_workflow.sh, this script assumes you also have some temporary files from the previous workflow and tries to delete them. 
If those temp files aren't there (because you either deleted them by yourself or your SQL2Stan path is just newly installed and pristine), the tool cannot delete them and informs you about it. 

- Some error messages will be generated IN THE JSON FILES. Those will make the JSON FILES syntactically incorrect, and jfq-sided JSONATA queries will inform you about it. 
This is some kind of very rudimentary error feedback I've implemented.
Basically, if there is a problem, take a closer look into the generated text file where the problems began to appear.  

##################################################

DIRECTORIES IN THE SQL2Stan PATH:

1) Directory "code_for_libpg_query" 
= generated C-code with embedded SQL statements, which should be parsed into JSON parse trees. 
Subdirectories "createTable" and "logLikelihood" contain the C-Programs for parsing each Create-Table statements or rather an SQL query with the target function (model structure). 

2) Directory "codeTemplates"
= contains the code for the SQL2Stan compiler: it consists of C-code templates and JFQ/Jsonata queries (JSON query language).

3) Directory "createTable"
= that's where your CREATE-TABLE statements of the integrated dabase schema should be.
Please place the topological order numbers in front of your SQL file names! Only then table dependencies can be recreated properly. 
The contents of this directory are allowed to be deleted or changed after the workflow ends. 
You can load the CREATE-TABLE statements from any of the three prototype examples here. Just be in the SQL2Stan directory and execute this in the terminal:
	rm createTable/*
	cp example_models/HERE-STANDS-THE-EXAMPLE-NAME/createTable/* createTable/

4) Directory "logLikelihood"
= a place to start, when you've freshly written your model specific log likelihood function in SQL and don't know where it belongs. 
The contents of this directory are allowed to be deleted or changed after the workflow ends. 
You can load the target function statement (log likelihood) from any of the three prototype examples here. Just be in the SQL2Stan directory and execute this in the terminal:
	rm logLikelihood/*
	cp example_models/HERE-STANDS-THE-EXAMPLE-NAME/logLikelihood/* logLikelihood/

5) Directory "generated_OUTPUT"
= results of automatic manipulations (translated Stan code, array-ized model input data, summarized inference output). 
It may be the most interesting directory. Here you can find the generated Stan code ("generated_OUTPUT.stan"), the array representation of your relational data ("inputData.data.R") and the summarized inference output with some statistics ("summarized_inference_output.txt") after the workflow has ended. 

6) Directory "parse_trees" 
= JSON parse trees as a result of parsing the SQL statements. 
Subdirectories "createTable" and "logLikelihood" contain the JSON files with parse trees for Create-Table statements or rather SQL query with the target function (model structure). 

7) Directory "Postgres_import_export"
= contains some automatically generated commands for PostgreSQL RDBMS (data management infrastructure in this prototype) and R-styled ('L'-suffix for integers) CSV dumps for input data.
The automatically created file "portgres_import_commands.sql" contains the commands needed to dump the database data into parse-friendly CSV files. 

8) Directory "Stan_entries_collection"
= all the automatically generated knowledge bases ("dictionaries") and code needed for translation from SQL to Stan are placed here.



##################################################
##################### HOW  #######################
######################  TO  ######################
#######################  START  ##################
##################################################


######################
 BEFORE YOU START!
######################
 (assuming, you are now in the SQL2STAN directory):

 0.0) Install SQL2Stan and dependencies (follow through the INSTALLATION INSTRUCTIONS.txt)

 0.1) Give needed permissions to work on the SQL2STAN directory content to the Unix user "sql2stan_user"  with
 	these shell commands (execute as superuser, not as sql2stan_user; execute in the SQL2STAN directory): 
	
		sudo setfacl -R -d -m u:sql2stan_user:rwx .
		sudo setfacl -R    -m u:sql2stan_user:rwx .
		sudo setfacl -R -d -m u:sql2stan_user:rwx ../cmdstan-2.18.0
		sudo setfacl -R    -m u:sql2stan_user:rwx ../cmdstan-2.18.0

 0.2) Check, which Unix system user account you are currently working with. 
 	Shell command: 	
	
		whoami 
		
 0.3) Now you have switch to your SQL2STAN Unix system account ("sql2stan_user"). 
 	You will be asked for a password for it; type in the password you used when installing SQL2STAN.
 	Shell command:
 	
		su - sql2stan_user
		
 0.4) Go to you SQL2STAN directory. Please swap the "YOUR_ORIGINAL_SYSTEM_ACCOUNT_NAME" with the Unix user name from step 1.
 	Shell command: 	
	
		cd ../YOUR_ORIGINAL_SYSTEM_ACCOUNT_NAME/SQL2STAN
		
	For example (if you are using an Osboxes Ubuntu VM):
	
		cd ../osboxes/SQL2STAN

######################
 HOW TO USE: 
######################
 (assuming, you are now in the SQL2STAN directory)

 0) Give needed permissions to work on the SQL2STAN directory content to the Unix user "sql2stan_user" and log in as "sql2stan_user" 
	(see above in the "BEFORE YOU START" part).

 1) Place your CREATE TABLE files (one for each table) into the subdirectory "createTable".
 	Important note: 
		IF YOU ARE WORKING WITH YOUR OWN RELATIONAL SCHEMA STATEMENTS, place the topological order numbers in front of file names (just like in the SQL2Stan model examples)! 
		Only then table dependencies can be recreated properly. 
 	HINT: if you try out the model examples, use these shell commands to load the statements:
		- for LDA example:
			rm createTable/*
			cp example_models/LDA/createTable/* createTable/
		- for supervised naive Bayes example:
			rm createTable/*
			cp example_models/supervised_naive_Bayes/createTable/* createTable/
		- for unsupervised naive Bayes example:
			rm createTable/*
			cp example_models/unsupervised_naive_Bayes/createTable/* createTable/

 2) Place you log likelihood sum SQL statement into the subdirectory "logLikelihood".
 	HINT: if you try out the model examples, use these shell commands to load the statements:
		- for LDA example:
			rm logLikelihood/*
			cp example_models/LDA/logLikelihood/* logLikelihood/
		- for supervised naive Bayes example:
			rm logLikelihood/*
			cp example_models/supervised_naive_Bayes/logLikelihood/* logLikelihood/
		- for unsupervised naive Bayes example:
			rm logLikelihood/*
			cp example_models/unsupervised_naive_Bayes/logLikelihood/* logLikelihood/

 3) Start with script (and create a database following script's directions): ./start_workflow.sh 
 
 4) Type \q and press Enter to quit the PostgreSQL shell.

 5) Put the model data into your database tables. 
 	HINT: if you try out the model examples, use a script which loads the example data into your DB:
		- for LDA example:
			example_models/LDA/insert_model_data_for_LDA_example.sh
		- for supervised naive Bayes example:
			example_models/supervised_naive_Bayes/insert_model_data_for_SUPERVISED_NAIVE_BAYES_example.sh
		- for unsupervised naive Bayes example:
			example_models/unsupervised_naive_Bayes/insert_model_data_for_UNSUPERVISED_NAIVE_BAYES_example.sh

 6) Continue with the script: ./continue_workflow.sh 

 7) (optional) Query up the model data (given and inferred) via SQL: 

		psql -U sql2stan_user -d NAME-OF-THE-EXAMPLE-MODEL-DATABASE

		-- just use classic SQL queries! 
		-- When you have enough of it, enter \q to exit.

		\q

 8) (optional) Delete the database with all the model data: 

		sudo -u postgres psql

		drop database NAME-OF-THE-EXAMPLE-MODEL-DATABASE ;

		\q

######################
 optional, but could be important for integration SQL2Stan into another project: 
######################
 accessing CREATE TABLE statements (among other infos) with the additional information after the workflow ended: 
 pg_dump -U sql2stan_user -d DATABASE_NAME_YOU_USED -s



