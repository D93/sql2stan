CREATE TABLE token (
	token_id	integer not null,
	PRIMARY KEY (token_id),
	CONSTRAINT SortingOrder_Position_1 CHECK (argument_column('token_id'))
);
