CREATE TABLE document_topic (
	topic_id	integer	 REFERENCES topic,
	document_id	integer	 REFERENCES document,
	theta		stan_parameter_simplex_constrained,
	PRIMARY KEY (document_id, topic_id),
	CONSTRAINT stan_SimplexConstraint__data_sums_to_one_in_col CHECK (argument_column('theta')),
	CONSTRAINT stan_SimplexConstraint__when_summed_over_col CHECK (argument_column('topic_id')),
	CONSTRAINT stan_SimplexConstraint__when_grouped_by_col CHECK (argument_column('document_id')),
	CONSTRAINT SortingOrder_Position_1 CHECK (argument_column('document_id')),
	CONSTRAINT SortingOrder_Position_2 CHECK (argument_column('topic_id'))
);
