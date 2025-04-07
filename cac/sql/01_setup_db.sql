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

CREATE TABLE IF NOT EXISTS route_popularity (
    -- Composite primary key
    CONSTRAINT route_popularity_pk PRIMARY KEY (source_city_id, target_city_id),
    source_city_id UUID,
    target_city_id UUID,
    popularity DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    CONSTRAINT fk_route_popularity_source_city FOREIGN KEY (source_city_id) REFERENCES city(id),
    CONSTRAINT fk_route_popularity_target_city FOREIGN KEY (target_city_id) REFERENCES city(id)
);

CREATE TABLE route_definition (
    id uuid PRIMARY KEY,
    transport_type VARCHAR(50) NOT NULL,
    source_city_id UUID REFERENCES city(id),
    target_city_id UUID REFERENCES city(id),
    CONSTRAINT fk_route_popularity FOREIGN KEY (source_city_id, target_city_id) REFERENCES route_popularity(source_city_id, target_city_id),
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
    operator VARCHAR(50) NOT NULL,
    departure_location VARCHAR(100) NOT NULL,
    arrival_location VARCHAR(100) NOT NULL,
    last_check TIMESTAMPTZ NOT NULL,
    travel_time INTERVAL NOT NULL,
    route_definition_id UUID REFERENCES route_definition(id),
    CONSTRAINT chk_positive_amount CHECK (cost >= 0),
    CONSTRAINT chk_valid_travel_time CHECK (arrival > departure)
);