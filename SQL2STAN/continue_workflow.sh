#!/bin/bash
# the folder "SQL2STAN" has to be in the same parent directory as "libpg_query"!


echo 'Workflow continued!' 
echo 'Please make sure you are logged in as SQL2STAN Unix system account "sql2stan_user".' 
# If not, you have to switch to your SQL2STAN Unix system account ("sql2stan_user"). 
# 	You will be asked for a password for it; type in the password you used when installing SQL2STAN. 
# 	Shell command: 	
#		su - sql2stan_user

rm Postgres_import_export/*.csv

rm generated_OUTPUT/inputData.data.R
touch generated_OUTPUT/inputData.data.R
rm Stan_entries_collection/totals_initialized_with_numbers.txt
touch Stan_entries_collection/totals_initialized_with_numbers.txt

read -p "Enter a database name for your SQL2STAN project you want to work further with (without special characters, and for the case sensitivity also double-quoted, e.g. \"supervisedNaiveBayes\"): " dbname_entered 

printf '\n\n'
echo "Now extracting the data of each column from the database..."
# extract column data from DB and prepare it for being converted into an * .data.R formatted Stan input file:
while read extracting_command
do
	psql -U sql2stan_user -d $dbname_entered -c "$extracting_command"
done < Postgres_import_export/postgres_import_commands.sql

printf '\n\n'
echo "Now initializing Stan total entries with actual values..."
# generate input data entries for Stan total entries, and create a non-JSON dictionary for total entries with their values.
for s in Postgres_import_export/*_totalEntry.csv; do 
	echo "$(basename $s) <-" | sed 's/__totalEntry.csv//g' >> generated_OUTPUT/inputData.data.R
	cat $s >> generated_OUTPUT/inputData.data.R
	printf "$(basename $s) =" | sed 's/__totalEntry.csv//g' >> Stan_entries_collection/totals_initialized_with_numbers.txt
	printf "$(cat $s) \n" >> Stan_entries_collection/totals_initialized_with_numbers.txt
done

printf '\n\n'
echo "Now initializing one-dimensional Stan data entries with actual values..."
# generate input data entries for Stan data arrays/vectors entries (one-dimensional):
for s in Postgres_import_export/*onedimensional__importedFromDB.csv; do 
	echo "$(basename $s) <-" | sed 's/__onedimensional__importedFromDB.csv//g' >> generated_OUTPUT/inputData.data.R
	echo "c(" >> generated_OUTPUT/inputData.data.R
	paste -d, -s $s >> generated_OUTPUT/inputData.data.R
	echo ")" >> generated_OUTPUT/inputData.data.R
done

printf '\n\n'
echo "Now initializing multi-dimensional Stan data entries with actual values..."
# generate input data entries for Stan data arrays/vectors entries (multidimensional):
for s in Postgres_import_export/*multidimensional__importedFromDB.csv; do 
	entry_name=$(printf "$(basename $s)" | sed 's/__multidimensional__importedFromDB.csv//g')
	echo "$entry_name  <-" >> generated_OUTPUT/inputData.data.R
	echo "structure(c(" >> generated_OUTPUT/inputData.data.R
	paste -d, -s $s >> generated_OUTPUT/inputData.data.R
	echo "),.Dim=c(" >> generated_OUTPUT/inputData.data.R
	touch Stan_entries_collection/temporary_file_dimensions.txt
	jfq "column[without_type=\"$entry_name\"].sorting_order_with_totals_names" Stan_entries_collection/generated_integerCol_entries.json >> Stan_entries_collection/temporary_file_dimensions.txt
	jfq "column[without_type=\"$entry_name\"].sorting_order_with_totals_names" Stan_entries_collection/generated_numericCol_DATA_entries.json >> Stan_entries_collection/temporary_file_dimensions.txt
	sed -i '/./,$!d' Stan_entries_collection/temporary_file_dimensions.txt
	while read line
	do
		grep $line Stan_entries_collection/totals_initialized_with_numbers.txt | sed "s/$line =//g" >> generated_OUTPUT/inputData.data.R
		printf "," >> generated_OUTPUT/inputData.data.R
	done < Stan_entries_collection/temporary_file_dimensions.txt
	truncate -s-2 generated_OUTPUT/inputData.data.R
	echo "))" >> generated_OUTPUT/inputData.data.R
	rm Stan_entries_collection/temporary_file_dimensions.txt
done


########################################################################
# STAN INFERENCE:
########################################################################

rm generated_OUTPUT/summarized_inference_output.txt

echo "Now compiling the generated Stan code..."
# compile Stan code:
make -C ../cmdstan-2.18.0/ ../SQL2STAN/generated_OUTPUT/generated_OUTPUT

echo "Now executing sampling of the model..."
# start sampling (with Stan's default settings):
generated_OUTPUT/generated_OUTPUT sample data file=generated_OUTPUT/inputData.data.R output file=generated_OUTPUT/raw_output.csv

echo "Now summarizing the inference output..."
# summarize the sampling output:
../cmdstan-2.18.0/bin/stansummary generated_OUTPUT/raw_output.csv >> generated_OUTPUT/summarized_inference_output.txt

rm generated_OUTPUT/generated_OUTPUT
rm generated_OUTPUT/generated_OUTPUT.hpp
rm generated_OUTPUT/raw_output.csv


########################################################################
# FILTER STAN INFERENCE OUTPUT:
########################################################################
rm generated_OUTPUT/first_temporary_file_for_inference_output.txt
rm generated_OUTPUT/second_temporary_file_for_inference_output.txt

# skip the header and the tail of the summarized output
if grep -Eq "lp__" generated_OUTPUT/summarized_inference_output.txt 
then 
	cat generated_OUTPUT/summarized_inference_output.txt | sed '/lp__/,$!d' | tail -n +2 > generated_OUTPUT/first_temporary_file_for_inference_output.txt
	if grep -Eq "energy__" generated_OUTPUT/first_temporary_file_for_inference_output.txt
	then
		cat generated_OUTPUT/first_temporary_file_for_inference_output.txt | sed '/energy__/,$!d' | tail -n +2 | head -n -6 > generated_OUTPUT/second_temporary_file_for_inference_output.txt
	else 
		cat generated_OUTPUT/first_temporary_file_for_inference_output.txt |  head -n -6 > generated_OUTPUT/second_temporary_file_for_inference_output.txt
	fi
else 
	echo 'Strangely, there is no "lp__" (unnormalized log probability of the model) entry in the summarized output, but it has to be there! Please check the inference output for errors.'
fi

echo "Now writing the inference output into DB..."
# write computed values for latent model parameters into DB:
while read line
do
	column_name="$(sed 's/__asColumnOfTable.*//' <<< $line)"
	table_name="$(sed 's/.*asColumnOfTable__\(.*\)\[.*/\1/' <<< $line)" 
	index_information="$(sed 's/.*\[\(.*\)\].*/\1/' <<< $line)" 
	IFS=', ' read -r -a index_information_split_on_comma <<< "$index_information"
	value_to_be_put_into_DB="$(awk '{print $2}' <<< $line)"    
	stan_entry_string=""$column_name\_\_asColumnOfTable\_\_$table_name""
	sorting_order="$(jfq "column[(Stan_PARAMETER_array) and (without_type=\"$stan_entry_string\")].sorting_order" Stan_entries_collection/generated_numericCol_PARAMETER_entries.json)"
	IFS=', ' read -r -a sorting_order_split_on_comma <<< "$sorting_order"
	unset zipping_colNames_and_indexes_for_WHERE_conditions;
	for (( i=0; i<${#index_information_split_on_comma[*]}; ++i)); do zipping_colNames_and_indexes_for_WHERE_conditions+=( ${sorting_order_split_on_comma[$i]}"="${index_information_split_on_comma[$i]}); done
	where_conditions="$(echo "${zipping_colNames_and_indexes_for_WHERE_conditions[*]}" | sed "s/ / and /g")"
	postgres_insert_query="UPDATE $table_name SET $column_name = $value_to_be_put_into_DB WHERE $where_conditions;" 
	psql -U sql2stan_user -d $dbname_entered -c "$postgres_insert_query"
done < generated_OUTPUT/second_temporary_file_for_inference_output.txt

rm generated_OUTPUT/first_temporary_file_for_inference_output.txt
rm generated_OUTPUT/second_temporary_file_for_inference_output.txt

printf '\n\n'
echo "All work done! Enjoy your complete model data in the database. "
echo "Access the PostgreSQL DB with the command:   psql -U sql2stan_user -d $dbname_entered "
echo "Quit the psql shell with: 	\q "

