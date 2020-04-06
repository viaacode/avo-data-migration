-- in target

DO LANGUAGE PLPGSQL $$
DECLARE
rec record;

BEGIN

FOR rec IN
SELECT
	up.id as profile_id,
	mo.entryuuid as organization_id
FROM migrate.usersprofilesschools mu
JOIN migrate.onderwijsinstellingen mo
	ON mo.o = mu.o
JOIN shared.users su
	ON su.external_uid = mu.external_uid
JOIN users.profiles up
	ON up.user_id = su.uid
LOOP
INSERT INTO users.profile_organizations(profile_id, organization_id)
    VALUES (rec.profile_id, rec.organization_id);
END LOOP;
END;
$$
