-- in target

UPDATE users.profiles up
	SET stamboek = sq.stamboek
FROM (SELECT
	  	su.external_uid as external_uid,
	  	su.uid as user_id,
	  	ms.stamboek as stamboek
	 FROM shared.users su
	 LEFT JOIN users.profiles up ON su.uid = up.user_id
	 INNER JOIN migrate.stamboek ms ON su.external_uid = ms.external_uid) as sq
WHERE up.user_id = sq.user_id;
