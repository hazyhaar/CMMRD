-- ============================================================================
-- COCKPIT_DESK_PKG : desk/tab/widget CRUD operations
-- Oracle 19c SE2 compatible
-- All output as JSON (structural data, not tabular)
-- ============================================================================

CREATE OR REPLACE PACKAGE cockpit.cockpit_desk_pkg
AUTHID CURRENT_USER
AS
    -- List desks accessible by current user
    PROCEDURE get_my_desks;

    -- Get full desk definition (tabs + widgets + catalog info)
    PROCEDURE get_desk_full (
        p_desk_id   IN NUMBER
    );

    -- Create a new desk
    PROCEDURE create_desk (
        p_body_json IN CLOB
    );

    -- Delete a desk (owner only)
    PROCEDURE delete_desk (
        p_desk_id   IN NUMBER
    );

    -- Create a tab in a desk
    PROCEDURE create_tab (
        p_desk_id   IN NUMBER,
        p_body_json IN CLOB
    );

    -- Delete a tab
    PROCEDURE delete_tab (
        p_tab_id    IN NUMBER
    );

    -- Add a widget to a tab
    PROCEDURE add_widget (
        p_tab_id    IN NUMBER,
        p_body_json IN CLOB
    );

    -- Update widget position/size (drag & drop)
    PROCEDURE update_widget_position (
        p_widget_id IN NUMBER,
        p_body_json IN CLOB
    );

    -- Remove a widget
    PROCEDURE remove_widget (
        p_widget_id IN NUMBER
    );

    -- Set desk permissions for a user
    PROCEDURE set_permissions (
        p_desk_id   IN NUMBER,
        p_body_json IN CLOB
    );

    -- Get widget catalog (available widgets)
    PROCEDURE get_catalog;

    -- Get audit trail for a desk
    PROCEDURE get_desk_audit (
        p_desk_id   IN NUMBER,
        p_max_rows  IN NUMBER DEFAULT 100
    );

END cockpit_desk_pkg;
/

