-- in source TB

CREATE OR REPLACE VIEW viewAuthMap AS
SELECT
	r.user_id as local_user_id,
	UPPER(a.module) as idp,
	a.authname as idp_user_id
FROM authmap a
LEFT JOIN
	reference_user_ids r on r.external_uid = a.uid;
