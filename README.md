# avo-data-migration

## Purpose

This repository contains the SQL-scripts needed to succesfully ETL users and content from AVO v1 to AVO v2.

## Usage

# Process

We start with restoring an online backup locally to speed up the data migration process by avoiding network latency and connection issues. Altering the databases, creating indexes etc. is thus locally sandboxed. It also enables us to easily drop a local copy and restart in case things go awry.

First we backup and restore the avo1 sb_testbeeldond MySQL and avo2 PostgresQL databases. Backup and restore can be done from CLI with the respective database binaries or by using a client, e.g. pgAdmin and Dbeaver.

After locally restoring the databases we need to facilitate the migration from avo1 to avo2 by cleaning up some data and by creating intermediary tables and views in the avo1 database. The views handsomely extract, aggregate and transform the essential data into a readily usable dataset for migration. This gives us the convenience of being able to copy data in the corresponding formats (such as column names) and with the correct avo2 id's directly into the avo2 database without the further need of intermediairy or reference tables in avo2 and post-copy transactions.

# Steps

## Prepare databases

Step 1: backup/restore  avo1 sb_testbeeldond and avo2 databases locally
Step 2: create tables, indexes and views in sb_testbeeldond

## User Accounts & Profiles

Step 3: copy users into avo2 shared.users from avo1 exportUsers view
Step 4: copy avo2 user id's and their corresponding avo1 id's into the table avo1 reference_user_ids
Step 5: copy user profiles into avo2 users.profiles from exportProfiles view
Step 6: copy avo1 authmap entries to avo2 users.idp_map from avo1 exportAuthMap view
Step 7: copy avo2 user profile id's and their corresponding user ids into avo1 reference_user_profile_ids table

By this point we have aggregated all user accounts and their respective profiles from avo2 beta and avo1 into avo2. All avo2 id's are added tot he avo1 db in order to make directly importing the user content possible.

## User content

Step 7: copy mediamosa id's into avo1 reference_media_ids table
Step 8: copy avo1 favorites and watch_laters into avo2 app.item_bookmarks
Step 9: copy users collections excluding already migrated collections into avo2 app.collections from export Collections view
Step 10: copy avo2 collection id's and their corresponding avo1_id's from avo2 to avo1 reference_collection_ids
Step 11: copy collection items from avo1 to avo2 app.collection_fragments from exportFragments view in avo1

Now if a users would log in to avo2 he or she would have an acocunt and prodile where they have all of their collections and bookmarks as they were in avo1.

## Other content

We only migrate news entries since all other pages and bundles differ too much and will be rebuild in avo2.

Step 12: copy news from avo1 to avo2 app.content
Step 13: copy content id's from avo2 to avo1 reference_content_ids
Step 13: copy news body from avo1 to avo2 app.content from exportContentNews view in avo1

## Finalizing

Although users are now migrated, they are not yet able to login with the idp. To enable this we need to import all accounts into ldap and insert the resulting entryUUID's into avo2 users.idp_map mapped to the local_user_id in avo2.
