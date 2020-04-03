/* ------------------------------------------------------------
Data in target exists?
Clear user and profile tables
before import of user accounts:

- Delete all entries in shared.users and related profiles
- And reset id sequences to 1
------------------------------------------------------------ */

TRUNCATE TABLE shared.users RESTART IDENTITY CASCADE;
TRUNCATE TABLE users.idp_map RESTART IDENTITY;
TRUNCATE TABLE users.profile_organizations RESTART IDENTITY CASCADE;
DROP TABLE IF EXISTS migrate.users_profiles_stamboek;
DROP TABLE IF EXISTS migrate.users_authmap;
DROP TABLE IF EXISTS migrate.ref_organizations;
DROP TABLE IF EXISTS migrate.ref_mediamosa_items;

-- Provision migration tables
CREATE TABLE migrate.users_profiles_stamboek (
external_uid int primary key,
stamboek varchar(11)
);

CREATE TABLE migrate.users_authmap (
	external_uid int,
	idp text,
	idp_user_id varchar
);

CREATE TABLE migrate.ref_organizations (
  entryuuid primary key,
  o varchar,
  ou varchar
);

CREATE TABLE migrate.ref_mediamosa_items (
mediamosa_id varchar unique,
external_id varchar,
type_label text
);
