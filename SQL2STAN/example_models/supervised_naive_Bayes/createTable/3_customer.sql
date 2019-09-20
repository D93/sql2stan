CREATE TABLE customer (
	customer_id	integer not null,
	customer_class_id	integer	 REFERENCES customer_class,
	PRIMARY KEY (customer_id),
	CONSTRAINT SortingOrder_Position_1 CHECK (argument_column('customer_id'))
);
