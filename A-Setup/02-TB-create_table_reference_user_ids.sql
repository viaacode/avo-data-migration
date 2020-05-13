/* in source TESTBEELD */

-- Create table for future mapping of Drupal userid's to avo2 uuid's
CREATE TABLE reference_user_ids
(external_uid int primary key,
uid varchar(36));


-- INSERT values from AVO2.shared.users
