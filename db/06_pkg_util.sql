-- ============================================================================
-- COCKPIT_UTIL_PKG : cross-cutting utilities
-- Oracle 19c SE2 compatible
-- ============================================================================

CREATE OR REPLACE PACKAGE cockpit.cockpit_util_pkg
AS
    -- Emit TSV response via HTP (for ORDS handlers)
    PROCEDURE emit_tsv (
        p_cursor    IN SYS_REFCURSOR
    );

    -- Emit JSON response via HTP
    PROCEDURE emit_json (
        p_json      IN CLOB,
        p_status    IN NUMBER DEFAULT 200
    );

    -- Emit error response
    PROCEDURE emit_error (
        p_status    IN NUMBER,
        p_code      IN VARCHAR2,
        p_message   IN VARCHAR2
    );

    -- Validate identifier (column name) against SQL injection
    FUNCTION is_valid_identifier (
        p_name      IN VARCHAR2
    ) RETURN BOOLEAN;

    -- Get current username from ORDS session or SYS_CONTEXT
    FUNCTION current_user_name RETURN VARCHAR2;

    -- Get client IP from ORDS
    FUNCTION client_ip RETURN VARCHAR2;

    -- Log an audit action
    PROCEDURE audit_log (
        p_desk_id       IN NUMBER DEFAULT NULL,
        p_action_type   IN VARCHAR2,
        p_catalog_code  IN VARCHAR2 DEFAULT NULL,
        p_detail        IN VARCHAR2 DEFAULT NULL
    );

END cockpit_util_pkg;
/

