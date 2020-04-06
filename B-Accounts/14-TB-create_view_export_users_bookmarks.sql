-- items in collections that are favorites or watch_laters with owner_profile_id
SELECT
  rp.profile_id as owner_profile_id,
  ri.external_id as external_id,
  n.uid as external_uid,
  from_unixtime(field_assets_created, "%Y-%m-%d %T.%f+00") as created_at,
  1 as type_id --  => TODO: add type in reference_item_ids
FROM
    field_data_field_assets as f
LEFT JOIN
	node n ON f.entity_id = n.nid
JOIN
	reference_user_ids ru on ru.external_uid = n.uid
JOIN
    reference_profile_ids rp on rp.user_id = ru.user_id
JOIN
	reference_item_ids ri on ri.mediamosa_id = f.field_assets_asset_reference_id
WHERE
    n.type = "collectie"
    AND (n.title = "favourite"
    OR n.title = "watch_later");
