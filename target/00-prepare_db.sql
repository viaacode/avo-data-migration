/* ------------------------------------------------------------
Data in target exists?
Clear user and profile tables
before import of user accounts:

- Delete all entries in shared.users and related profiles
- And reset id sequences to 1
------------------------------------------------------------ */

TRUNCATE TABLE shared.users RESTART IDENTITY CASCADE;
TRUNCATE TABLE users.idp_map RESTART IDENTITY;
ALTER SEQUENCE users.profiles_id_seq RESTART WITH 1;
DROP TABLE IF EXISTS migrate.stamboek;
DROP TABLE IF EXISTS migrate.authmap;
DROP TABLE IF EXISTS migrate.scholen;

-- Provision migration tables
CREATE TABLE migrate.stamboek (
  external_uid int primary key,
  stamboek varchar);

CREATE TABLE migrate.authmap (
	external_uid int,
	idp text,
	idp_user_id varchar
);

CREATE TABLE migrate.scholen (
  external_id int primary key,
  entryuuid uuid unique,
  o
)
