-- ============================================================================
-- COCKPIT_AUTH_PKG : authentication helpers & permission checks
-- Oracle 19c SE2 compatible
-- Auth transport = ORDS OAuth2, this package handles app-level authorization
-- ============================================================================

CREATE OR REPLACE PACKAGE cockpit.cockpit_auth_pkg
AS
    -- Check if user has a given role
    FUNCTION has_role (
        p_username  IN VARCHAR2,
        p_role_code IN VARCHAR2
    ) RETURN BOOLEAN;

    -- Check if user can access a desk
    FUNCTION can_access_desk (
        p_username  IN VARCHAR2,
        p_desk_id   IN NUMBER
    ) RETURN BOOLEAN;

    -- Check if user can use a catalog widget in a desk context
    FUNCTION can_use_widget (
        p_username      IN VARCHAR2,
        p_desk_id       IN NUMBER,
        p_catalog_code  IN VARCHAR2
    ) RETURN BOOLEAN;

    -- Get contractor filter JSON for a desk (for data filtering)
    FUNCTION get_contractor_filter (
        p_desk_id   IN NUMBER
    ) RETURN VARCHAR2;

    -- Record user login
    PROCEDURE record_login (
        p_username  IN VARCHAR2
    );

    -- Get current user profile as JSON
    PROCEDURE get_my_profile;

END cockpit_auth_pkg;
/

CREATE OR REPLACE PACKAGE BODY cockpit.cockpit_auth_pkg
AS

    FUNCTION has_role (
        p_username  IN VARCHAR2,
        p_role_code IN VARCHAR2
    ) RETURN BOOLEAN
    IS
        l_cnt NUMBER;
    BEGIN
        SELECT COUNT(*) INTO l_cnt
        FROM cockpit.meta_user_roles ur
        JOIN cockpit.meta_users u ON u.user_id = ur.user_id
        JOIN cockpit.meta_roles r ON r.role_id = ur.role_id
        WHERE u.username = p_username
          AND u.is_active = 1
          AND r.role_code = p_role_code;
        RETURN l_cnt > 0;
    END has_role;

    FUNCTION can_access_desk (
        p_username  IN VARCHAR2,
        p_desk_id   IN NUMBER
    ) RETURN BOOLEAN
    IS
        l_cnt NUMBER;
    BEGIN
        -- Owner always has access
        SELECT COUNT(*) INTO l_cnt
        FROM cockpit.meta_desks
        WHERE desk_id = p_desk_id
          AND is_active = 1
          AND (owner_user = p_username OR contractor_user = p_username)
          AND (valid_to IS NULL OR valid_to >= SYSDATE);
        IF l_cnt > 0 THEN RETURN TRUE; END IF;

        -- Check explicit permissions
        SELECT COUNT(*) INTO l_cnt
        FROM cockpit.meta_desk_permissions dp
        JOIN cockpit.meta_desks d ON d.desk_id = dp.desk_id
        WHERE dp.desk_id = p_desk_id
          AND dp.granted_user = p_username
          AND dp.can_read = 1
          AND d.is_active = 1
          AND (d.valid_to IS NULL OR d.valid_to >= SYSDATE);
        RETURN l_cnt > 0;
    END can_access_desk;

    FUNCTION can_use_widget (
        p_username      IN VARCHAR2,
        p_desk_id       IN NUMBER,
        p_catalog_code  IN VARCHAR2
    ) RETURN BOOLEAN
    IS
        l_whitelist VARCHAR2(4000);
    BEGIN
        -- Owner can use any widget
        DECLARE
            l_cnt NUMBER;
        BEGIN
            SELECT COUNT(*) INTO l_cnt
            FROM cockpit.meta_desks
            WHERE desk_id = p_desk_id AND owner_user = p_username;
            IF l_cnt > 0 THEN RETURN TRUE; END IF;
        END;

        -- Check whitelist for non-owners
        BEGIN
            SELECT dp.catalog_whitelist INTO l_whitelist
            FROM cockpit.meta_desk_permissions dp
            WHERE dp.desk_id = p_desk_id
              AND dp.granted_user = p_username;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN RETURN FALSE;
        END;

        -- NULL whitelist = all allowed
        IF l_whitelist IS NULL THEN RETURN TRUE; END IF;

        -- Check if catalog_code is in the JSON array whitelist
        DECLARE
            l_cnt NUMBER;
        BEGIN
            SELECT COUNT(*) INTO l_cnt
            FROM JSON_TABLE(l_whitelist, '$[*]' COLUMNS (val VARCHAR2(50) PATH '$'))
            WHERE val = p_catalog_code;
            RETURN l_cnt > 0;
        END;
    END can_use_widget;

    FUNCTION get_contractor_filter (
        p_desk_id   IN NUMBER
    ) RETURN VARCHAR2
    IS
        l_filter VARCHAR2(4000);
    BEGIN
        SELECT contractor_filter INTO l_filter
        FROM cockpit.meta_desks
        WHERE desk_id = p_desk_id;
        RETURN l_filter;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN RETURN NULL;
    END get_contractor_filter;

    PROCEDURE record_login (
        p_username  IN VARCHAR2
    )
    IS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        UPDATE cockpit.meta_users
        SET last_login_at = SYSTIMESTAMP
        WHERE username = p_username;

        IF SQL%ROWCOUNT = 0 THEN
            INSERT INTO cockpit.meta_users (username, display_name)
            VALUES (p_username, p_username);
        END IF;
        COMMIT;

        cockpit_util_pkg.audit_log(
            p_action_type => 'LOGIN',
            p_detail      => 'User logged in'
        );
    END record_login;

    PROCEDURE get_my_profile
    IS
        l_user VARCHAR2(128) := cockpit_util_pkg.current_user_name();
        l_json CLOB;
    BEGIN
        SELECT JSON_OBJECT(
            'username'    VALUE u.username,
            'displayName' VALUE u.display_name,
            'email'       VALUE u.email,
            'roles'       VALUE (
                SELECT JSON_ARRAYAGG(r.role_code)
                FROM cockpit.meta_user_roles ur2
                JOIN cockpit.meta_roles r ON r.role_id = ur2.role_id
                WHERE ur2.user_id = u.user_id
            ),
            'lastLogin'   VALUE TO_CHAR(u.last_login_at, 'YYYY-MM-DD"T"HH24:MI:SS')
        ) INTO l_json
        FROM cockpit.meta_users u
        WHERE u.username = l_user;

        cockpit_util_pkg.emit_json(l_json);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            cockpit_util_pkg.emit_error(404, 'USER_NOT_FOUND', 'Utilisateur non trouve');
    END get_my_profile;

END cockpit_auth_pkg;
/
