/* in source TESTBEELD */

-- Drop index on name so we can clean-up values fast
ALTER TABLE users drop index name;

-- Remove illicit tabs and suffixes from usernames
UPDATE users SET name = REPLACE(name, '\t', ' ' );
UPDATE users SET name = IF(name REGEXP '[[:digit:]]+' = 1, SUBSTRING(name, 1, CHAR_LENGTH(name)-1), name);

-- recreate index
CREATE INDEX name ON users (name);

-- Create tables for mapping of Drupal id's to avo2 (uu)id's
-- Add indexes for speed
CREATE TABLE reference_user_ids (
	user_id varchar(36) primary key,
	external_uid int default null
);

CREATE INDEX external_uid ON reference_user_ids (external_uid);
CREATE INDEX user_id ON reference_user_ids (user_id);

CREATE TABLE reference_profile_ids (
  user_id varchar(36) primary key,
  profile_id varchar(36),
  external_uid int
);

CREATE INDEX external_uid ON reference_profile_ids (external_uid);
CREATE INDEX user_id ON reference_profile_ids (user_id);
CREATE INDEX profile_id ON reference_profile_ids (profile_id);

CREATE TABLE reference_item_ids (
	mediamosa_id varchar(32),
	external_id varchar,
	-- uuid varchar(36) UNIQUE,
	type_id int,
	asset_type text
);
CREATE INDEX mediamosa_id ON reference_item_ids (mediamosa_id(36));

CREATE TABLE reference_item_uuids (
	external_id varchar(32) primary key,
	uuid varchar(36)
);
CREATE INDEX external_id ON reference_item_uuids (external_id);

CREATE TABLE reference_users_profiles (
	external_uid int primary key,
	stamboek varchar(11)
);

CREATE TABLE reference_collection_ids (
	id int primary key,
	uuid varchar(36)
);
CREATE INDEX id on reference_collection_ids (id);
CREATE INDEX uuid on reference_collection_ids (uuid);

CREATE TABLE exported_users (
	user_id varchar(36) primary key,
	external_uid int NOT NULL
);
CREATE INDEX external_uid on exported_users (external_uid);

CREATE TABLE exported_collections (
	id int primary key,
	uuid varchar(36)
);
CREATE INDEX id on exported_collections (id);

-- create missing indexes on Drupal tables to avoid very slow queries in mysql

CREATE INDEX uid ON authmap (uid);
CREATE INDEX nid on node (nid);
CREATE INDEX field_assets_asset_reference_id ON field_data_field_assets (field_assets_asset_reference_id(36));
CREATE INDEX entity_id ON field_data_field_assets (entity_id);

-- Create views for data export

/* ------------------------------------------------------------
View for extracting user accounts base on viewUsers view

# registrationStatus = "Account status" in Tableau
	0: Invited = "Te reactiveren account"
	1: Registered = "Actieve account"
	2: Blocked = "Geblokkeerde account"
	=> only status 2 is_blocked TRUE
------------------------------------------------------------ */
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
WHERE vu.userId NOT IN (SELECT external_uid from exported_users)
GROUP BY vu.userId
ORDER BY userID ASC;

-- > into shared.users
SELECT * from exportUsers;

-- external auth mapping
CREATE OR REPLACE VIEW exportAuthMap AS
SELECT
	r.user_id as local_user_id,
	UPPER(a.module) as idp,
	a.authname as idp_user_id
FROM reference_user_ids r
INNER JOIN authmap a ON a.uid = r.external_uid;

-- > into users.idp_map
SELECT * FROM exportAuthMap;

-- > basic info for user profiles
CREATE OR REPLACE VIEW exportUsersProfiles AS
SELECT DISTINCT
	r.user_id as user_id,
	r.external_uid as alias,
	GROUP_CONCAT(DISTINCT(SUBSTRING(rl.field_registratie_leraarkaart_value, 1, 11))) as stamboek,
	u.mail as alternative_email
FROM
	reference_user_ids r
JOIN
	exportUsers u ON u.external_uid = r.external_uid
LEFT JOIN
	profile p ON p.uid = r.external_uid
LEFT JOIN
	field_data_field_registratie_leraarkaart rl ON rl.entity_id = p.pid
