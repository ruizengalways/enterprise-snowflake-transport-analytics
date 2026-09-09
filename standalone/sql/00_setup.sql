-- Portable Transport demo setup.
-- The caller chooses the database, warehouse and role before running this file.

CREATE SCHEMA IF NOT EXISTS DEMO_TRANSPORT
  COMMENT = 'Portable synthetic Transport source data owned by the data repository';
