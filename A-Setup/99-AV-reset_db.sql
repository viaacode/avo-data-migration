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
