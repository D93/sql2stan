CREATE TABLE document_token_topic (
	topic_id	stan_parameter_int,
	token_id	integer	 REFERENCES token,
	document_id	integer	 REFERENCES document,
	PRIMARY KEY (token_id),
	CONSTRAINT SortingOrder_Position_1 CHECK (argument_column('token_id')),
	CONSTRAINT stan_Constraint__int_parameter_independent CHECK (true), 
	-- discrete/integer parameter independent = no need to involve X-1 and X+1 into the computation of the value X.
	CONSTRAINT stan_Constraint__int_parameter_refers_to_table CHECK (argument_table('topic'))
);	
