-- ============================================================================
-- DBA Cockpit - Seed Data: Default DBA desk with Redo Logs tab
-- Oracle 19c SE2 compatible
-- ============================================================================

-- Default DBA user
INSERT INTO cockpit.meta_users (username, display_name)
VALUES ('DBA_ADMIN', 'Administrateur DBA');

-- Assign DBA_ADMIN role
INSERT INTO cockpit.meta_user_roles (user_id, role_id)
VALUES (
    (SELECT user_id FROM cockpit.meta_users WHERE username = 'DBA_ADMIN'),
    (SELECT role_id FROM cockpit.meta_roles WHERE role_code = 'DBA_ADMIN')
);

-- Default personal desk
INSERT INTO cockpit.meta_desks (desk_code, desk_name, owner_user, desk_type)
VALUES ('DESK_DBA_MAIN', 'DBA Cockpit Principal', 'DBA_ADMIN', 'PERSONAL');

-- Tab: Redo Logs
INSERT INTO cockpit.meta_tabs (
    desk_id, tab_code, tab_name, tab_order, tab_icon
) VALUES (
    (SELECT desk_id FROM cockpit.meta_desks WHERE desk_code = 'DESK_DBA_MAIN'),
    'TAB_REDO', 'Redo Logs', 10, 'database'
);

-- Widgets in the Redo Logs tab
DECLARE
    v_tab_id NUMBER;
BEGIN
    SELECT tab_id INTO v_tab_id
    FROM cockpit.meta_tabs WHERE tab_code = 'TAB_REDO';

    -- KPI stats bar at top (full width)
    INSERT INTO cockpit.meta_widgets (
        tab_id, catalog_id, widget_title,
        position_x, position_y, size_w, size_h, refresh_sec
    ) VALUES (
        v_tab_id,
        (SELECT catalog_id FROM cockpit.meta_widget_catalog WHERE catalog_code = 'REDO_STATS'),
        'Indicateurs Redo',
        0, 0, 12, 2, 15
    );

    -- Redo groups (left half)
    INSERT INTO cockpit.meta_widgets (
        tab_id, catalog_id, widget_title,
        position_x, position_y, size_w, size_h, refresh_sec
    ) VALUES (
        v_tab_id,
        (SELECT catalog_id FROM cockpit.meta_widget_catalog WHERE catalog_code = 'REDO_GROUPS'),
        'Groupes de Redo Log',
        0, 2, 6, 5, 30
    );

    -- Redo files (right half)
    INSERT INTO cockpit.meta_widgets (
        tab_id, catalog_id, widget_title,
        position_x, position_y, size_w, size_h, refresh_sec
    ) VALUES (
        v_tab_id,
        (SELECT catalog_id FROM cockpit.meta_widget_catalog WHERE catalog_code = 'REDO_FILES'),
        'Fichiers de Redo Log',
        6, 2, 6, 5, 60
    );

    -- Log switch history (full width, bottom)
    INSERT INTO cockpit.meta_widgets (
        tab_id, catalog_id, widget_title,
        position_x, position_y, size_w, size_h, refresh_sec
    ) VALUES (
        v_tab_id,
        (SELECT catalog_id FROM cockpit.meta_widget_catalog WHERE catalog_code = 'REDO_HISTORY'),
        'Historique Log Switches (24h)',
        0, 7, 12, 5, 30
    );
END;
/

COMMIT;
