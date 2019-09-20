CREATE TABLE topic_word (
	topic_id	integer	 REFERENCES topic,
	word_id		integer	 REFERENCES word,
	phi		stan_parameter_simplex_constrained,
	beta		stan_data_real,
	PRIMARY KEY (topic_id, word_id),
	CONSTRAINT stan_SimplexConstraint__data_sums_to_one_in_col CHECK (argument_column('phi')),
	CONSTRAINT stan_SimplexConstraint__when_summed_over_col CHECK (argument_column('word_id')),
	CONSTRAINT stan_SimplexConstraint__when_grouped_by_col CHECK (argument_column('topic_id')),
	CONSTRAINT SortingOrder_Position_1 CHECK (argument_column('topic_id')),
	CONSTRAINT SortingOrder_Position_2 CHECK (argument_column('word_id'))
);
