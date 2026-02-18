-- ============================================================================
-- DBA Cockpit - Master Install Script
-- Run as SYS or a privileged user
-- Usage: @99_install.sql
-- ============================================================================

PROMPT ============================================
PROMPT DBA Cockpit - Installation
PROMPT Oracle 19c SE2 + ORDS 24.x
PROMPT ============================================

PROMPT [1/9] Creating schema...
@01_schema.sql

PROMPT [2/9] Creating catalog tables...
@02_tables_catalog.sql

PROMPT [3/9] Creating desk tables...
@03_tables_desk.sql

PROMPT [4/9] Creating auth tables...
@04_tables_auth.sql

PROMPT [5/9] Creating audit tables...
@05_tables_audit.sql

PROMPT [6/9] Installing packages...
@06_pkg_util.sql
@07_pkg_auth.sql
@08_pkg_redo.sql
@09_pkg_data.sql
@10_pkg_desk.sql

PROMPT [7/9] Configuring ORDS endpoints...
@11_ords_endpoints.sql

PROMPT [8/9] Loading widget catalog...
@20_data_catalog.sql

PROMPT [9/9] Creating default desk...
@21_data_default_desk.sql

PROMPT ============================================
PROMPT Installation terminee.
PROMPT ============================================
