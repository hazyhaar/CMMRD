-- ============================================================================
-- DBA Cockpit - Desk / Tab / Widget Tables
-- Oracle 19c SE2 compatible
-- ============================================================================

CREATE SEQUENCE cockpit.seq_desk START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE cockpit.seq_tab START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE cockpit.seq_widget START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE cockpit.seq_desk_perm START WITH 1 INCREMENT BY 1 NOCACHE;

-- ---------------------------------------------------------------------------
-- META_DESKS : workspaces (personal, contractor, shared)
-- ---------------------------------------------------------------------------
CREATE TABLE cockpit.meta_desks (
    desk_id             NUMBER(10)       DEFAULT cockpit.seq_desk.NEXTVAL PRIMARY KEY,
    desk_code           VARCHAR2(50)     NOT NULL,
    desk_name           VARCHAR2(200)    NOT NULL,
    owner_user          VARCHAR2(128)    NOT NULL,
    desk_type           VARCHAR2(20)     NOT NULL
        CONSTRAINT md_type_ck CHECK (desk_type IN (
            'PERSONAL','CONTRACTOR','SHARED'
        )),
    contractor_user     VARCHAR2(128),
    contractor_filter   VARCHAR2(4000)
        CONSTRAINT md_filter_json CHECK (contractor_filter IS JSON OR contractor_filter IS NULL),
    valid_from          DATE             DEFAULT SYSDATE,
    valid_to            DATE,
    is_active           NUMBER(1)        DEFAULT 1 NOT NULL
        CONSTRAINT md_active_ck CHECK (is_active IN (0,1)),
    created_at          TIMESTAMP        DEFAULT SYSTIMESTAMP,
    CONSTRAINT md_code_uk UNIQUE (desk_code)
);

CREATE INDEX cockpit.md_owner_ix ON cockpit.meta_desks(owner_user);
CREATE INDEX cockpit.md_contractor_ix ON cockpit.meta_desks(contractor_user);

-- ---------------------------------------------------------------------------
-- META_TABS : tabs within a desk
-- ---------------------------------------------------------------------------
CREATE TABLE cockpit.meta_tabs (
    tab_id              NUMBER(10)       DEFAULT cockpit.seq_tab.NEXTVAL PRIMARY KEY,
    desk_id             NUMBER(10)       NOT NULL
        CONSTRAINT mt_desk_fk REFERENCES cockpit.meta_desks(desk_id) ON DELETE CASCADE,
    tab_code            VARCHAR2(50)     NOT NULL,
    tab_name            VARCHAR2(200)    NOT NULL,
    tab_order           NUMBER(5)        DEFAULT 10,
    tab_icon            VARCHAR2(50),
    layout_columns      NUMBER(2)        DEFAULT 12,
    is_visible          NUMBER(1)        DEFAULT 1
        CONSTRAINT mt_visible_ck CHECK (is_visible IN (0,1)),
    created_at          TIMESTAMP        DEFAULT SYSTIMESTAMP,
    CONSTRAINT mt_desk_code_uk UNIQUE (desk_id, tab_code)
);

CREATE INDEX cockpit.mt_desk_order_ix ON cockpit.meta_tabs(desk_id, tab_order);

-- ---------------------------------------------------------------------------
-- META_WIDGETS : widget instances placed in a tab
-- ---------------------------------------------------------------------------
CREATE TABLE cockpit.meta_widgets (
    widget_id           NUMBER(10)       DEFAULT cockpit.seq_widget.NEXTVAL PRIMARY KEY,
    tab_id              NUMBER(10)       NOT NULL
        CONSTRAINT mw_tab_fk REFERENCES cockpit.meta_tabs(tab_id) ON DELETE CASCADE,
    catalog_id          NUMBER(10)       NOT NULL
        CONSTRAINT mw_catalog_fk REFERENCES cockpit.meta_widget_catalog(catalog_id),
    widget_title        VARCHAR2(200),
    position_x          NUMBER(2)        DEFAULT 0,
    position_y          NUMBER(3)        DEFAULT 0,
    size_w              NUMBER(2)        DEFAULT 6,
    size_h              NUMBER(2)        DEFAULT 4,
    refresh_sec         NUMBER(6)        DEFAULT 30,
    custom_params       VARCHAR2(4000)
        CONSTRAINT mw_params_json CHECK (custom_params IS JSON OR custom_params IS NULL),
    is_visible          NUMBER(1)        DEFAULT 1
        CONSTRAINT mw_visible_ck CHECK (is_visible IN (0,1)),
    created_at          TIMESTAMP        DEFAULT SYSTIMESTAMP
);

CREATE INDEX cockpit.mw_tab_ix ON cockpit.meta_widgets(tab_id);

-- ---------------------------------------------------------------------------
-- META_DESK_PERMISSIONS : who sees what in which desk
-- ---------------------------------------------------------------------------
CREATE TABLE cockpit.meta_desk_permissions (
    perm_id             NUMBER(10)       DEFAULT cockpit.seq_desk_perm.NEXTVAL PRIMARY KEY,
    desk_id             NUMBER(10)       NOT NULL
        CONSTRAINT mdp_desk_fk REFERENCES cockpit.meta_desks(desk_id) ON DELETE CASCADE,
    granted_user        VARCHAR2(128)    NOT NULL,
    can_read            NUMBER(1)        DEFAULT 1
        CONSTRAINT mdp_read_ck CHECK (can_read IN (0,1)),
    can_modify_layout   NUMBER(1)        DEFAULT 0
        CONSTRAINT mdp_modify_ck CHECK (can_modify_layout IN (0,1)),
    can_add_widgets     NUMBER(1)        DEFAULT 0
        CONSTRAINT mdp_add_ck CHECK (can_add_widgets IN (0,1)),
    can_execute         NUMBER(1)        DEFAULT 1
        CONSTRAINT mdp_exec_ck CHECK (can_execute IN (0,1)),
    catalog_whitelist   VARCHAR2(4000)
        CONSTRAINT mdp_wl_json CHECK (catalog_whitelist IS JSON OR catalog_whitelist IS NULL),
    created_at          TIMESTAMP        DEFAULT SYSTIMESTAMP,
    CONSTRAINT mdp_desk_user_uk UNIQUE (desk_id, granted_user)
);
