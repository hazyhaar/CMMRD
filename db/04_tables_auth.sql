-- ============================================================================
-- DBA Cockpit - Auth Tables (lightweight, OAuth2 ORDS handles transport)
-- Oracle 19c SE2 compatible
-- ============================================================================

CREATE SEQUENCE cockpit.seq_user START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE cockpit.seq_role START WITH 1 INCREMENT BY 1 NOCACHE;

-- ---------------------------------------------------------------------------
-- META_USERS : application users (roles/desk mapping, not password auth)
-- Passwords handled by ORDS OAuth2 - this table maps users to app roles
-- ---------------------------------------------------------------------------
CREATE TABLE cockpit.meta_users (
    user_id             NUMBER(10)       DEFAULT cockpit.seq_user.NEXTVAL PRIMARY KEY,
    username            VARCHAR2(128)    NOT NULL,
    display_name        VARCHAR2(200),
    email               VARCHAR2(400),
    is_active           NUMBER(1)        DEFAULT 1 NOT NULL
        CONSTRAINT mu_active_ck CHECK (is_active IN (0,1)),
    last_login_at       TIMESTAMP,
    created_at          TIMESTAMP        DEFAULT SYSTIMESTAMP,
    CONSTRAINT mu_username_uk UNIQUE (username)
);

-- ---------------------------------------------------------------------------
-- META_ROLES : application roles
-- ---------------------------------------------------------------------------
CREATE TABLE cockpit.meta_roles (
    role_id             NUMBER(10)       DEFAULT cockpit.seq_role.NEXTVAL PRIMARY KEY,
    role_code           VARCHAR2(50)     NOT NULL,
    role_name           VARCHAR2(200)    NOT NULL,
    description         VARCHAR2(1000),
    CONSTRAINT mr_code_uk UNIQUE (role_code)
);

-- ---------------------------------------------------------------------------
-- META_USER_ROLES : user <-> role mapping
-- ---------------------------------------------------------------------------
CREATE TABLE cockpit.meta_user_roles (
    user_id             NUMBER(10)       NOT NULL
        CONSTRAINT mur_user_fk REFERENCES cockpit.meta_users(user_id) ON DELETE CASCADE,
    role_id             NUMBER(10)       NOT NULL
        CONSTRAINT mur_role_fk REFERENCES cockpit.meta_roles(role_id) ON DELETE CASCADE,
    CONSTRAINT mur_pk PRIMARY KEY (user_id, role_id)
);

-- Seed default roles
INSERT INTO cockpit.meta_roles (role_code, role_name, description) VALUES
    ('DBA_ADMIN', 'DBA Administrateur', 'Acces complet, creation de desks, gestion des prestataires');
INSERT INTO cockpit.meta_roles (role_code, role_name, description) VALUES
    ('DBA_VIEWER', 'DBA Lecteur', 'Consultation des widgets dans les desks autorises');
INSERT INTO cockpit.meta_roles (role_code, role_name, description) VALUES
    ('CONTRACTOR', 'Prestataire', 'Acces restreint au desk attribue uniquement');

COMMIT;
