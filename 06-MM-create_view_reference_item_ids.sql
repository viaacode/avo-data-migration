/* in source MEDIAMOSA */

CREATE OR REPLACE VIEW viewPids AS
SELECT
    CAST(mam.asset_id AS CHAR CHARACTER SET utf8) as mediamosa_id,
    CAST(mam.val_char AS CHAR CHARACTER SET utf8) as external_id
FROM mediamosa_asset_metadata as mam
INNER JOIN mediamosa_asset as ma on
    mam.asset_id = ma.asset_id
WHERE mam.prop_id = 101
    -- AND (ma.asset_type = "video" or ma.asset_type = "audio")
    AND ma.app_id = 2;

-- INSERT INTO TESTBEELD.reference_pids
