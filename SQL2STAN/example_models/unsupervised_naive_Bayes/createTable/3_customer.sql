CREATE TABLE customer (
	customer_id	integer not null,
	customer_class_id	stan_parameter_int,
	PRIMARY KEY (customer_id),
	CONSTRAINT SortingOrder_Position_1 CHECK (argument_column('customer_id')),
	CONSTRAINT stan_Constraint__int_parameter_independent CHECK (true), 
	CONSTRAINT stan_Constraint__int_parameter_refers_to_table CHECK (argument_table('customer_class'))
);
