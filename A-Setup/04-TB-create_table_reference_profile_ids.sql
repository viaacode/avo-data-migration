/* in source TESTBEELD */

-- Create table for future mapping of Drupal profiles to avo2 profiles
CREATE TABLE reference_profile_ids (
  user_id varchar(36) primary key,
  profile_id varchar(36)
);

-- INSERT values (external_uid,profile_id) from AVO2.shared.users
