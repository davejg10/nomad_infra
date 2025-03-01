-- This script is passed the github managed identity (used in nomad_backend repo) & the web_app identity
-- It creates Postgres users out of them and then assigns them to roles. 
-- The remaining sql scripts are later executed in the nomad_backend repo using the github managed identity.

\set nomad_admin_user :env:NOMAD_ADMIN_USER
\set nomad_backend_user :env:NOMAD_BACKEND_USER

CREATE DATABASE nomad;

SELECT :'nomad_admin_user';

-- These are the managed identity we have created
select * from pgaadauth_create_principal(:'nomad_admin_user', false, false);
select * from pgaadauth_create_principal(:'nomad_backend_user', false, false);

CREATE ROLE nomad_admin;
CREATE ROLE nomad_backend;
CREATE ROLE nomad_function_app; -- We will assign the function app identity to this later when its created

GRANT nomad_admin TO :'nomad_admin_user';
GRANT nomad_backend TO :'nomad_backend_user';

GRANT ALL PRIVILEGES ON DATABASE nomad TO nomad_admin;

ALTER DATABASE nomad OWNER TO nomad_admin;

ALTER ROLE nomad_admin WITH CREATEROLE;