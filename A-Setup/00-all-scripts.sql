/* in source TESTBEELD */

-- Drop index on name so we can clean-up values fast
ALTER TABLE users drop index name;

-- Remove illicit tabs and suffixes from usernames
UPDATE users SET name = REPLACE(name, '\t', ' ' );
UPDATE users SET name = IF(name REGEXP '[[:digit:]]+' = 1, SUBSTRING(name, 1, CHAR_LENGTH(name)-1), name);

-- Create tables for future mapping of Drupal id's to avo2 (uu)id's
CREATE TABLE reference_user_ids (
	user_id varchar(36) primary key,
	external_uid int default null
);

CREATE TABLE reference_profile_ids (
  user_id varchar(36) primary key,
  profile_id varchar(36)
);

CREATE TABLE reference_item_ids (
	mediamosa_id text,
	external_id text,
	uuid varchar(36) UNIQUE,
	type_id int,
	asset_type text
);

CREATE TABLE reference_users_profiles (
	external_uid int primary key,
	stamboek varchar(11)
);

CREATE TABLE reference_collection_ids (
	id int primary key,
	uuid varchar(36)
);

CREATE TABLE exported_users (
	id int primary key
);

CREATE TABLE exportedCollections (
	id int primary key
);

-- create indexes to avoid very slow queries in mysql

CREATE INDEX name ON users (name);
CREATE INDEX external_uid ON reference_user_ids (external_uid);
CREATE INDEX user_id ON reference_user_ids (user_id);
CREATE INDEX uid ON authmap (uid);
CREATE INDEX id on referenceCollectionIds (id);
CREATE INDEX uuid on referenceCollectionIds (uuid);
CREATE INDEX id on exportedUsers (id);
CREATE INDEX nid on node (nid);
CREATE INDEX mediamosa_id ON reference_item_ids (mediamosa_id(36));
CREATE INDEX field_assets_asset_reference_id ON field_data_field_assets (field_assets_asset_reference_id(36));

-- Create views for data export

/* ------------------------------------------------------------
View for extracting user accounts base on viewUsers view

# registrationStatus = "Account status" in Tableau
	0: Invited = "Te reactiveren account"
	1: Registered = "Actieve account"
	2: Blocked = "Geblokkeerde account"
	=> only status 2 is_blocked TRUE
------------------------------------------------------------ */

-- > into shared.users
CREATE OR REPLACE VIEW exportUsers AS
SELECT
	vu.userCreatedOn as created_at,
	LOWER(vu.userMail) as mail,
  -- Map Drupal roles to avo2 base roles in shared.roles
	CAST(LEFT(GROUP_CONCAT(DISTINCT(CASE
		WHEN vu.roleID = 1 THEN NULL -- n.a.
		WHEN vu.roleID = 2 THEN NULL -- n.a.
		WHEN vu.roleID = 21 THEN 10 -- redacteur
		WHEN vu.roleID = 31 THEN 2 -- lesgever
		WHEN vu.roleID = 41 THEN 1 -- beheerder
		WHEN vu.roleID = 51 THEN 3 -- studentlesgever
		WHEN vu.roleID = 61 THEN NULL -- n.a.
		WHEN vu.roleID = 71 THEN NULL -- n.a.
		WHEN vu.roleID = 81 THEN 1 -- beheerder
		WHEN vu.roleID = 91 THEN 1 -- beheerder
		WHEN vu.roleID = 101 THEN 10 -- redacteur
		WHEN vu.roleID = 111 THEN 4 -- leerling
		WHEN vu.roleID = 121 THEN 9 -- educatievepartner
		WHEN vu.roleID = 131 THEN 7 -- educatieveauteur
		WHEN vu.roleID = 141 THEN 6 -- contentpartner
		WHEN vu.roleID = 151 THEN 5 -- medewerker
		WHEN vu.roleID = 161 THEN NULL -- n.a.
	END)),1) AS unsigned) as role_id,
	-- vu.roleName as "type",
  -- do not use userFamilyName and userGivenName from viewUsers as they are often empty
	GROUP_CONCAT(DISTINCT(IFNULL(TRIM(vu.userGivenName), SUBSTRING_INDEX(TRIM(u.name), ' ', 1)))) as first_name,
	GROUP_CONCAT(DISTINCT(IFNULL(TRIM(vu.userFamilyName), TRIM(REPLACE(u.name, SUBSTRING_INDEX(u.name, ' ', 1), ''))))) as last_name,
  -- SUBSTRING_INDEX(vu.schoolId, '_', 1) as organisation_id,
  -- Map registration status (invited, registered, blocked) to is_blocked? status
	vu.userId as external_uid,
	CASE
		WHEN vu.registrationStatus = 0 THEN FALSE
		WHEN vu.registrationStatus = 1 THEN FALSE
		WHEN vu.registrationStatus = 2 THEN TRUE
	END as is_blocked
