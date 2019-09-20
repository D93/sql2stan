CREATE TABLE word (
	word_id	integer not null,
	PRIMARY KEY (word_id),
	CONSTRAINT SortingOrder_Position_1 CHECK (argument_column('word_id'))
);
