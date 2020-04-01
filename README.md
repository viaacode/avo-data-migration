# avo-data-migration

## Purpose

This repository contains the ETL-scripts needed to succesfully migrate users and content from AVO v1 to AVO v2.

## Usage

### 1. Prepare source

Run ```source/00-prepare_db.sql```

First clean-up some data. Then create the views for the datasets we need to migrate. These views handsomely extract, aggregate and transform the essential data into a readily usable dataset for migration.

### 2. Prepare target

Run ```target/00-prepare_db.sql```

We need some temporary _migrate tables_ to hold reference data and id's for further transformation and loading of the data into the new schema's.
Remove records for users and profiles before performing an ETL on a target database where residual data exists.

### 3. Perform ETL steps

| Step 	| Description                      	| Source      	| Target         	| Script 	|
|------	|----------------------------------	|-------------	|----------------	|--------	|
| 1    	| Import user accounts             	| exportUsers 	| shared.users   	|        	|
| 2    	| Create profile records for users 	|             	| users.profiles 	|        	|
| 3    	| Add stamboek to profiles         	|             	| users.profiles 	|        	|
