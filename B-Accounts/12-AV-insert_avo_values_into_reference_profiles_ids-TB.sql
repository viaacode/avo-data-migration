select
	users.uid as user_id,
	profiles.id as profile_id
from
  shared.users as users
join
	users.profiles profiles on profiles.user_id = users.uid;
