-- ============================================================================
-- DBA Cockpit - ORDS REST Endpoint Definitions
-- Oracle 19c SE2 + ORDS 24.x
-- ============================================================================

-- Enable ORDS for the COCKPIT schema
BEGIN
    ORDS.ENABLE_SCHEMA(
        p_enabled             => TRUE,
        p_schema              => 'COCKPIT',
        p_url_mapping_type    => 'BASE_PATH',
        p_url_mapping_pattern => 'cockpit',
        p_auto_rest_auth      => TRUE
    );
    COMMIT;
END;
/

-- ============================================================================
-- Module: cockpit_desk_v1 - Desk management
-- ============================================================================
BEGIN
    ORDS.DEFINE_MODULE(
        p_module_name    => 'cockpit_desk_v1',
        p_base_path      => '/api/v1/',
        p_items_per_page => 0,
        p_status         => 'PUBLISHED',
        p_comments       => 'DBA Cockpit - Desk Management API'
    );

    -- GET /api/v1/desks/mine
    ORDS.DEFINE_TEMPLATE(
        p_module_name    => 'cockpit_desk_v1',
        p_pattern        => 'desks/mine'
    );
    ORDS.DEFINE_HANDLER(
        p_module_name    => 'cockpit_desk_v1',
        p_pattern        => 'desks/mine',
        p_method         => 'GET',
        p_source_type    => 'plsql/block',
        p_source         => 'BEGIN cockpit.cockpit_desk_pkg.get_my_desks; END;',
        p_items_per_page => 0
    );

    -- POST /api/v1/desks
    ORDS.DEFINE_TEMPLATE(
        p_module_name    => 'cockpit_desk_v1',
        p_pattern        => 'desks'
    );
    ORDS.DEFINE_HANDLER(
        p_module_name    => 'cockpit_desk_v1',
        p_pattern        => 'desks',
        p_method         => 'POST',
        p_source_type    => 'plsql/block',
        p_source         => 'BEGIN cockpit.cockpit_desk_pkg.create_desk(:body_text); END;',
        p_items_per_page => 0
    );

    -- GET /api/v1/desks/:desk_id
    ORDS.DEFINE_TEMPLATE(
        p_module_name    => 'cockpit_desk_v1',
        p_pattern        => 'desks/:desk_id'
    );
    ORDS.DEFINE_HANDLER(
        p_module_name    => 'cockpit_desk_v1',
        p_pattern        => 'desks/:desk_id',
        p_method         => 'GET',
        p_source_type    => 'plsql/block',
        p_source         => 'BEGIN cockpit.cockpit_desk_pkg.get_desk_full(:desk_id); END;',
        p_items_per_page => 0
    );

    -- DELETE /api/v1/desks/:desk_id
    ORDS.DEFINE_HANDLER(
        p_module_name    => 'cockpit_desk_v1',
        p_pattern        => 'desks/:desk_id',
        p_method         => 'DELETE',
        p_source_type    => 'plsql/block',
        p_source         => 'BEGIN cockpit.cockpit_desk_pkg.delete_desk(:desk_id); END;',
        p_items_per_page => 0
    );

    -- POST /api/v1/desks/:desk_id/tabs
    ORDS.DEFINE_TEMPLATE(
        p_module_name    => 'cockpit_desk_v1',
        p_pattern        => 'desks/:desk_id/tabs'
    );
    ORDS.DEFINE_HANDLER(
        p_module_name    => 'cockpit_desk_v1',
        p_pattern        => 'desks/:desk_id/tabs',
        p_method         => 'POST',
        p_source_type    => 'plsql/block',
        p_source         => 'BEGIN cockpit.cockpit_desk_pkg.create_tab(:desk_id, :body_text); END;',
        p_items_per_page => 0
    );

    -- DELETE /api/v1/tabs/:tab_id
    ORDS.DEFINE_TEMPLATE(
        p_module_name    => 'cockpit_desk_v1',
        p_pattern        => 'tabs/:tab_id'
    );
    ORDS.DEFINE_HANDLER(
        p_module_name    => 'cockpit_desk_v1',
        p_pattern        => 'tabs/:tab_id',
        p_method         => 'DELETE',
        p_source_type    => 'plsql/block',
        p_source         => 'BEGIN cockpit.cockpit_desk_pkg.delete_tab(:tab_id); END;',
        p_items_per_page => 0
    );

    -- POST /api/v1/tabs/:tab_id/widgets
    ORDS.DEFINE_TEMPLATE(
        p_module_name    => 'cockpit_desk_v1',
        p_pattern        => 'tabs/:tab_id/widgets'
    );
    ORDS.DEFINE_HANDLER(
        p_module_name    => 'cockpit_desk_v1',
        p_pattern        => 'tabs/:tab_id/widgets',
        p_method         => 'POST',
        p_source_type    => 'plsql/block',
        p_source         => 'BEGIN cockpit.cockpit_desk_pkg.add_widget(:tab_id, :body_text); END;',
        p_items_per_page => 0
    );

    -- PUT /api/v1/widgets/:widget_id
    ORDS.DEFINE_TEMPLATE(
        p_module_name    => 'cockpit_desk_v1',
        p_pattern        => 'widgets/:widget_id'
    );
    ORDS.DEFINE_HANDLER(
        p_module_name    => 'cockpit_desk_v1',
        p_pattern        => 'widgets/:widget_id',
        p_method         => 'PUT',
        p_source_type    => 'plsql/block',
        p_source         => 'BEGIN cockpit.cockpit_desk_pkg.update_widget_position(:widget_id, :body_text); END;',
        p_items_per_page => 0
    );

    -- DELETE /api/v1/widgets/:widget_id
    ORDS.DEFINE_HANDLER(
        p_module_name    => 'cockpit_desk_v1',
        p_pattern        => 'widgets/:widget_id',
        p_method         => 'DELETE',
        p_source_type    => 'plsql/block',
        p_source         => 'BEGIN cockpit.cockpit_desk_pkg.remove_widget(:widget_id); END;',
        p_items_per_page => 0
    );

    -- POST /api/v1/desks/:desk_id/permissions
    ORDS.DEFINE_TEMPLATE(
        p_module_name    => 'cockpit_desk_v1',
        p_pattern        => 'desks/:desk_id/permissions'
    );
    ORDS.DEFINE_HANDLER(
        p_module_name    => 'cockpit_desk_v1',
        p_pattern        => 'desks/:desk_id/permissions',
        p_method         => 'POST',
        p_source_type    => 'plsql/block',
        p_source         => 'BEGIN cockpit.cockpit_desk_pkg.set_permissions(:desk_id, :body_text); END;',
        p_items_per_page => 0
    );

    -- GET /api/v1/catalog
    ORDS.DEFINE_TEMPLATE(
        p_module_name    => 'cockpit_desk_v1',
        p_pattern        => 'catalog'
    );
    ORDS.DEFINE_HANDLER(
        p_module_name    => 'cockpit_desk_v1',
        p_pattern        => 'catalog',
        p_method         => 'GET',
        p_source_type    => 'plsql/block',
        p_source         => 'BEGIN cockpit.cockpit_desk_pkg.get_catalog; END;',
        p_items_per_page => 0
    );

    -- GET /api/v1/desks/:desk_id/audit
    ORDS.DEFINE_TEMPLATE(
        p_module_name    => 'cockpit_desk_v1',
        p_pattern        => 'desks/:desk_id/audit'
    );
    ORDS.DEFINE_HANDLER(
        p_module_name    => 'cockpit_desk_v1',
        p_pattern        => 'desks/:desk_id/audit',
        p_method         => 'GET',
        p_source_type    => 'plsql/block',
        p_source         => 'BEGIN cockpit.cockpit_desk_pkg.get_desk_audit(:desk_id); END;',
        p_items_per_page => 0
    );

    -- ========================================================================
    -- Data endpoint: TSV datasource execution
    -- ========================================================================

    -- POST /api/v1/data/:ds_code
    ORDS.DEFINE_TEMPLATE(
        p_module_name    => 'cockpit_desk_v1',
        p_pattern        => 'data/:ds_code'
    );
    ORDS.DEFINE_HANDLER(
        p_module_name    => 'cockpit_desk_v1',
        p_pattern        => 'data/:ds_code',
        p_method         => 'POST',
        p_source_type    => 'plsql/block',
        p_source         => 'BEGIN cockpit.cockpit_data_pkg.execute_datasource(
                                :ds_code,
                                TO_NUMBER(:desk_id),
                                :body_text
                             ); END;',
        p_items_per_page => 0
    );

    -- GET /api/v1/data/:ds_code (simple, no params)
    ORDS.DEFINE_HANDLER(
        p_module_name    => 'cockpit_desk_v1',
        p_pattern        => 'data/:ds_code',
        p_method         => 'GET',
        p_source_type    => 'plsql/block',
        p_source         => 'BEGIN cockpit.cockpit_data_pkg.execute_datasource(:ds_code); END;',
        p_items_per_page => 0
    );

    -- ========================================================================
    -- Auth endpoints
    -- ========================================================================

    -- GET /api/v1/auth/me
    ORDS.DEFINE_TEMPLATE(
        p_module_name    => 'cockpit_desk_v1',
        p_pattern        => 'auth/me'
    );
    ORDS.DEFINE_HANDLER(
        p_module_name    => 'cockpit_desk_v1',
        p_pattern        => 'auth/me',
        p_method         => 'GET',
        p_source_type    => 'plsql/block',
        p_source         => 'BEGIN cockpit.cockpit_auth_pkg.get_my_profile; END;',
        p_items_per_page => 0
    );

    COMMIT;
END;
/

-- ============================================================================
-- ORDS Privileges & Roles (protect all endpoints)
-- ============================================================================
BEGIN
    ORDS.CREATE_ROLE('cockpit_user');
    ORDS.CREATE_ROLE('cockpit_admin');

    -- Protect all API endpoints
    ORDS.CREATE_PRIVILEGE(
        p_name          => 'cockpit_api_priv',
        p_role_name     => 'cockpit_user',
        p_label         => 'DBA Cockpit API Access',
        p_description   => 'Access to all cockpit API endpoints'
    );

    ORDS.CREATE_PRIVILEGE_MAPPING(
        p_privilege_name => 'cockpit_api_priv',
        p_pattern        => '/api/v1/*'
    );

    COMMIT;
END;
/
