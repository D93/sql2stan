CREATE TABLE product_purchase (
	product_purchase_id	integer not null,
	customer_id	integer	 REFERENCES customer,
	product_id	integer	 REFERENCES product,
	PRIMARY KEY (product_purchase_id),
	CONSTRAINT SortingOrder_Position_1 CHECK (argument_column('product_purchase_id'))
);