WHERE r.user_id NOT IN (SELECT external_uid FROM exported_users)
GROUP BY r.user_id;

-- > into users.profiles
SELECT * FROM exportUsersProfiles;

-- view for favorites and watch_laters (items)
CREATE OR REPLACE VIEW exportBookmarks AS
SELECT
  rp.profile_id as profile_id,
  riu.uuid as item_id,
  -- ri.external_id as external_id,
  substring_index(GROUP_CONCAT(from_unixtime(field_assets_created, "%Y-%m-%d %T.%f+00")),',', -1) as created_at
FROM
    field_data_field_assets as f
LEFT JOIN
	node n ON f.entity_id = n.nid
LEFT JOIN
	reference_user_ids ru ON ru.external_uid = n.uid
LEFT JOIN
    reference_profile_ids rp ON rp.user_id = ru.user_id
INNER JOIN
	reference_item_ids ri ON ri.mediamosa_id = f.field_assets_asset_reference_id
INNER JOIN
	reference_item_uuids riu ON riu.external_id = ri.external_id
WHERE
    n.type = "collectie"
    AND (n.title = "favourite"
    OR n.title = "watch_later")
    AND rp.profile_id IS NOT NULL
GROUP BY profile_id,item_id;

-- > into app.item_bookmarks
SELECT * FROM exportBookmarks;

-- View for collection ids
CREATE OR REPLACE VIEW viewCollectionIds AS
SELECT nid FROM node n
WHERE
  type = "collectie"
  AND NOT (title = "favourite"
           OR title = "watch_later")
  AND NOT n.nid IN (SELECT id FROM exported_collections);

-- > into app.collections
CREATE OR REPLACE VIEW exportCollections AS
SELECT
    cast(n.nid AS char) AS avo1_id,
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
LEFT JOIN
	reference_user_ids ruid ON ruid.external_uid = n.uid
LEFT JOIN
	reference_profile_ids rpid ON rpid.user_id = ruid.user_id
WHERE
    n.nid IN (SELECT nid FROM viewCollectionIds);

-- > into app.collections
SELECT * FROM exportCollections;

-- View collection description as first fragment of type 'TEXT'
CREATE OR REPLACE VIEW exportCollectionBody AS
SELECT
    n.nid AS avo1_id,
    recol.uuid as collection_uuid,
    -1 AS external_id,
    n.title AS custom_title,
    b.body_value AS custom_description,
    from_unixtime(created, "%Y-%m-%d %T.%f+00") AS created_at,
    from_unixtime(changed, "%Y-%m-%d %T.%f+00") AS updated_at,
    'TEXT' AS "type",
    true AS use_custom_fields,
    0 AS position
FROM
    node AS n
LEFT JOIN
	field_data_body AS b ON b.entity_id = n.nid
LEFT JOIN
	reference_collection_ids recol on recol.id = n.nid
WHERE n.nid IN (SELECT nid FROM viewCollectionIds);

-- > into app.collection_fragments
select * from exportCollectionBody;

-- Export collection items (media fragments)
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
LEFT JOIN
  reference_collection_ids recol on recol.id = f.entity_id
LEFT JOIN
	reference_item_ids ri on ri.mediamosa_id = cast(field_assets_asset_reference_id as char)
WHERE
  entity_id in (SELECT nid from viewCollectionIds)
AND recol.uuid is not null;

-- > into app.collection_fragments
select * from exportFragments;

-- News items
-- > into app.content
select
	n.title as title,
	b.body_value as description,
	n.status as is_public,
	from_unixtime(n.created, "%Y-%m-%d %T.%f+00") AS created_at,
    from_unixtime(n.changed, "%Y-%m-%d %T.%f+00") AS updated_at,
    "NIEUWS_ITEM" as content_type,
    p.profile_id as user_profile_id
from
	node n
join
	field_data_body b on b.entity_id = n.nid
left join
	reference_profile_ids p on p.external_uid = n.uid
where n.type = "nieuws";

-- This collection is a copy of that collection
-- > into app.collection_relations
select
	r1.uuid as subject,
	'IS_COPY_OF' as predicate,
	r2.uuid as object
from field_data_field_copy_from c
join
	reference_collection_ids r1 on r1.id = c.entity_id
join
	reference_collection_ids r2 on r2.id= c.field_copy_from_target_id ;
