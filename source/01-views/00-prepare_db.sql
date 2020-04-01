-- Cleanup tabs in names
ALTER TABLE users drop index name;
UPDATE users SET name = REPLACE(name, '\t', ' ' );
CREATE INDEX name ON users (name);
