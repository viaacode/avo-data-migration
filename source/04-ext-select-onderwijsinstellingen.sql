-- in source DW

select
	org_uuid::uuid as entryuuid,
	CONCAT_WS('-', org_id_ldap, nullif(split_part(org_unit_id_ldap, '-', 2),'')) as o,
	nullif(org_unit_id_ldap, 'n/a') as ou
from dwh.dim_int_organization order by o ASC;
