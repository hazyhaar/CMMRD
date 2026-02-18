-- ============================================================================
-- DBA Cockpit - Catalog Tables (the "things you can call")
-- Oracle 19c SE2 compatible - No JSON type, use VARCHAR2/CLOB + IS JSON
-- ============================================================================

-- Sequences
CREATE SEQUENCE cockpit.seq_catalog START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE cockpit.seq_datasource START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE cockpit.seq_js_function START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE cockpit.seq_css_rule START WITH 1 INCREMENT BY 1 NOCACHE;

-- ---------------------------------------------------------------------------
-- META_WIDGET_CATALOG : the library of available widgets
-- ---------------------------------------------------------------------------
CREATE TABLE cockpit.meta_widget_catalog (
    catalog_id          NUMBER(10)       DEFAULT cockpit.seq_catalog.NEXTVAL PRIMARY KEY,
    catalog_code        VARCHAR2(50)     NOT NULL,
    catalog_name        VARCHAR2(200)    NOT NULL,
    category            VARCHAR2(50)     NOT NULL
        CONSTRAINT mwc_category_ck CHECK (category IN (
            'REDO','SESSIONS','STORAGE','PERFORMANCE','NETWORK','CUSTOM'
        )),
    widget_type         VARCHAR2(20)     NOT NULL
        CONSTRAINT mwc_wtype_ck CHECK (widget_type IN (
            'GRID','CHART','KPI','LOG','TREE'
        )),
    datasource_id       NUMBER(10),
    columns_def         VARCHAR2(4000)
        CONSTRAINT mwc_coldef_json CHECK (columns_def IS JSON),
    default_refresh_sec NUMBER(6)        DEFAULT 30,
    min_privilege       VARCHAR2(50)     DEFAULT 'DBA_VIEWER',
    js_render           CLOB,
    js_init             CLOB,
    icon_name           VARCHAR2(50)     DEFAULT 'table',
    description         VARCHAR2(1000),
    is_active           NUMBER(1)        DEFAULT 1 NOT NULL
        CONSTRAINT mwc_active_ck CHECK (is_active IN (0,1)),
    created_by          VARCHAR2(128)    DEFAULT SYS_CONTEXT('USERENV','SESSION_USER'),
    created_at          TIMESTAMP        DEFAULT SYSTIMESTAMP,
    CONSTRAINT mwc_code_uk UNIQUE (catalog_code)
);

CREATE INDEX cockpit.mwc_category_ix ON cockpit.meta_widget_catalog(category);

-- ---------------------------------------------------------------------------
-- META_DATA_SOURCES : SQL queries / PL/SQL functions behind widgets
-- ---------------------------------------------------------------------------
CREATE TABLE cockpit.meta_data_sources (
    datasource_id       NUMBER(10)       DEFAULT cockpit.seq_datasource.NEXTVAL PRIMARY KEY,
    ds_code             VARCHAR2(50)     NOT NULL,
    ds_name             VARCHAR2(200)    NOT NULL,
    ds_type             VARCHAR2(20)     NOT NULL
        CONSTRAINT mds_type_ck CHECK (ds_type IN (
            'SQL_QUERY','PLSQL_FUNCTION'
        )),
    sql_query           CLOB,
    plsql_call          VARCHAR2(500),
    supports_pagination NUMBER(1)        DEFAULT 0
        CONSTRAINT mds_pagin_ck CHECK (supports_pagination IN (0,1)),
    default_page_size   NUMBER(5)        DEFAULT 50,
    required_privilege  VARCHAR2(50)     DEFAULT 'DBA_VIEWER',
    is_active           NUMBER(1)        DEFAULT 1 NOT NULL
        CONSTRAINT mds_active_ck CHECK (is_active IN (0,1)),
    created_by          VARCHAR2(128)    DEFAULT SYS_CONTEXT('USERENV','SESSION_USER'),
    created_at          TIMESTAMP        DEFAULT SYSTIMESTAMP,
    CONSTRAINT mds_code_uk UNIQUE (ds_code)
);

ALTER TABLE cockpit.meta_widget_catalog
    ADD CONSTRAINT mwc_ds_fk FOREIGN KEY (datasource_id)
    REFERENCES cockpit.meta_data_sources(datasource_id);

-- ---------------------------------------------------------------------------
-- META_JS_FUNCTIONS : reusable JS functions stored in DB
-- ---------------------------------------------------------------------------
CREATE TABLE cockpit.meta_js_functions (
    js_function_id      NUMBER(10)       DEFAULT cockpit.seq_js_function.NEXTVAL PRIMARY KEY,
    function_code       VARCHAR2(60)     NOT NULL,
    function_name       VARCHAR2(200)    NOT NULL,
    function_body       CLOB             NOT NULL,
    scope               VARCHAR2(20)     DEFAULT 'GLOBAL'
        CONSTRAINT mjf_scope_ck CHECK (scope IN ('GLOBAL','WIDGET','ACTION')),
    is_active           NUMBER(1)        DEFAULT 1 NOT NULL
        CONSTRAINT mjf_active_ck CHECK (is_active IN (0,1)),
    created_by          VARCHAR2(128)    DEFAULT SYS_CONTEXT('USERENV','SESSION_USER'),
    created_at          TIMESTAMP        DEFAULT SYSTIMESTAMP,
    CONSTRAINT mjf_code_uk UNIQUE (function_code)
);

-- ---------------------------------------------------------------------------
-- META_CSS_RULES : custom CSS rules stored in DB
-- ---------------------------------------------------------------------------
CREATE TABLE cockpit.meta_css_rules (
    css_rule_id         NUMBER(10)       DEFAULT cockpit.seq_css_rule.NEXTVAL PRIMARY KEY,
    rule_code           VARCHAR2(60)     NOT NULL,
    css_selector        VARCHAR2(400)    NOT NULL,
    css_properties      VARCHAR2(4000)   NOT NULL,
    media_query         VARCHAR2(400),
    display_order       NUMBER(5)        DEFAULT 100,
    is_active           NUMBER(1)        DEFAULT 1 NOT NULL
        CONSTRAINT mcr_active_ck CHECK (is_active IN (0,1)),
    created_by          VARCHAR2(128)    DEFAULT SYS_CONTEXT('USERENV','SESSION_USER'),
    created_at          TIMESTAMP        DEFAULT SYSTIMESTAMP,
    CONSTRAINT mcr_code_uk UNIQUE (rule_code)
);
