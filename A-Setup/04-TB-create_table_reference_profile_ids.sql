/* in source TESTBEELD */

-- Create table for future mapping of Drupal profiles to avo2 profiles
CREATE TABLE reference_profile_ids (
  user_id varchar(36) primary key,
  profile_id varchar(36),
  pid int
);


-- INSERT values (external_uid,profile_id) from AVO2.shared.users
-- ISERT values (pid) from TESTBEELD.profile JOIN ON external_uid