CREATE OR REPLACE PACKAGE BODY cockpit.cockpit_desk_pkg
AS

    -- -----------------------------------------------------------------------
    PROCEDURE get_my_desks
    IS
        l_user VARCHAR2(128) := cockpit_util_pkg.current_user_name();
        l_json CLOB;
    BEGIN
        SELECT JSON_ARRAYAGG(
            JSON_OBJECT(
                'deskId'          VALUE d.desk_id,
                'deskCode'        VALUE d.desk_code,
                'deskName'        VALUE d.desk_name,
                'deskType'        VALUE d.desk_type,
                'ownerUser'       VALUE d.owner_user,
                'contractorUser'  VALUE d.contractor_user,
                'validFrom'       VALUE TO_CHAR(d.valid_from, 'YYYY-MM-DD'),
                'validTo'         VALUE TO_CHAR(d.valid_to, 'YYYY-MM-DD'),
                'tabCount'        VALUE (
                    SELECT COUNT(*) FROM cockpit.meta_tabs t WHERE t.desk_id = d.desk_id
                )
            )
            ORDER BY d.desk_type, d.desk_name
            RETURNING CLOB
        ) INTO l_json
        FROM cockpit.meta_desks d
        WHERE d.is_active = 1
          AND (d.valid_to IS NULL OR d.valid_to >= SYSDATE)
          AND (
              d.owner_user = l_user
              OR d.contractor_user = l_user
              OR EXISTS (
                  SELECT 1 FROM cockpit.meta_desk_permissions dp
                  WHERE dp.desk_id = d.desk_id
                    AND dp.granted_user = l_user
                    AND dp.can_read = 1
              )
          );

        cockpit_util_pkg.emit_json(NVL(l_json, '[]'));
    END get_my_desks;

    -- -----------------------------------------------------------------------
    PROCEDURE get_desk_full (
        p_desk_id   IN NUMBER
    )
    IS
        l_user VARCHAR2(128) := cockpit_util_pkg.current_user_name();
        l_json CLOB;
    BEGIN
        IF NOT cockpit_auth_pkg.can_access_desk(l_user, p_desk_id) THEN
            cockpit_util_pkg.emit_error(403, 'FORBIDDEN', 'Acces refuse a ce desk');
            RETURN;
        END IF;

        cockpit_util_pkg.audit_log(p_desk_id, 'VIEW_DESK');

        SELECT JSON_OBJECT(
            'deskId'          VALUE d.desk_id,
            'deskCode'        VALUE d.desk_code,
            'deskName'        VALUE d.desk_name,
            'deskType'        VALUE d.desk_type,
            'ownerUser'       VALUE d.owner_user,
            'contractorUser'  VALUE d.contractor_user,
            'validTo'         VALUE TO_CHAR(d.valid_to, 'YYYY-MM-DD'),
            'tabs'            VALUE (
                SELECT JSON_ARRAYAGG(
                    JSON_OBJECT(
                        'tabId'       VALUE t.tab_id,
                        'tabCode'     VALUE t.tab_code,
                        'tabName'     VALUE t.tab_name,
                        'tabOrder'    VALUE t.tab_order,
                        'tabIcon'     VALUE t.tab_icon,
                        'widgets'     VALUE (
                            SELECT JSON_ARRAYAGG(
                                JSON_OBJECT(
                                    'widgetId'      VALUE w.widget_id,
                                    'widgetTitle'   VALUE NVL(w.widget_title, c.catalog_name),
                                    'catalogCode'   VALUE c.catalog_code,
                                    'catalogName'   VALUE c.catalog_name,
                                    'widgetType'    VALUE c.widget_type,
                                    'category'      VALUE c.category,
                                    'iconName'      VALUE c.icon_name,
                                    'dsCode'        VALUE ds.ds_code,
                                    'columnsDef'    VALUE c.columns_def FORMAT JSON,
                                    'positionX'     VALUE w.position_x,
                                    'positionY'     VALUE w.position_y,
                                    'sizeW'         VALUE w.size_w,
                                    'sizeH'         VALUE w.size_h,
                                    'refreshSec'    VALUE w.refresh_sec,
                                    'customParams'  VALUE w.custom_params FORMAT JSON,
                                    'jsRender'      VALUE c.js_render,
                                    'jsInit'        VALUE c.js_init
                                )
                                ORDER BY w.position_y, w.position_x
                                RETURNING CLOB
                            )
                            FROM cockpit.meta_widgets w
                            JOIN cockpit.meta_widget_catalog c ON c.catalog_id = w.catalog_id
                            LEFT JOIN cockpit.meta_data_sources ds ON ds.datasource_id = c.datasource_id
                            WHERE w.tab_id = t.tab_id
                              AND w.is_visible = 1
                        )
                    )
                    ORDER BY t.tab_order
                    RETURNING CLOB
                )
                FROM cockpit.meta_tabs t
                WHERE t.desk_id = d.desk_id
                  AND t.is_visible = 1
            ),
            'permissions'     VALUE (
                SELECT JSON_OBJECT(
                    'canRead'         VALUE dp.can_read,
                    'canModifyLayout' VALUE dp.can_modify_layout,
                    'canAddWidgets'   VALUE dp.can_add_widgets,
                    'canExecute'      VALUE dp.can_execute
                )
                FROM cockpit.meta_desk_permissions dp
                WHERE dp.desk_id = d.desk_id
                  AND dp.granted_user = l_user
            )
            RETURNING CLOB
        ) INTO l_json
        FROM cockpit.meta_desks d
        WHERE d.desk_id = p_desk_id;

        cockpit_util_pkg.emit_json(l_json);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            cockpit_util_pkg.emit_error(404, 'DESK_NOT_FOUND', 'Desk non trouve');
    END get_desk_full;

    -- -----------------------------------------------------------------------
    PROCEDURE create_desk (
        p_body_json IN CLOB
    )
    IS
        l_user      VARCHAR2(128) := cockpit_util_pkg.current_user_name();
        l_desk_id   NUMBER;
        l_code      VARCHAR2(50);
        l_name      VARCHAR2(200);
        l_type      VARCHAR2(20);
        l_contractor VARCHAR2(128);
        l_filter    VARCHAR2(4000);
        l_valid_to  DATE;
    BEGIN
        -- Parse input
        SELECT jt.desk_code, jt.desk_name, jt.desk_type,
               jt.contractor_user, jt.contractor_filter,
               TO_DATE(jt.valid_to, 'YYYY-MM-DD')
        INTO l_code, l_name, l_type, l_contractor, l_filter, l_valid_to
        FROM JSON_TABLE(p_body_json, '$' COLUMNS (
            desk_code         VARCHAR2(50)   PATH '$.deskCode',
            desk_name         VARCHAR2(200)  PATH '$.deskName',
            desk_type         VARCHAR2(20)   PATH '$.deskType',
            contractor_user   VARCHAR2(128)  PATH '$.contractorUser',
            contractor_filter VARCHAR2(4000) PATH '$.contractorFilter',
            valid_to          VARCHAR2(10)   PATH '$.validTo'
        )) jt;

        INSERT INTO cockpit.meta_desks (
            desk_code, desk_name, owner_user, desk_type,
            contractor_user, contractor_filter, valid_to
        ) VALUES (
            l_code, l_name, l_user, l_type,
            l_contractor, l_filter, l_valid_to
        ) RETURNING desk_id INTO l_desk_id;

        -- Auto-grant permissions to contractor
        IF l_type = 'CONTRACTOR' AND l_contractor IS NOT NULL THEN
            INSERT INTO cockpit.meta_desk_permissions (
                desk_id, granted_user,
                can_read, can_modify_layout, can_add_widgets, can_execute
            ) VALUES (
                l_desk_id, l_contractor,
                1, 0, 0, 1
            );
        END IF;

        COMMIT;

        cockpit_util_pkg.audit_log(l_desk_id, 'CREATE_DESK', p_detail => l_name);
        cockpit_util_pkg.emit_json(
            JSON_OBJECT('deskId' VALUE l_desk_id, 'status' VALUE 'OK')
        );
    END create_desk;

    -- -----------------------------------------------------------------------
    PROCEDURE delete_desk (
        p_desk_id   IN NUMBER
    )
    IS
        l_user VARCHAR2(128) := cockpit_util_pkg.current_user_name();
        l_cnt  NUMBER;
    BEGIN
        SELECT COUNT(*) INTO l_cnt
        FROM cockpit.meta_desks
        WHERE desk_id = p_desk_id AND owner_user = l_user;

        IF l_cnt = 0 THEN
            cockpit_util_pkg.emit_error(403, 'FORBIDDEN', 'Seul le proprietaire peut supprimer');
            RETURN;
        END IF;

        cockpit_util_pkg.audit_log(p_desk_id, 'DELETE_DESK');

        DELETE FROM cockpit.meta_desks WHERE desk_id = p_desk_id;
        COMMIT;

        cockpit_util_pkg.emit_json(JSON_OBJECT('status' VALUE 'OK'));
    END delete_desk;

    -- -----------------------------------------------------------------------
    PROCEDURE create_tab (
        p_desk_id   IN NUMBER,
        p_body_json IN CLOB
    )
    IS
        l_user   VARCHAR2(128) := cockpit_util_pkg.current_user_name();
        l_tab_id NUMBER;
        l_code   VARCHAR2(50);
        l_name   VARCHAR2(200);
        l_order  NUMBER;
        l_icon   VARCHAR2(50);
    BEGIN
        IF NOT cockpit_auth_pkg.can_access_desk(l_user, p_desk_id) THEN
            cockpit_util_pkg.emit_error(403, 'FORBIDDEN', 'Acces refuse');
            RETURN;
        END IF;

        SELECT jt.tab_code, jt.tab_name, jt.tab_order, jt.tab_icon
        INTO l_code, l_name, l_order, l_icon
        FROM JSON_TABLE(p_body_json, '$' COLUMNS (
            tab_code  VARCHAR2(50)  PATH '$.tabCode',
            tab_name  VARCHAR2(200) PATH '$.tabName',
            tab_order NUMBER        PATH '$.tabOrder',
            tab_icon  VARCHAR2(50)  PATH '$.tabIcon'
        )) jt;

        INSERT INTO cockpit.meta_tabs (desk_id, tab_code, tab_name, tab_order, tab_icon)
        VALUES (p_desk_id, l_code, l_name, NVL(l_order, 10), l_icon)
        RETURNING tab_id INTO l_tab_id;

        COMMIT;

        cockpit_util_pkg.audit_log(p_desk_id, 'CREATE_TAB', p_detail => l_name);
        cockpit_util_pkg.emit_json(JSON_OBJECT('tabId' VALUE l_tab_id, 'status' VALUE 'OK'));
    END create_tab;

    -- -----------------------------------------------------------------------
    PROCEDURE delete_tab (
        p_tab_id    IN NUMBER
    )
    IS
        l_desk_id NUMBER;
    BEGIN
        SELECT desk_id INTO l_desk_id
        FROM cockpit.meta_tabs WHERE tab_id = p_tab_id;

        cockpit_util_pkg.audit_log(l_desk_id, 'DELETE_TAB');

        DELETE FROM cockpit.meta_tabs WHERE tab_id = p_tab_id;
        COMMIT;

        cockpit_util_pkg.emit_json(JSON_OBJECT('status' VALUE 'OK'));
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            cockpit_util_pkg.emit_error(404, 'TAB_NOT_FOUND', 'Onglet non trouve');
    END delete_tab;

    -- -----------------------------------------------------------------------
    PROCEDURE add_widget (
        p_tab_id    IN NUMBER,
        p_body_json IN CLOB
    )
    IS
        l_widget_id NUMBER;
        l_desk_id   NUMBER;
    BEGIN
        SELECT t.desk_id INTO l_desk_id
        FROM cockpit.meta_tabs t WHERE t.tab_id = p_tab_id;

        INSERT INTO cockpit.meta_widgets (
            tab_id, catalog_id, widget_title,
            position_x, position_y, size_w, size_h, refresh_sec, custom_params
        )
        SELECT p_tab_id,
               jt.catalog_id, jt.widget_title,
               NVL(jt.pos_x, 0), NVL(jt.pos_y, 0),
               NVL(jt.size_w, 6), NVL(jt.size_h, 4),
               NVL(jt.refresh_sec, c.default_refresh_sec),
               jt.custom_params
        FROM JSON_TABLE(p_body_json, '$' COLUMNS (
            catalog_id    NUMBER         PATH '$.catalogId',
            widget_title  VARCHAR2(200)  PATH '$.widgetTitle',
            pos_x         NUMBER         PATH '$.positionX',
            pos_y         NUMBER         PATH '$.positionY',
            size_w        NUMBER         PATH '$.sizeW',
            size_h        NUMBER         PATH '$.sizeH',
            refresh_sec   NUMBER         PATH '$.refreshSec',
            custom_params VARCHAR2(4000) PATH '$.customParams'
        )) jt
        JOIN cockpit.meta_widget_catalog c ON c.catalog_id = jt.catalog_id
        RETURNING widget_id INTO l_widget_id;

        COMMIT;

        cockpit_util_pkg.audit_log(l_desk_id, 'ADD_WIDGET');
        cockpit_util_pkg.emit_json(JSON_OBJECT('widgetId' VALUE l_widget_id, 'status' VALUE 'OK'));
    END add_widget;

    -- -----------------------------------------------------------------------
    PROCEDURE update_widget_position (
        p_widget_id IN NUMBER,
        p_body_json IN CLOB
    )
    IS
    BEGIN
        UPDATE cockpit.meta_widgets
        SET position_x = NVL(JSON_VALUE(p_body_json, '$.positionX' RETURNING NUMBER), position_x),
            position_y = NVL(JSON_VALUE(p_body_json, '$.positionY' RETURNING NUMBER), position_y),
            size_w     = NVL(JSON_VALUE(p_body_json, '$.sizeW'     RETURNING NUMBER), size_w),
            size_h     = NVL(JSON_VALUE(p_body_json, '$.sizeH'     RETURNING NUMBER), size_h)
        WHERE widget_id = p_widget_id;

        COMMIT;
        cockpit_util_pkg.emit_json(JSON_OBJECT('status' VALUE 'OK'));
    END update_widget_position;

    -- -----------------------------------------------------------------------
    PROCEDURE remove_widget (
        p_widget_id IN NUMBER
    )
    IS
        l_desk_id NUMBER;
    BEGIN
        SELECT t.desk_id INTO l_desk_id
        FROM cockpit.meta_widgets w
        JOIN cockpit.meta_tabs t ON t.tab_id = w.tab_id
        WHERE w.widget_id = p_widget_id;

        cockpit_util_pkg.audit_log(l_desk_id, 'REMOVE_WIDGET');

        DELETE FROM cockpit.meta_widgets WHERE widget_id = p_widget_id;
        COMMIT;

        cockpit_util_pkg.emit_json(JSON_OBJECT('status' VALUE 'OK'));
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            cockpit_util_pkg.emit_error(404, 'WIDGET_NOT_FOUND', 'Widget non trouve');
    END remove_widget;

    -- -----------------------------------------------------------------------
    PROCEDURE set_permissions (
        p_desk_id   IN NUMBER,
        p_body_json IN CLOB
    )
    IS
    BEGIN
        MERGE INTO cockpit.meta_desk_permissions dp
        USING (
            SELECT p_desk_id AS desk_id,
                   jt.granted_user,
                   jt.can_read, jt.can_modify_layout,
                   jt.can_add_widgets, jt.can_execute,
                   jt.catalog_whitelist
            FROM JSON_TABLE(p_body_json, '$' COLUMNS (
                granted_user      VARCHAR2(128)  PATH '$.grantedUser',
                can_read          NUMBER         PATH '$.canRead',
                can_modify_layout NUMBER         PATH '$.canModifyLayout',
                can_add_widgets   NUMBER         PATH '$.canAddWidgets',
                can_execute       NUMBER         PATH '$.canExecute',
                catalog_whitelist VARCHAR2(4000) PATH '$.catalogWhitelist'
            )) jt
        ) src ON (dp.desk_id = src.desk_id AND dp.granted_user = src.granted_user)
        WHEN MATCHED THEN UPDATE SET
            dp.can_read = NVL(src.can_read, dp.can_read),
            dp.can_modify_layout = NVL(src.can_modify_layout, dp.can_modify_layout),
            dp.can_add_widgets = NVL(src.can_add_widgets, dp.can_add_widgets),
            dp.can_execute = NVL(src.can_execute, dp.can_execute),
            dp.catalog_whitelist = src.catalog_whitelist
        WHEN NOT MATCHED THEN INSERT (
            desk_id, granted_user, can_read, can_modify_layout,
            can_add_widgets, can_execute, catalog_whitelist
        ) VALUES (
            src.desk_id, src.granted_user,
            NVL(src.can_read, 1), NVL(src.can_modify_layout, 0),
            NVL(src.can_add_widgets, 0), NVL(src.can_execute, 1),
            src.catalog_whitelist
        );

        COMMIT;

        cockpit_util_pkg.audit_log(p_desk_id, 'CHANGE_PERMISSION');
        cockpit_util_pkg.emit_json(JSON_OBJECT('status' VALUE 'OK'));
    END set_permissions;

    -- -----------------------------------------------------------------------
    PROCEDURE get_catalog
    IS
        l_json CLOB;
    BEGIN
        SELECT JSON_ARRAYAGG(
            JSON_OBJECT(
                'catalogId'     VALUE c.catalog_id,
                'catalogCode'   VALUE c.catalog_code,
                'catalogName'   VALUE c.catalog_name,
                'category'      VALUE c.category,
                'widgetType'    VALUE c.widget_type,
                'iconName'      VALUE c.icon_name,
                'description'   VALUE c.description,
                'defaultRefresh' VALUE c.default_refresh_sec
            )
            ORDER BY c.category, c.catalog_name
            RETURNING CLOB
        ) INTO l_json
        FROM cockpit.meta_widget_catalog c
        WHERE c.is_active = 1;

        cockpit_util_pkg.emit_json(NVL(l_json, '[]'));
    END get_catalog;

    -- -----------------------------------------------------------------------
    PROCEDURE get_desk_audit (
        p_desk_id   IN NUMBER,
        p_max_rows  IN NUMBER DEFAULT 100
    )
    IS
        l_json CLOB;
    BEGIN
        SELECT JSON_ARRAYAGG(
            JSON_OBJECT(
                'username'    VALUE a.username,
                'actionType'  VALUE a.action_type,
                'catalogCode' VALUE a.catalog_code,
                'detail'      VALUE a.action_detail,
                'clientIp'    VALUE a.client_ip,
                'actionDate'  VALUE TO_CHAR(a.action_date, 'YYYY-MM-DD"T"HH24:MI:SS')
            )
            ORDER BY a.action_date DESC
            RETURNING CLOB
        ) INTO l_json
        FROM (
            SELECT * FROM cockpit.meta_audit_actions
            WHERE desk_id = p_desk_id
            ORDER BY action_date DESC
            FETCH FIRST p_max_rows ROWS ONLY
        ) a;

        cockpit_util_pkg.emit_json(NVL(l_json, '[]'));
    END get_desk_audit;

END cockpit_desk_pkg;
/
