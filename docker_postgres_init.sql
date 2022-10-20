-- https://onexlab-io.medium.com/docker-compose-postgres-multiple-database-bbc0816db603
CREATE USER outlineusr WITH PASSWORD 'outlinepwd' CREATEDB;
CREATE DATABASE outline
    WITH 
    OWNER = outlineusr
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.utf8'
    LC_CTYPE = 'en_US.utf8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;
