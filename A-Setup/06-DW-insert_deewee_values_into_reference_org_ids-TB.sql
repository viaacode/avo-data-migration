/* from source DEEWEE */

-- insert values into TESTBEELD.reference_orgs from DEEWEE select statement

select
	org_uuid::varchar(36) as entryuuid,
	nullif(split_part(org_id_ldap, '-', 1), 'n/a') as org_id_ldap,
	left(nullif(org_unit_id_ldap, 'n/a'), -4) as org_unit_id_ldap
from dwh.dim_int_organization
