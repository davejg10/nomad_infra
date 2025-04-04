
-- ======================= NOMAD BACKEND USER========================
-- Grant read access to all tables
GRANT CONNECT ON DATABASE nomad TO nomad_backend;
GRANT USAGE ON SCHEMA public TO nomad_backend;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO nomad_backend;

-- Automatically grant read access to future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT ON TABLES TO nomad_backend;

-- Grant write access to specific tables
-- Will use this for when we have users/preferneces saving routes etc/
-- GRANT INSERT, UPDATE, DELETE ON my_schema.writable_table TO $NOMAD_BACKEND_USER;

-- ======================= NOMAD FUNCTION APP USER========================

-- Grant read/write access to specific tables
GRANT CONNECT ON DATABASE nomad TO nomad_function_app;
GRANT USAGE ON SCHEMA public TO nomad_function_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.country TO nomad_function_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.city TO nomad_function_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.route_definition TO nomad_function_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.route_operator TO nomad_function_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.route_instance TO nomad_function_app;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.route_popularity TO nomad_function_app;


-- ======================= NOMAD Neo4j user (used for debug) ========================
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO neo4j_user;
