/* in source TESTBEELD */

-- Drop index on name so we can clean-up values
ALTER TABLE users drop index name;

-- Remove illicit tabs and numbers from usernames
UPDATE users SET name = REPLACE(name, '\t', ' ' );
UPDATE users SET name = IF(name REGEXP '[[:digit:]]+' = 1, SUBSTRING(name, 1, CHAR_LENGTH(name)-1), name);

-- Recreate index on name
CREATE INDEX name ON users (name);
