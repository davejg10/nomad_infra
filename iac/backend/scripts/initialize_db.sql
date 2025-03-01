-- This script is passed the github managed identity (used in nomad_backend repo) & the web_app identity
-- It creates Postgres users out of them and then assigns them to roles. 
-- The remaining sql scripts are later executed in the nomad_backend repo using the github managed identity.

CREATE DATABASE nomad;

SELECT :'NOMAD_ADMIN_USER';

-- These are the managed identity we have created
select * from pgaadauth_create_principal(:'NOMAD_ADMIN_USER', false, false);
select * from pgaadauth_create_principal(:'NOMAD_BACKEND_USER', false, false);

CREATE ROLE nomad_admin;
CREATE ROLE nomad_backend;
CREATE ROLE nomad_function_app; -- We will assign the function app identity to this later when its created

GRANT nomad_admin TO :NOMAD_ADMIN_USER;
GRANT nomad_backend TO :NOMAD_BACKEND_USER;

GRANT ALL PRIVILEGES ON DATABASE nomad TO nomad_admin;

ALTER DATABASE nomad OWNER TO :NOMAD_ADMIN_USER;

ALTER ROLE nomad_admin WITH CREATEROLE;