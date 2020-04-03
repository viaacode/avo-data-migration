-- in source DW

select
	org_uuid::uuid as entryuuid,
	nullif(split_part(org_id_ldap, '-', 1), 'n/a') as org_id_ldap,
	left(nullif(org_unit_id_ldap, 'n/a'), -4) as org_unit_id_ldap
from dwh.dim_int_organization