CREATE OR REPLACE PACKAGE BODY cockpit.cockpit_util_pkg
AS

    -- -----------------------------------------------------------------------
    -- emit_tsv : converts a SYS_REFCURSOR to TSV and writes via HTP
    -- Header line = column names, then one line per row, tab-separated
    -- NULL rendered as \N
    -- -----------------------------------------------------------------------
    PROCEDURE emit_tsv (
        p_cursor    IN SYS_REFCURSOR
    )
    IS
        l_cursor_id     INTEGER;
        l_col_cnt       INTEGER;
        l_desc_tab      DBMS_SQL.DESC_TAB;
        l_varchar_val   VARCHAR2(4000);
        l_number_val    NUMBER;
        l_date_val      DATE;
        l_ts_val        TIMESTAMP;
        l_header        VARCHAR2(32767);
        l_line          VARCHAR2(32767);
        l_status        INTEGER;
        l_col_type      INTEGER;
    BEGIN
        OWA_UTIL.MIME_HEADER('text/tab-separated-values; charset=utf-8', TRUE);

        l_cursor_id := DBMS_SQL.TO_CURSOR_NUMBER(p_cursor);
        DBMS_SQL.DESCRIBE_COLUMNS(l_cursor_id, l_col_cnt, l_desc_tab);

        -- Define columns for fetch
        FOR i IN 1..l_col_cnt LOOP
            DBMS_SQL.DEFINE_COLUMN(l_cursor_id, i, l_varchar_val, 4000);
        END LOOP;

        -- Header line
        l_header := '';
        FOR i IN 1..l_col_cnt LOOP
            IF i > 1 THEN l_header := l_header || CHR(9); END IF;
            l_header := l_header || l_desc_tab(i).col_name;
        END LOOP;
        HTP.P(l_header);

        -- Data lines
        LOOP
            l_status := DBMS_SQL.FETCH_ROWS(l_cursor_id);
            EXIT WHEN l_status = 0;

            l_line := '';
            FOR i IN 1..l_col_cnt LOOP
                IF i > 1 THEN l_line := l_line || CHR(9); END IF;
                DBMS_SQL.COLUMN_VALUE(l_cursor_id, i, l_varchar_val);
                IF l_varchar_val IS NULL THEN
                    l_line := l_line || '\N';
                ELSE
                    -- Escape tabs and newlines in values to preserve TSV integrity
                    l_line := l_line || REPLACE(REPLACE(REPLACE(
                        l_varchar_val, '\', '\\'), CHR(9), '\t'), CHR(10), '\n');
                END IF;
            END LOOP;
            HTP.P(l_line);
        END LOOP;

        DBMS_SQL.CLOSE_CURSOR(l_cursor_id);
    EXCEPTION
        WHEN OTHERS THEN
            IF DBMS_SQL.IS_OPEN(l_cursor_id) THEN
                DBMS_SQL.CLOSE_CURSOR(l_cursor_id);
            END IF;
            RAISE;
    END emit_tsv;

    -- -----------------------------------------------------------------------
    -- emit_json
    -- -----------------------------------------------------------------------
    PROCEDURE emit_json (
        p_json      IN CLOB,
        p_status    IN NUMBER DEFAULT 200
    )
    IS
    BEGIN
        OWA_UTIL.MIME_HEADER('application/json; charset=utf-8', FALSE);
        OWA_UTIL.STATUS_LINE(p_status);
        OWA_UTIL.HTTP_HEADER_CLOSE;
        HTP.P(p_json);
    END emit_json;

    -- -----------------------------------------------------------------------
    -- emit_error
    -- -----------------------------------------------------------------------
    PROCEDURE emit_error (
        p_status    IN NUMBER,
        p_code      IN VARCHAR2,
        p_message   IN VARCHAR2
    )
    IS
    BEGIN
        emit_json(
            '{"error":' || JSON_OBJECT('code' VALUE p_code, 'message' VALUE p_message) || '}',
            p_status
        );
    END emit_error;

    -- -----------------------------------------------------------------------
    -- is_valid_identifier
    -- -----------------------------------------------------------------------
    FUNCTION is_valid_identifier (
        p_name      IN VARCHAR2
    ) RETURN BOOLEAN
    IS
        l_result VARCHAR2(128);
    BEGIN
        IF p_name IS NULL THEN RETURN FALSE; END IF;
        l_result := DBMS_ASSERT.SIMPLE_SQL_NAME(p_name);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END is_valid_identifier;

    -- -----------------------------------------------------------------------
    -- current_user_name
    -- -----------------------------------------------------------------------
    FUNCTION current_user_name RETURN VARCHAR2
    IS
    BEGIN
        -- ORDS sets this when OAuth2 is configured
        RETURN NVL(
            SYS_CONTEXT('USERENV', 'CLIENT_IDENTIFIER'),
            SYS_CONTEXT('USERENV', 'SESSION_USER')
        );
    END current_user_name;

    -- -----------------------------------------------------------------------
    -- client_ip
    -- -----------------------------------------------------------------------
    FUNCTION client_ip RETURN VARCHAR2
    IS
    BEGIN
        RETURN NVL(
            OWA_UTIL.GET_CGI_ENV('REMOTE_ADDR'),
            SYS_CONTEXT('USERENV', 'IP_ADDRESS')
        );
    END client_ip;

    -- -----------------------------------------------------------------------
    -- audit_log
    -- -----------------------------------------------------------------------
    PROCEDURE audit_log (
        p_desk_id       IN NUMBER DEFAULT NULL,
        p_action_type   IN VARCHAR2,
        p_catalog_code  IN VARCHAR2 DEFAULT NULL,
        p_detail        IN VARCHAR2 DEFAULT NULL
    )
    IS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        INSERT INTO cockpit.meta_audit_actions (
            desk_id, username, action_type,
            catalog_code, action_detail,
            client_ip, user_agent
        ) VALUES (
            p_desk_id, current_user_name(), p_action_type,
            p_catalog_code, p_detail,
            client_ip(), OWA_UTIL.GET_CGI_ENV('HTTP_USER_AGENT')
        );
        COMMIT;
    END audit_log;

END cockpit_util_pkg;
/
