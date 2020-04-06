-- in source TB

-- all selected schools in user profiles (multivalue so multiple uid's ok)
CREATE OR REPLACE VIEW exportUsersProfilesOrganizations AS
SELECT
    u.uid as uid,
    -- u.name,
    -- n.title,
    SUBSTRING_INDEX(m.sourceid1, '_', 1) as organization_id,
    REPLACE(m.sourceid1, '_', '-') as unit_id
FROM
    field_data_field_scholen fs
LEFT JOIN
    profile p ON p.pid = fs.entity_id
LEFT JOIN
    users u ON u.uid = p.uid
LEFT JOIN
    node n ON n.nid = fs.field_scholen_target_id
JOIN
    migrate_map_testbeeld_contentonderwijsinstellingen m ON m.destid1 = n.nid
;
