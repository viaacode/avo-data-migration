-- in target

WITH tmp AS (
SELECT
	su.uid,
	UPPER(ma.idp),
	ma.idp_user_id
FROM
	migrate.authmap ma
INNER JOIN
	shared.users su ON su.external_uid = ma.external_uid)
INSERT INTO users.idp_map (local_user_id,idp,idp_user_id)
SELECT * from tmp;