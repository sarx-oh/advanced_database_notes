--LESSON 10
SELECT MAX(years_employed) as max_years
FROM employees;

SELECT role, AVG(years_employed) as average_years
FROM employees
GROUP BY role;

SELECT building, SUM(years_employed) as total_years
FROM employees
GROUP BY building;

--LESSON 11
SELECT role, COUNT(*) as Number_of_artists
FROM employees
WHERE role = "Artist";

SELECT role, COUNT(*)
FROM employees
GROUP BY role;

SELECT role, SUM(years_employed)
FROM employees
GROUP BY role
HAVING role = "Engineer";

--Try it
select count (distinct shape) number_of_shapes,
       stddev (distinct weight) distinct_weight_stddev
from   bricks;

select shape,sum(weight) as shape_weight
from   bricks
group  by shape;

select shape, sum ( weight )
from   bricks
group  by shape
having sum(weight)<4;

