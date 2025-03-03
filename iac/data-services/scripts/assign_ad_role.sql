
select * from pgaadauth_create_principal(:'NOMAD_FUNCTION_APP_USER', false, false);

-- This role is created in ../backend/scripts/initialize_db.sql
GRANT nomad_function_app TO :'NOMAD_FUNCTION_APP_USER';
