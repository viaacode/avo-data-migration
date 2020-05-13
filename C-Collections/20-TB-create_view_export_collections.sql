-- Export collections
CREATE OR REPLACE VIEW exportCollections AS
SELECT
    cast(n.nid AS char) as avo1_id,
    n.title,
    rpid.user_id AS author_uid,
    n.uid AS author_external_uid,
    rpid.profile_id AS owner_profile_id,
    CASE
        WHEN n.status = 0 THEN "FALSE"
        ELSE "TRUE"
    END AS is_public,
    from_unixtime(n.created, "%Y-%m-%d %T.%f+00") AS created_at,
    from_unixtime(n.changed, "%Y-%m-%d %T.%f+00") AS updated_at,
    3 AS type_id
FROM
    node AS n
JOIN reference_user_ids ruid ON ruid.external_uid = n.uid
JOIN reference_profile_ids rpid ON rpid.user_id = ruid.user_id
WHERE
    n.type = "collectie"
    AND NOT (n.title = "favourite"
    OR n.title = "watch_later")
	-- use this to exclude previously migrated collections
  -- AND not n.nid in
	;
