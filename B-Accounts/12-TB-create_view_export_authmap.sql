-- in source TB

CREATE OR REPLACE VIEW viewAuthMap AS
SELECT
	r.external_uid as external_uid,
	UPPER(a.module) as idp,
	a.authname as idp_user_id
FROM authmap a
LEFT JOIN
	reference_user_ids r on r.external_uid = a.uid;
