
select * from pgaadauth_create_principal(:'NOMAD_FUNCTION_APP_ADMIN_API', false, false);
select * from pgaadauth_create_principal(:'NOMAD_FUNCTION_APP_JOB_ORCHESTRATOR', false, false);

-- This role is created in ../backend/scripts/initialize_db.sql
GRANT nomad_function_app TO :'NOMAD_FUNCTION_APP_ADMIN_API';
GRANT nomad_function_app TO :'NOMAD_FUNCTION_APP_JOB_ORCHESTRATOR';
