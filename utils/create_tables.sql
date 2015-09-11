CREATE SCHEMA IF NOT EXISTS rulzurkitchen;

-- Add HStore support
CREATE EXTENSION hstore;

-- Creation of enum types
DROP TYPE IF EXISTS rulzurkitchen.measurement;
DROP TYPE IF EXISTS rulzurkitchen.category;
DROP TYPE IF EXISTS rulzurkitchen.duration;

CREATE TYPE rulzurkitchen.measurement AS ENUM ('L', 'g', 'oz', 'spoon');
CREATE TYPE rulzurkitchen.category AS ENUM ('starter', 'main', 'dessert');
CREATE TYPE rulzurkitchen.duration AS ENUM('0/5', '5/10', '10/15', '15/20',
  '20/25', '25/30', '30/45', '45/60', '60/75', '75/90', '90/120', '120/150');


-- Creation of tables
CREATE TABLE IF NOT EXISTS rulzurkitchen.ingredient (
    id SERIAL PRIMARY KEY,
    name varchar(20)
);

CREATE TABLE IF NOT EXISTS rulzurkitchen.utensil (
    id serial PRIMARY KEY,
    name varchar(20)
);

CREATE TABLE IF NOT EXISTS rulzurkitchen.recipe (
    id serial PRIMARY KEY,
    name varchar(20),
    directions json,
    difficulty smallint CONSTRAINT difficulty_borders CHECK
      (difficulty > 0 AND difficulty < 6),
    duration rulzurkitchen.duration,
    people smallint CONSTRAINT people_borders CHECK
      (people > 0 AND people < 13),
    category rulzurkitchen.category
);

CREATE TABLE IF NOT EXISTS rulzurkitchen.recipe_ingredients (
    fk_recipe integer REFERENCES rulzurkitchen.recipe (id),
    fk_ingredient integer REFERENCES rulzurkitchen.ingredient (id),
    quantity smallint,
    measurement rulzurkitchen.measurement,
    PRIMARY KEY (fk_recipe, fk_ingredient)
);

CREATE TABLE IF NOT EXISTS rulzurkitchen.recipe_utensils (
    fk_recipe integer REFERENCES rulzurkitchen.recipe (id),
    fk_utensil integer REFERENCES rulzurkitchen.utensil (id),
    PRIMARY KEY (fk_recipe, fk_utensil)
);

