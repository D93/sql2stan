CREATE TABLE document_token_word (
	word_id		integer	 REFERENCES token,
	token_id	integer	 REFERENCES token,
	document_id	integer	 REFERENCES token,
	PRIMARY KEY (token_id),
	CONSTRAINT SortingOrder_Position_1 CHECK (argument_column('token_id'))
);
