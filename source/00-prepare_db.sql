/* in source TB
TODO: make sure this is done on restore
*/

-- Cleanup usernames
ALTER TABLE users drop index name;
UPDATE users SET name = REPLACE(name, '\t', ' ' );
CREATE INDEX name ON users (name);
