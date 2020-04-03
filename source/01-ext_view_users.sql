/* ------------------------------------------------------------
In source TB
Use existing "viewUsers" view for user extract

# registrationStatus = "Account status" in Tableau
	0: Invited = "Te reactiveren account"
	1: Registered = "Actieve account"
	2: Blocked = "Geblokkeerde account"
	=> only status 2 is_blocked TRUE
------------------------------------------------------------ */

-- Create view for extract
CREATE OR REPLACE VIEW exportUsers AS
SELECT
	vu.userId as external_uid,
	vu.userCreatedOn as created_at,
	LOWER(vu.userMail) as mail,
  -- Map Drupal roles to avo2 base roles in shared.roles
	CASE
		WHEN vu.roleID = 1 THEN NULL -- n.a.
		WHEN vu.roleID = 2 THEN NULL -- n.a.
		WHEN vu.roleID = 21 THEN 10 -- redacteur
		WHEN vu.roleID = 31 THEN 2 -- lesgever
		WHEN vu.roleID = 41 THEN 1 -- beheerder
		WHEN vu.roleID = 51 THEN 3 -- studentlesgever
		WHEN vu.roleID = 61 THEN NULL -- n.a.
		WHEN vu.roleID = 71 THEN NULL -- n.a.
		WHEN vu.roleID = 81 THEN 1 -- beheerder
		WHEN vu.roleID = 91 THEN 1 -- beheerder
		WHEN vu.roleID = 101 THEN 10 -- redacteur
		WHEN vu.roleID = 111 THEN 4 -- leerling
		WHEN vu.roleID = 121 THEN 9 -- educatievepartner
		WHEN vu.roleID = 131 THEN 7 -- educatieveauteur
		WHEN vu.roleID = 141 THEN 6 -- contentpartner
		WHEN vu.roleID = 151 THEN 5 -- medewerker
		WHEN vu.roleID = 161 THEN NULL -- n.a.
	END as role_id,
	vu.roleName as "type",
  -- do not use userFamilyName and userGivenName from viewUsers as they are often empty
	IFNULL(TRIM(vu.userFamilyName), TRIM(REPLACE(u.name, SUBSTRING_INDEX(u.name, ' ', 1), ''))) as last_name,
	IFNULL(TRIM(vu.userGivenName), TRIM(REPLACE(u.name, SUBSTRING_INDEX(u.name, ' ', -1), ''))) as first_name,
	SUBSTRING_INDEX(vu.schoolId, '_', 1) as organisation_id,
  -- Map registration status (invited, registered, blocked) to is_blocked? status
	CASE
		WHEN vu.registrationStatus = 0 THEN FALSE
		WHEN vu.registrationStatus = 1 THEN FALSE
		WHEN vu.registrationStatus = 2 THEN TRUE
	END as is_blocked
FROM viewUsers vu
LEFT JOIN
	users u ON u.uid = vu.userId
LEFT JOIN
    profile p ON p.uid = vu.userId
LEFT JOIN
    field_data_field_registratie_leraarkaart rl ON rl.entity_id = p.pid
GROUP BY vu.userId
ORDER BY userID ASC;
