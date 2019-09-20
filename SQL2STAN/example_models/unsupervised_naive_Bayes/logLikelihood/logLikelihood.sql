-- theta ~ dirichlet(alpha);
--
with "log dir(theta|alpha)" as (
		with "posterior__theta" as (
			select 
				-- a view for a distribution parameter: a data/parameter column + primary key column(s)
				theta,
				customer_class_id
			from 
				customer_class
		),
		"prior__alpha" as (
			select 
				alpha,
				customer_class_id
			from 
				customer_class
		)
		select 
			dirichlet_lpdf(
				ARRAY(
					select 
						theta 
					from 
						posterior__theta
					order by 
						customer_class_id
				),
				ARRAY(
					select 
						alpha
					from 
						prior__alpha
					order by 
						customer_class_id
				)
			) as dirichlet_lpdf
	)
	

-- for (k in 1:K)  
-- phi[k] ~ dirichlet(beta);
-- 
	, "log p(phi|beta)" as (
		with "log dir(phi|beta)" as (
			with "posterior__phi" as (
				select 
					phi,
					customer_class_id,
					product_id
				from 
					customer_class_product
			),
			"prior__beta" as (
				select 
					beta,
					product_id
				from 
					product
			),
			"loop_over_customer_class_ids" as (
				select 
					customer_class_id
				from 
					customer_class
			)
			select
				LoopIndex.customer_class_id,
				dirichlet_lpdf(
					ARRAY(
						select 
							phi 
						from 
							posterior__phi 
						where 
							customer_class_id = LoopIndex.customer_class_id
						order by 
							customer_class_id,
							product_id
					),
					ARRAY(
						select
							beta
						from 
							prior__beta
						order by 
							product_id
					) 
				) as dirichlet_lpdf
			from
				loop_over_customer_class_ids as LoopIndex
		)
		select
			sum(dirichlet_lpdf) as "log p(phi|beta)"
		from
			"log dir(phi|beta)"
	)
	
	-- for (m in 1:M)
	-- z[m] ~ categorical(theta);
	-- 
	, "log p(z|theta)" as (
		with "log cat(z_m|theta)" as (
			with "posterior__z_m" as (
				select 
					customer_class_id,
					customer_id
				from 
					customer
			),
			"prior__theta" as (
				select
					theta,
					customer_class_id
				from 
					customer_class
			)
			select 
				LoopIndex.customer_id,
				categorical_lpmf(
					ARRAY(
						select 
							customer_class_id 
						from 
							posterior__z_m
						where 
							customer_id = LoopIndex.customer_id
						order by 
							customer_id
					),
					ARRAY(
						select
							theta
						from 
							prior__theta
						order by 
							customer_class_id
					)
				) as categorical_lpmf
			from 
				posterior__z_m as LoopIndex
		)
		select
			sum(categorical_lpmf) as "log p(z|theta)"
		from
			"log cat(z_m|theta)"
	)	
	
	-- for (n in 1:N) 
	-- w[n] ~ categorical(phi[z[m[n]]]);
	-- 
	, "log p(w|phi)" as (
      	with "log cat(w_n|phi_z_m_n)" as (
			with "posterior__w_n" as (
				select
					product_id,
					product_purchase_id
				from 
					product_purchase
			),
			-- prior composition: product_purchase_id = n ---> customer_id = m ---> customer_class_id = z ---> phi 
			"prior__m_n" as (
				select
					product_purchase_id,
					customer_id
				from 
					product_purchase
			),
			"prior__z_m" as (
				select 
					customer_id,
					customer_class_id
				from 
					customer
			),
			"prior__phi_z" as (
				select
					customer_class_id,
					phi 
				from 
					customer_class_product
			)
			select
				LoopIndex.product_purchase_id,
				categorical_lpmf(
					ARRAY(
						select 
							product_id 
						from 
							posterior__w_n
						where 
							product_purchase_id = LoopIndex.product_purchase_id
						order by 
							product_purchase_id
					),
					ARRAY(
						select 
							phi 
						from 
							prior__phi_z
						where 
							customer_class_id in (
								select
									customer_class_id
								from 
									prior__z_m
								where 
									customer_id in (
										select
											customer_id
										from 
											prior__m_n
										where 
											product_purchase_id = LoopIndex.product_purchase_id
										order by 
											product_purchase_id
									)
								order by 
									customer_id
							)
						order by 
							customer_class_id,
							product_id
					)
				) as categorical_lpmf
			from 
				posterior__w_n as LoopIndex
		)
		select
			sum(categorical_lpmf) as "log p(w|phi)"
		from
			"log cat(w_n|phi_z_m_n)"
	)
select
  "log dir(theta|alpha)"
  + "log p(phi|beta)"
  + "log p(z|theta)"
  + "log p(w|phi)"
  as "log p(w,z,phi,theta|alpha,beta)"
from
  "log dir(theta|alpha)",
  "log p(phi|beta)",
  "log p(z|theta)",
  "log p(w|phi)"
  ;
