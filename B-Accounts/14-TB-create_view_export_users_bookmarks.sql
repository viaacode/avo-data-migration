-- Set of collections that are favorites or watch_laters with uid
CREATE OR REPLACE VIEW exportFavorites AS
SELECT
  n.uid as external_uid,
  field_assets_asset_reference_id as external_id,
  from_unixtime(field_assets_created, "%Y-%m-%d %T.%f+00") as created_at
  1 as type_id
FROM
    field_data_field_assets as f
LEFT JOIN node AS n ON
    f.entity_id = n.nid;
WHERE
    n.type = "collectie"
    AND (n.title = "favourite"
    OR n.title = "watch_later");

select * from exportFavorites limit 50;
