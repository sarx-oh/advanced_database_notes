-- Analytic Functions: Databases for Developers

--try it 3
select b.*,
       count(*) over (
         partition by shape
       ) bricks_per_shape,
       median(weight) over (
         partition by shape
       ) median_weight_per_shape
from   bricks b
order  by shape, weight, brick_id;

--try it 5
select b.brick_id, b.weight,
       round( avg(weight) over (
         order by brick_id
       ), 2 ) running_average_weight
from   bricks b
order  by brick_id;

--try it 9
select b.*,
       min ( colour ) over (
         order by brick_id
         rows between 2 preceding and 1 preceding
       ) first_colour_two_prev,
       count (*) over (
         order by weight
         range between current row and 1 following
       ) count_values_this_and_next
from   bricks b
order  by weight;

--try it 11
with totals as (
  select b.*,
         sum(weight) over (
           partition by shape
         ) weight_per_shape,
         sum(weight) over (
           order by brick_id
         ) running_weight_by_id
  from bricks b
)
select *
from totals
where weight_per_shape > 4
and   running_weight_by_id > 4
order by brick_id;

--Datalemur
with ranked_employees as (
    select
        e.name,
        d.department_name,
        e.salary,
        dense_rank() over (
            partition by e.department_id
            order by e.salary desc
        ) as salary_rank
    from employee e
    join department d
      on e.department_id = d.department_id
)
select
    department_name,
    name,
    salary
from ranked_employees
where salary_rank <= 3
order by department_name asc, salary desc, name asc;


