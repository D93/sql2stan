CREATE TABLE product (
	product_id		integer not null,
	beta		stan_data_real,
	PRIMARY KEY (product_id),
	CONSTRAINT SortingOrder_Position_1 CHECK (argument_column('product_id'))
);