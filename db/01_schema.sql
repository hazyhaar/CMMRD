-- ============================================================================
-- DBA Cockpit - Schema Creation
-- Oracle 19c SE2 compatible
-- ============================================================================

-- Create dedicated schema
-- NOTE: Replace &&cockpit_password with a secure password at install time
CREATE USER cockpit IDENTIFIED BY "&&cockpit_password"
    DEFAULT TABLESPACE users
    TEMPORARY TABLESPACE temp
    QUOTA UNLIMITED ON users;

-- Minimal privileges
GRANT CREATE SESSION TO cockpit;
GRANT CREATE TABLE TO cockpit;
GRANT CREATE PROCEDURE TO cockpit;
GRANT CREATE SEQUENCE TO cockpit;
GRANT CREATE VIEW TO cockpit;
GRANT CREATE TRIGGER TO cockpit;

-- V$ views access for redo log monitoring
GRANT SELECT ON v_$log TO cockpit;
GRANT SELECT ON v_$logfile TO cockpit;
GRANT SELECT ON v_$log_history TO cockpit;
GRANT SELECT ON v_$instance TO cockpit;
GRANT SELECT ON v_$database TO cockpit;
GRANT SELECT ON v_$session TO cockpit;
GRANT SELECT ON v_$tablespace TO cockpit;
GRANT SELECT ON v_$datafile TO cockpit;
GRANT SELECT ON v_$sga TO cockpit;

-- For ORDS (ORDS sets CLIENT_IDENTIFIER automatically, no special grant needed)
