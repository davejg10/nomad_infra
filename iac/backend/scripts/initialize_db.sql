CREATE DATABASE nomad;

-- -- These are the managed identity we have created
-- -- These statements actually create the roles in PostgreSQL 
-- -- Notice the difference in quotes when referencing the variable here and when GRANTING the roles below. This is intentional.
select * from pgaadauth_create_principal(:'NOMAD_BACKEND_USER', false, false);
select * from pgaadauth_create_principal(:'NEO4J_USER', false, false);

CREATE ROLE nomad_backend;
CREATE ROLE neo4j_user;

CREATE ROLE nomad_function_app; -- We will assign the function app identity to this later when its created

GRANT nomad_backend TO :"NOMAD_BACKEND_USER";
GRANT neo4j_user TO :"NEO4J_USER";
