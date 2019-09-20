CREATE TABLE customer_class_product (
	customer_class_id	integer	 REFERENCES customer_class,
	product_id		integer	 REFERENCES product,
	phi 		stan_parameter_simplex_constrained,
	PRIMARY KEY (customer_class_id, product_id),
	CONSTRAINT stan_SimplexConstraint__data_sums_to_one_in_col CHECK (argument_column('phi')),
	CONSTRAINT stan_SimplexConstraint__when_summed_over_col CHECK (argument_column('product_id')),
	CONSTRAINT stan_SimplexConstraint__when_grouped_by_col CHECK (argument_column('customer_class_id')),
	CONSTRAINT SortingOrder_Position_1 CHECK (argument_column('customer_class_id')),
	CONSTRAINT SortingOrder_Position_2 CHECK (argument_column('product_id'))
);