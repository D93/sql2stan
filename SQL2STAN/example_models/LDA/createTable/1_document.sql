CREATE TABLE document (
	document_id	integer not null,
	PRIMARY KEY (document_id),
	CONSTRAINT SortingOrder_Position_1 CHECK (argument_column('document_id'))
);
