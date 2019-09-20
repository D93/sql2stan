CREATE TABLE customer_class (
	customer_class_id	integer not null,
	alpha		stan_data_real,
	theta		stan_parameter_simplex_constrained,
	PRIMARY KEY (customer_class_id),
	CONSTRAINT stan_SimplexConstraint__data_sums_to_one_in_col CHECK (argument_column('theta')),
	CONSTRAINT stan_SimplexConstraint__when_summed_over_col CHECK (argument_column('customer_class_id')),
	CONSTRAINT SortingOrder_Position_1 CHECK (argument_column('customer_class_id'))
);