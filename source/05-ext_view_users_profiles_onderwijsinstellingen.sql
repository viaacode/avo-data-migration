-- in source TB

-- scholen in profielen
CREATE OR REPLACE VIEW exportUserProfielSchools AS
SELECT
    u.uid as uid,
    SUBSTRING_INDEX(m.sourceid1, '_', 1) as o,
    REPLACE(m.sourceid1, '_', '-') as ou
FROM
    users u
LEFT JOIN
    profile p ON p.uid = u.uid
LEFT JOIN
    field_data_field_scholen fs ON fs.entity_id = p.pid
LEFT JOIN
    node n ON n.nid = fs.field_scholen_target_id
RIGHT JOIN
    migrate_map_testbeeld_contentonderwijsinstellingen m ON m.destid1 = n.nid
;
