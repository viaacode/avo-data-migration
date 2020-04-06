/* in source TESTBEELD */

-- Drop index on name so we can clean-up values
ALTER TABLE users drop index name;

-- Remove illicit tabs from usernames
UPDATE users SET name = REPLACE(name, '\t', ' ' );

-- Recreate index on name
CREATE INDEX name ON users (name);
