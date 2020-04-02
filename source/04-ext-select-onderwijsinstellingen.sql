-- in source DW

select
	org_uuid::uuid as entryuuid,
	org_id_ldap as o,
	concat_ws('-', org_id_ldap, nullif(split_part(org_unit_id_ldap, '-', 2),'')) as ou
from dwh.dim_int_organization order by o ASC;
