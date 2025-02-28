\set nomad_function_app_user :env:NOMAD_FUNCTION_APP_USER

select * from pgaadauth_create_principal(:'nomad_function_app_user', false, false);

-- This role is created in ../backend/scripts/initialize_db.sql
GRANT nomad_function_app TO :'nomad_function_app_user';
