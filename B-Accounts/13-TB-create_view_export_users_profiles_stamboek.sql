-- in source TB

CREATE OR REPLACE VIEW exportStamboek AS
SELECT
    u.uid as external_uid,
    GROUP_CONCAT(DISTINCT(SUBSTRING(rl.field_registratie_leraarkaart_value, 1, 11))) as stamboek
FROM users u
LEFT JOIN
    profile p ON p.uid = u.uid
LEFT JOIN
    field_data_field_registratie_leraarkaart rl ON rl.entity_id = p.pid
WHERE rl.field_registratie_leraarkaart_value IS NOT NULL
GROUP BY u.uid
ORDER BY u.uid ASC;
