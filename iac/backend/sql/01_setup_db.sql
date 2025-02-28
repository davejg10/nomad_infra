-- 1st script to run
-- This will be run as postgresadmin user
-- psql -U myapp_user -d myapp_db -h localhost -f path/to/file.sql
-- This could be run in Terrafrm as a localexec
-- THen we dont have to store the admin creds anywhere, we just store the user creds? or maybe managed identity? for use with file 2.
CREATE DATABASE nomad;

CREATE USER nomad_admin WITH PASSWORD 'mysecretpassword';

GRANT ALL PRIVILEGES ON DATABASE nomad TO nomad_admin;

ALTER DATABASE nomad OWNER TO nomad_admin;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO nomad_admin;

