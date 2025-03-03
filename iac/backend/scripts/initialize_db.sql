-- This script is passed the github managed identity (used in nomad_backend repo) & the web_app identity
-- It creates Postgres users out of them and then assigns them to roles. 
-- The remaining sql scripts are later executed in the nomad_backend repo using the github managed identity.

-- CREATE DATABASE nomad;

-- -- These are the managed identity we have created
-- -- These statements actually create the roles in PostgreSQL 
-- -- Notice the difference in quotes when referencing the variable here and when GRANTING the roles below. This is intentional.

select * from pgaadauth_create_principal(:'PSQL_ADMIN', true, false);
select * from pgaadauth_create_principal(:'NOMAD_BACKEND_USER', false, false);


-- CREATE ROLE nomad_backend;
-- CREATE ROLE nomad_function_app; -- We will assign the function app identity to this later when its created

-- GRANT nomad_backend TO :"NOMAD_BACKEND_USER";

SELECT rolname, rolsuper, rolcreaterole FROM pg_roles WHERE rolname = current_user;

GRANT :"PSQL_ADMIN" TO current_user WITH ADMIN OPTION;

ALTER ROLE :"PSQL_ADMIN" WITH CREATEROLE;

GRANT ALL PRIVILEGES ON DATABASE nomad TO :"PSQL_ADMIN";

ALTER DATABASE nomad OWNER TO :"PSQL_ADMIN";

