/*
from AVO to source TESTBEELD
see step 02
*/

-- import into TESTBEELD.reference_user_ids
select users.uid as user_id ,external_uid from shared.users;
