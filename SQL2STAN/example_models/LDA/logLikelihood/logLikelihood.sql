	-- for (m in 1:M)  theta[m] ~ dirichlet(alpha); 
	-- 
	with "log p(theta|alpha)" as (
		with "log dir(theta|alpha)" as (
			with "prior__alpha" as (
				select 
					alpha,
					topic_id
				from 
					topic
			),
			"posterior__theta" as (
				select 
					theta,
					document_id, 
					topic_id
				from 
					document_topic
			),
			"index_for_loop_over_document_ids" as (
				select 
					document_id
				from 
					document
			)
			select
				LoopIndex.document_id,
				dirichlet_lpdf(
					ARRAY(
						select 
							theta 
						from 
							posterior__theta 
						where 
							document_id = LoopIndex.document_id
						order by 
							document_id, 
							topic_id
					),
					ARRAY(
						select
							alpha
						from 
							prior__alpha
						order by 
							topic_id
					) 
				) as dirichlet_lpdf
			from
				index_for_loop_over_document_ids as LoopIndex
		)
		select
			sum(dirichlet_lpdf) as "log p(theta|alpha)"
		from
			"log dir(theta|alpha)"
	)
	--  for (k in 1:K)  phi[k] ~ dirichlet(beta);
	-- 
	,"log p(phi|beta)" as (
		with "log dir(phi|beta)" as (
			with "prior__beta" as (
				select 
					beta,
					topic_id,
					word_id
				from 
					topic_word
			),
			"posterior__phi" as (
				select 
					phi,
					topic_id,
					word_id
				from 
					topic_word
			),
			"index_for_loop_over_topic_ids" as (
				select 
					topic_id
				from 
					topic
			)
			select
				LoopIndex.topic_id,
				dirichlet_lpdf(
					ARRAY(
						select 
							phi 
						from 
							posterior__phi 
						where 
							topic_id = LoopIndex.topic_id
						order by 
							topic_id,
							word_id
					),
					ARRAY(
						select 
							beta 
						from 
							prior__beta 
						where 
							topic_id = LoopIndex.topic_id
						order by 
							topic_id,
							word_id
					) 
					-- Subselect for beta-Prior has a WHERE condition in order to mind it's dimensionality:
					-- For each 'topic_id' value in the 'topic-word' table, there are always |V| many 'beta' values corresponding to it. |V| is the size of the vocabulary.
					-- Therefore, each 'word_id' has it's own beta value.  
				) as dirichlet_lpdf
			from
				index_for_loop_over_topic_ids as LoopIndex
		)
		select
			sum(dirichlet_lpdf) as "log p(phi|beta)"
		from
			"log dir(phi|beta)"
	)

	-- for (n in 1:N)
	-- z[n] ~ categorical(theta_m_n);
	-- 
	, "log p(z|theta)" as (
		with "log cat(z|theta)" as (
			with "posterior__z_n" as (
				select 
					topic_id,
					document_id,
					token_id
				from 
					document_token_topic
			),
			"prior__theta_n" as (
				select
					theta,
					document_id,
					topic_id
				from 
					document_topic
			),
			"n__for__prior__theta_n" as (
				select
					document_id,
					token_id
				from 
					document_token_word
			),
			"loop_over_tokens" as (
				select 
					token_id
				from 
					token
			)
			select 
				LoopIndex.token_id,
				categorical_lpmf(
					ARRAY(
						select 
							topic_id 
						from 
							posterior__z_n
						where 
							token_id = LoopIndex.token_id
						order by 
							token_id
					),
					ARRAY(
						select
							theta
						from 
							prior__theta_n
						where
							document_id in 
							(
								select
									document_id
								from
									n__for__prior__theta_n
								where 
									token_id = LoopIndex.token_id
								order by 
									token_id
							)
						order by 
							document_id,
							topic_id
					)
				) as categorical_lpmf
			from 
				loop_over_tokens as LoopIndex
		)
		select
			sum(categorical_lpmf) as "log p(z|theta)"
		from
			"log cat(z|theta)"
	)	

	-- for (n in 1:N)
	-- w[n] ~ categorical(phi[z_n]);
	-- 
	, "log p(w|z)" as (
		with "log cat(w|z)" as (
			with "posterior__w_n" as (
				select 
					word_id,
					document_id,
					token_id
				from 
					document_token_word
			),
			"prior__z_n" as (
				select 
					topic_id,
					document_id,
					token_id
				from 
					document_token_topic
			),
			"loop_over_tokens" as (
				select 
					token_id
				from 
					token
			),
			"prior__phi_z_n" as (
				select 
					phi,					
					topic_id,
					word_id
				from 
					topic_word
			)
			select 
				LoopIndex.token_id,
				categorical_lpmf(
					ARRAY(
						select 
							word_id 
						from 
							posterior__w_n
						where 
							token_id = LoopIndex.token_id
						order by 
							token_id
					),
					ARRAY(
						select
							phi
						from 
							prior__phi_z_n
						where
							topic_id in 
								( 
								select
									topic_id
								from
									prior__z_n
								where
									token_id = LoopIndex.token_id
								order by 
									token_id
								)	
						order by 
							topic_id,
							word_id
					)
				) as categorical_lpmf
			from 
				loop_over_tokens as LoopIndex
		)
		select
			sum(categorical_lpmf) as "log p(w|z)"
		from
			"log cat(w|z)"
	)
SELECT
	"log p(theta|alpha)" +
	"log p(phi|beta)" +
	"log p(z|theta)" +
	"log p(w|z)" 
	as "log p(d,z,phi,theta|alpha,beta)"
FROM
	"log p(theta|alpha)",
	"log p(phi|beta)",
	"log p(z|theta)",
	"log p(w|z)"
;
