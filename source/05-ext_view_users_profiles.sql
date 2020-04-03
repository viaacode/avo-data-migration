-- in source TB

-- for users.profiles

CREATE OR REPLACE VIEW exportUsersProfiles AS
SELECT
	vu.userId as external_uid,
	GROUP_CONCAT(DISTINCT(SUBSTRING(rl.field_registratie_leraarkaart_value, 1, 11))) as stamboek,
	SUBSTRING_INDEX(vu.schoolId, '_', 1) as o,
  REPLACE(vu.schoolId, '_', '-') as ou
FROM viewUsers vu
LEFT JOIN
	users u ON u.uid = vu.userId
LEFT JOIN
    profile p ON p.uid = vu.userId
LEFT JOIN
    field_data_field_registratie_leraarkaart rl ON rl.entity_id = p.pid
GROUP BY vu.userId
ORDER BY userID ASC;
