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
    country_id UUID REFERENCES country(id),
    CONSTRAINT unique_city_per_country UNIQUE (name, country_id)
);

CREATE TYPE transport_type AS ENUM ('TAXI', 'VAN', 'FLIGHT', 'BUS');

CREATE TABLE route_definition (
    id uuid PRIMARY KEY,
    type transport_type NOT NULL,
    source_city_id UUID REFERENCES city(id),
    target_city_id UUID REFERENCES city(id),
    CONSTRAINT chk_different_cities CHECK (source_city_id <> target_city_id)
);

CREATE TABLE route_operator (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    logo_url VARCHAR(200) NOT NULL
);

CREATE TABLE route_instance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cost NUMERIC(10,2) NOT NULL,
    popularity REAL NOT NULL,
    departure TIMESTAMPTZ NOT NULL,
    arrival  TIMESTAMPTZ NOT NULL,
    last_check TIMESTAMPTZ DEFAULT NOW(),
    travel_time INTERVAL GENERATED ALWAYS AS (arrival - departure) STORED,
    route_definition_id UUID REFERENCES route_definition(id),
    route_operator_id UUID  REFERENCES route_operator(id),
    CONSTRAINT chk_positive_amount CHECK (cost >= 0),
    CONSTRAINT chk_valid_travel_time CHECK (arrival > departure)
);