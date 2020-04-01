-- in target

DO LANGUAGE PLPGSQL $$
DECLARE
rec record;

BEGIN

FOR rec IN SELECT * FROM shared.users
LOOP
INSERT INTO users.profiles(user_id, location , alternative_email)
    VALUES (rec.uid, 'BE' , rec.mail);

END LOOP;
END;
$$
