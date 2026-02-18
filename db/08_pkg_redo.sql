-- ============================================================================
-- COCKPIT_REDO_PKG : Oracle Redo Log monitoring functions
-- Oracle 19c SE2 compatible
-- All functions return SYS_REFCURSOR for TSV emission
-- ============================================================================

CREATE OR REPLACE PACKAGE cockpit.cockpit_redo_pkg
AS
    -- Redo log groups (v$log)
    FUNCTION get_log_groups RETURN SYS_REFCURSOR;

    -- Redo log files (v$logfile)
    FUNCTION get_log_files RETURN SYS_REFCURSOR;

    -- Joined view: groups with their files
    FUNCTION get_log_groups_with_files RETURN SYS_REFCURSOR;

    -- Log switch statistics
    FUNCTION get_log_statistics RETURN SYS_REFCURSOR;

    -- Log switch history
    FUNCTION get_log_switch_history (
        p_hours_back IN NUMBER DEFAULT 24
    ) RETURN SYS_REFCURSOR;

END cockpit_redo_pkg;
/

CREATE OR REPLACE PACKAGE BODY cockpit.cockpit_redo_pkg
AS

    FUNCTION get_log_groups RETURN SYS_REFCURSOR
    IS
        l_cur SYS_REFCURSOR;
    BEGIN
        OPEN l_cur FOR
            SELECT l.GROUP#                                     AS GROUP_NUM,
                   l.THREAD#                                    AS THREAD_NUM,
                   l.SEQUENCE#                                  AS SEQUENCE_NUM,
                   ROUND(l.BYTES / 1048576, 2)                  AS SIZE_MB,
                   l.BLOCKSIZE                                  AS BLOCK_SIZE,
                   l.MEMBERS                                    AS MEMBERS,
                   l.ARCHIVED                                   AS ARCHIVED,
                   l.STATUS                                     AS STATUS,
                   l.FIRST_CHANGE#                              AS FIRST_CHANGE,
                   TO_CHAR(l.FIRST_TIME, 'YYYY-MM-DD HH24:MI:SS') AS FIRST_TIME
            FROM v$log l
            ORDER BY l.GROUP#;
        RETURN l_cur;
    END get_log_groups;

    FUNCTION get_log_files RETURN SYS_REFCURSOR
    IS
        l_cur SYS_REFCURSOR;
    BEGIN
        OPEN l_cur FOR
            SELECT lf.GROUP#                                    AS GROUP_NUM,
                   lf.STATUS                                    AS STATUS,
                   lf.TYPE                                      AS FILE_TYPE,
                   lf.MEMBER                                    AS FILE_PATH,
                   lf.IS_RECOVERY_DEST_FILE                     AS IS_FRA
            FROM v$logfile lf
            ORDER BY lf.GROUP#, lf.MEMBER;
        RETURN l_cur;
    END get_log_files;

    FUNCTION get_log_groups_with_files RETURN SYS_REFCURSOR
    IS
        l_cur SYS_REFCURSOR;
    BEGIN
        OPEN l_cur FOR
            SELECT l.GROUP#                                     AS GROUP_NUM,
                   l.THREAD#                                    AS THREAD_NUM,
                   l.SEQUENCE#                                  AS SEQUENCE_NUM,
                   ROUND(l.BYTES / 1048576, 2)                  AS SIZE_MB,
                   l.STATUS                                     AS GROUP_STATUS,
                   l.ARCHIVED                                   AS ARCHIVED,
                   lf.MEMBER                                    AS FILE_PATH,
                   lf.STATUS                                    AS FILE_STATUS,
                   lf.TYPE                                      AS FILE_TYPE
            FROM v$log l
            JOIN v$logfile lf ON l.GROUP# = lf.GROUP#
            ORDER BY l.GROUP#, lf.MEMBER;
        RETURN l_cur;
    END get_log_groups_with_files;

    FUNCTION get_log_statistics RETURN SYS_REFCURSOR
    IS
        l_cur SYS_REFCURSOR;
    BEGIN
        OPEN l_cur FOR
            SELECT 'TOTAL_GROUPS'           AS METRIC,
                   TO_CHAR(COUNT(*))        AS VALUE
            FROM v$log
            UNION ALL
            SELECT 'TOTAL_FILES',
                   TO_CHAR(COUNT(*))
            FROM v$logfile
            UNION ALL
            SELECT 'TOTAL_SIZE_MB',
                   TO_CHAR(ROUND(SUM(BYTES) / 1048576, 2))
            FROM v$log
            UNION ALL
            SELECT 'CURRENT_GROUP',
                   TO_CHAR(GROUP#)
            FROM v$log
            WHERE STATUS = 'CURRENT'
            UNION ALL
            SELECT 'SWITCHES_24H',
                   TO_CHAR(COUNT(*))
            FROM v$log_history
            WHERE FIRST_TIME > SYSDATE - 1
            UNION ALL
            SELECT 'SWITCHES_1H',
                   TO_CHAR(COUNT(*))
            FROM v$log_history
            WHERE FIRST_TIME > SYSDATE - 1/24;
        RETURN l_cur;
    END get_log_statistics;

    FUNCTION get_log_switch_history (
        p_hours_back IN NUMBER DEFAULT 24
    ) RETURN SYS_REFCURSOR
    IS
        l_cur SYS_REFCURSOR;
    BEGIN
        OPEN l_cur FOR
            SELECT THREAD#                                      AS THREAD_NUM,
                   SEQUENCE#                                    AS SEQUENCE_NUM,
                   FIRST_CHANGE#                                AS FIRST_CHANGE,
                   TO_CHAR(FIRST_TIME, 'YYYY-MM-DD HH24:MI:SS') AS SWITCH_TIME,
                   ROUND((NEXT_CHANGE# - FIRST_CHANGE#))       AS CHANGES
            FROM v$log_history
            WHERE FIRST_TIME > SYSDATE - p_hours_back / 24
            ORDER BY FIRST_TIME DESC;
        RETURN l_cur;
    END get_log_switch_history;

END cockpit_redo_pkg;
/