FROM viewUsers vu
LEFT JOIN
	users u ON u.uid = vu.userId
LEFT JOIN
    profile p ON p.uid = vu.userId
WHERE vu.userId NOT IN  (SELECT id from exported_users)
GROUP BY vu.userId
ORDER BY userID ASC;

-- > into users.idp_map
CREATE OR REPLACE VIEW exportAuthMap AS
SELECT
	r.user_id as local_user_id,
	UPPER(a.module) as idp,
	a.authname as idp_user_id
FROM reference_user_ids r
INNER JOIN
	authmap a on a.uid = r.external_uid;

-- > into users.profiles
CREATE OR REPLACE VIEW exportUsersProfiles AS
SELECT distinct
	r.user_id as user_id,
	CONCAT(u.first_name, " ", u.last_name) as alias,
	GROUP_CONCAT(DISTINCT(SUBSTRING(rl.field_registratie_leraarkaart_value, 1, 11))) as stamboek,
	u.mail as alternative_email
FROM reference_user_ids r
JOIN
	exportUsers u ON u.external_uid = r.external_uid
LEFT JOIN
	"profile" p on p.uid = r.external_uid
LEFT JOIN
	field_data_field_registratie_leraarkaart rl on rl.entity_id = p.pid
GROUP BY r.user_id;

-- > into app.item_bookmarks
CREATE OR REPLACE VIEW exportBookmarks AS
SELECT
  rp.profile_id as owner_profile_id,
  ri.uuid as item_id,
  n.uid as external_uid,
  substring_index(GROUP_CONCAT(from_unixtime(field_assets_created, "%Y-%m-%d %T.%f+00")),',', -1) as created_at,
  ri.type_id as type_id
FROM
    field_data_field_assets as f
LEFT JOIN
	node n ON f.entity_id = n.nid
LEFT JOIN
	reference_user_ids ru on ru.external_uid = n.uid
LEFT JOIN
    reference_profile_ids rp on rp.user_id = ru.user_id
INNER JOIN
	reference_item_ids ri on ri.mediamosa_id = f.field_assets_asset_reference_id
WHERE
    n.type = "collectie"
    AND (n.title = "favourite"
    OR n.title = "watch_later")
    -- AND rp.profile_id is not null
GROUP BY owner_profile_id,external_id,n.uid,type_id;

-- View for collection ids
CREATE OR REPLACE VIEW viewCollectionIds AS
SELECT nid FROM node n
WHERE
  type = "collectie"
  AND NOT (title = "favourite"
           OR title = "watch_later");

-- > into app.collections
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
	AND NOT n.nid IN (select id from exported_collections);

-- Export collection description as first text fragment
-- > into app.collection_fragments
CREATE OR REPLACE VIEW exportCollectionBody AS
select
    n.nid AS avo1_id,
    recol.uuid as collection_uuid,
    -1 AS external_id,
    n.title AS custom_title,
    b.body_value AS custom_description,
    from_unixtime(created, "%Y-%m-%d %T.%f+00") AS created_at,
    from_unixtime(changed, "%Y-%m-%d %T.%f+00") AS updated_at,
    'TEXT' as "type",
    true AS use_custom_fields,
    0 AS position
FROM
    node AS n
LEFT JOIN field_data_body AS b ON
    n.nid = b.entity_id
LEFT JOIN reference_collection_ids recol on recol.id = n.nid
WHERE type = "collectie" AND NOT (title = "favourite" OR title = "watch_later")
AND n.nid NOT IN (select id from exportedCollections);

-- Export collection items (media fragments)
-- > into app.collection_fragments
CREATE OR REPLACE VIEW exportFragments AS
SELECT
    entity_id AS collection_id,
    recol.uuid as collection_uuid,
    ri.external_id AS external_id,
    from_unixtime(field_assets_created, "%Y-%m-%d %T.%f+00") AS created_at,
    from_unixtime(field_assets_created, "%Y-%m-%d %T.%f+00") AS updated_at,
    field_assets_start AS start_oc,
    field_assets_end AS end_oc,
    field_assets_asset_reference AS custom_title,
    delta+1 AS position,
    'ITEM' AS "type",
    true AS use_custom_fields
FROM
    field_data_field_assets AS f
LEFT JOIN reference_collection_ids recol on recol.id = f.entity_id
LEFT JOIN reference_item_ids ri on ri.mediamosa_id = cast(field_assets_asset_reference_id as char)
WHERE
    entity_id in (SELECT nid from viewCollectionIds)
AND entity_id NOT IN (select id from exportedCollections)
AND recol.uuid is not null;
