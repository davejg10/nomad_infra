-- Active: 1740660744988@@127.0.0.1@5432@nomad
-- This script should be executed against the `nomad` database

CREATE TABLE country (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT
);

CREATE TABLE city (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    city_metrics JSONB NOT NULL,
    country_id UUID REFERENCES country(id),
    CONSTRAINT unique_city_per_country UNIQUE (name, country_id)
);

-- CREATE TYPE transport_type AS ENUM ('TAXI', 'VAN', 'FLIGHT', 'BUS', 'TRAIN');
-- CREATE CAST (varchar AS transport_type) WITH INOUT AS IMPLICIT; -- required to cast from java enum to psql enum

CREATE TABLE route_definition (
    id uuid PRIMARY KEY,
    popularity REAL NOT NULL,
    transport_type VARCHAR(50) NOT NULL,
    source_city_id UUID REFERENCES city(id),
    target_city_id UUID REFERENCES city(id),
    CONSTRAINT chk_different_cities CHECK (source_city_id <> target_city_id)
);

-- CREATE TABLE route_operator (
--     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
--     name VARCHAR(100) NOT NULL,
--     logo_url VARCHAR(200) NOT NULL
-- );

CREATE TABLE route_instance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cost NUMERIC(10,2) NOT NULL,
    search_date DATE NOT NULL,
    url TEXT NOT NULL,
    departure TIMESTAMPTZ NOT NULL,
    arrival  TIMESTAMPTZ NOT NULL,
    last_check TIMESTAMPTZ NOT NULL,
    travel_time INTERVAL NOT NULL,
    route_definition_id UUID REFERENCES route_definition(id),
    CONSTRAINT chk_positive_amount CHECK (cost >= 0),
    CONSTRAINT chk_valid_travel_time CHECK (arrival > departure)
);