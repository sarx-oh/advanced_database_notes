-- LESSON 1
SELECT Title FROM movies;
SELECT Director FROM movies;
SELECT Title, Director FROM movies;
SELECT Title, Year FROM movies;
SELECT * FROM movies;

-- LESSON 2
SELECT id, title FROM movies 
    WHERE id = 6;
SELECT year, title FROM movies 
    where year
    between 2000 and 2010;
SELECT year, title FROM movies 
    where year
    NOT between 2000 and 2010;
SELECT year, title FROM movies 
   where id <6;

-- LESSON 3
SELECT * FROM movies
    where title like "Toy Story%";
SELECT * FROM movies
    where director like "John Lasseter%";  
SELECT * FROM movies
    where director not like "John Lasseter%";  
SELECT * FROM movies
    where title like "WALL-%";  

-- LESSON 4
SELECT DISTINCT director
    FROM movies
    ORDER BY director ASC;

SELECT * FROM movies
    ORDER BY year DESC
    LIMIT 4;

SELECT * FROM movies
    ORDER BY title ASC
    LIMIT 5;

SELECT * FROM movies
    ORDER BY title ASC
    LIMIT 5 OFFSET 5;

-- LESSON 5
SELECT city, population
    FROM north_american_cities
    WHERE country = 'Canada';

SELECT * FROM north_american_cities
    WHERE country = 'United States'
    ORDER BY latitude DESC;

SELECT city FROM north_american_cities
    WHERE longitude < -87.6298
    ORDER BY longitude ASC;

SELECT city, population FROM north_american_cities
    WHERE country = 'Mexico'
    ORDER BY population DESC
    LIMIT 2;

SELECT city, population FROM north_american_cities
    WHERE country = 'United States'
    ORDER BY population DESC
    LIMIT 2 OFFSET 2;

