
-- ======================= NOMAD BACKEND USER========================
-- Grant read access to all tables
GRANT CONNECT ON DATABASE nomad TO $NOMAD_BACKEND_USER;
GRANT USAGE ON SCHEMA public TO $NOMAD_BACKEND_USER;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO $NOMAD_BACKEND_USER;

-- Automatically grant read access to future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT ON TABLES TO $NOMAD_BACKEND_USER;

-- Grant write access to specific tables
-- Will use this for when we have users/preferneces saving routes etc/
-- GRANT INSERT, UPDATE, DELETE ON my_schema.writable_table TO $NOMAD_BACKEND_USER;

-- ======================= NOMAD FUNCTION APP USER========================

-- Grant read access to specific tables
GRANT CONNECT ON DATABASE nomad TO $NOMAD_FUNCTION_APP_USER;
GRANT USAGE ON SCHEMA public TO $NOMAD_FUNCTION_APP_USER;
GRANT SELECT, INSERT, UPDATE ON public.country TO $NOMAD_FUNCTION_APP_USER;
GRANT SELECT, INSERT, UPDATE ON public.city TO $NOMAD_FUNCTION_APP_USER;
GRANT SELECT, INSERT, UPDATE ON public.route_definition TO $NOMAD_FUNCTION_APP_USER;
GRANT SELECT, INSERT, UPDATE ON public.route_operator TO $NOMAD_FUNCTION_APP_USER;
GRANT SELECT, INSERT, UPDATE ON public.route_instance TO $NOMAD_FUNCTION_APP_USER;