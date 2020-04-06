-- TODO: make alternative_email in users.profiles nullable

-- in target

DO LANGUAGE PLPGSQL $$
DECLARE
rec record;

BEGIN

FOR rec IN
SELECT
    su.uid as uid,
	su.mail as mail, -- included due to NOT NULL constraint on alternative_email
    ms.stamboek as stamboek
FROM shared.users su
LEFT JOIN migrate.users_profiles_stamboek ms ON su.uid = ms.user_id
LOOP
INSERT INTO users.profiles(user_id, location, alternative_email, stamboek)
    VALUES (rec.uid, 'BE', rec.mail, rec.stamboek);
END LOOP;
END;
$$
