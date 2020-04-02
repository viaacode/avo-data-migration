-- in source TB

CREATE OR UPDATE VIEW exportAuthMap AS
SELECT
	uid as external_uid,
	module as idp,
	authname as idp_user_id
FROM authmap a;
