CREATE TABLE topic (
	topic_id	integer not null,
	alpha		stan_data_real,
	PRIMARY KEY (topic_id),
	CONSTRAINT SortingOrder_Position_1 CHECK (argument_column('topic_id'))
);
