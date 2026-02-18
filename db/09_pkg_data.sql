-- ============================================================================
-- COCKPIT_DATA_PKG : dynamic datasource execution with TSV output
-- Oracle 19c SE2 compatible
-- No VPD: contractor filtering done in PL/SQL via WHERE injection
-- ============================================================================

CREATE OR REPLACE PACKAGE cockpit.cockpit_data_pkg
AUTHID CURRENT_USER
AS
    -- Execute a datasource by code, emit TSV
    -- p_desk_id: context desk (for contractor filtering + audit)
    -- p_params_json: optional parameters as JSON
    PROCEDURE execute_datasource (
        p_ds_code       IN VARCHAR2,
        p_desk_id       IN NUMBER DEFAULT NULL,
        p_params_json   IN VARCHAR2 DEFAULT NULL
    );

END cockpit_data_pkg;
/

CREATE OR REPLACE PACKAGE BODY cockpit.cockpit_data_pkg
AS

    -- -----------------------------------------------------------------------
    -- apply_contractor_filter
    -- Builds additional WHERE clause from desk contractor_filter JSON
    -- Returns empty string if no filter or not a contractor desk
    -- -----------------------------------------------------------------------
    FUNCTION apply_contractor_filter (
        p_desk_id   IN NUMBER,
        p_ds_code   IN VARCHAR2
    ) RETURN VARCHAR2
    IS
        l_filter    VARCHAR2(4000);
        l_where     VARCHAR2(4000) := '';
        l_desk_type VARCHAR2(20);
    BEGIN
        IF p_desk_id IS NULL THEN RETURN ''; END IF;

        SELECT desk_type, contractor_filter
        INTO l_desk_type, l_filter
        FROM cockpit.meta_desks
        WHERE desk_id = p_desk_id;

        IF l_desk_type != 'CONTRACTOR' OR l_filter IS NULL THEN
            RETURN '';
        END IF;

        -- Parse filter JSON and build WHERE conditions
        -- Example filter: {"schemas":["HR","SCOTT"], "tablespaces":["TBS_HR"]}
        -- The actual WHERE depends on the datasource columns
        -- This is the central security enforcement point
        DECLARE
            l_schemas VARCHAR2(4000);
        BEGIN
            SELECT LISTAGG('''' || val || '''', ',') WITHIN GROUP (ORDER BY val)
            INTO l_schemas
            FROM JSON_TABLE(l_filter, '$.schemas[*]' COLUMNS (val VARCHAR2(128) PATH '$'));

            IF l_schemas IS NOT NULL THEN
                -- Only apply schema filter to datasources that have schema-related columns
                -- Each datasource knows its filterable columns via naming convention
                l_where := l_where || ' AND (SCHEMA_NAME IN (' || l_schemas || ')'
                        || ' OR USERNAME IN (' || l_schemas || '))';
            END IF;
        EXCEPTION
            WHEN OTHERS THEN NULL; -- No schemas filter in JSON
        END;

        RETURN l_where;
    END apply_contractor_filter;

    -- -----------------------------------------------------------------------
    -- execute_datasource
    -- -----------------------------------------------------------------------
    PROCEDURE execute_datasource (
        p_ds_code       IN VARCHAR2,
        p_desk_id       IN NUMBER DEFAULT NULL,
        p_params_json   IN VARCHAR2 DEFAULT NULL
    )
    IS
        l_ds_type       VARCHAR2(20);
        l_sql_query     CLOB;
        l_plsql_call    VARCHAR2(500);
        l_privilege     VARCHAR2(50);
        l_username      VARCHAR2(128) := cockpit_util_pkg.current_user_name();
        l_cursor        SYS_REFCURSOR;
        l_extra_where   VARCHAR2(4000);
    BEGIN
        -- Fetch datasource definition
        BEGIN
            SELECT ds_type, sql_query, plsql_call, required_privilege
            INTO l_ds_type, l_sql_query, l_plsql_call, l_privilege
            FROM cockpit.meta_data_sources
            WHERE ds_code = p_ds_code
              AND is_active = 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                cockpit_util_pkg.emit_error(404, 'DS_NOT_FOUND',
                    'Datasource ' || p_ds_code || ' non trouvee');
                RETURN;
        END;

        -- Check widget permission in desk context
        IF p_desk_id IS NOT NULL THEN
            DECLARE
                l_cat_code VARCHAR2(50);
            BEGIN
                -- Find catalog_code for this datasource
                SELECT c.catalog_code INTO l_cat_code
                FROM cockpit.meta_widget_catalog c
                WHERE c.datasource_id = (
                    SELECT datasource_id FROM cockpit.meta_data_sources
                    WHERE ds_code = p_ds_code
                );

                IF NOT cockpit_auth_pkg.can_use_widget(l_username, p_desk_id, l_cat_code) THEN
                    cockpit_util_pkg.emit_error(403, 'FORBIDDEN', 'Acces refuse a ce widget');
                    RETURN;
                END IF;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN NULL; -- Datasource not linked to catalog, allow
            END;
        END IF;

        -- Audit
        cockpit_util_pkg.audit_log(
            p_desk_id      => p_desk_id,
            p_action_type  => 'VIEW_DATA',
            p_catalog_code => p_ds_code,
            p_detail       => p_params_json
        );

        -- Execute based on type
        CASE l_ds_type
            WHEN 'PLSQL_FUNCTION' THEN
                -- Dynamic PL/SQL call returning SYS_REFCURSOR
                EXECUTE IMMEDIATE
                    'BEGIN :1 := ' || DBMS_ASSERT.SQL_OBJECT_NAME(l_plsql_call) || '; END;'
                    USING OUT l_cursor;
                cockpit_util_pkg.emit_tsv(l_cursor);

            WHEN 'SQL_QUERY' THEN
                -- Apply contractor filter (no VPD in SE2)
                l_extra_where := apply_contractor_filter(p_desk_id, p_ds_code);

                IF l_extra_where IS NOT NULL AND LENGTH(l_extra_where) > 0 THEN
                    -- Wrap original query with filter
                    l_sql_query := 'SELECT * FROM (' || l_sql_query || ') q WHERE 1=1 ' || l_extra_where;
                END IF;

                OPEN l_cursor FOR l_sql_query;
                cockpit_util_pkg.emit_tsv(l_cursor);

            ELSE
                cockpit_util_pkg.emit_error(400, 'INVALID_DS_TYPE',
                    'Type de datasource non supporte: ' || l_ds_type);
        END CASE;

    EXCEPTION
        WHEN OTHERS THEN
            cockpit_util_pkg.emit_error(500, 'EXEC_ERROR',
                'Erreur execution datasource');
    END execute_datasource;

END cockpit_data_pkg;
/
