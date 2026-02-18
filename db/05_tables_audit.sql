-- ============================================================================
-- DBA Cockpit - Audit Tables
-- Oracle 19c SE2 compatible
-- ============================================================================

CREATE SEQUENCE cockpit.seq_audit START WITH 1 INCREMENT BY 1 NOCACHE;

-- ---------------------------------------------------------------------------
-- META_AUDIT_ACTIONS : application-level audit trail
-- ---------------------------------------------------------------------------
CREATE TABLE cockpit.meta_audit_actions (
    audit_id            NUMBER(15)       DEFAULT cockpit.seq_audit.NEXTVAL PRIMARY KEY,
    desk_id             NUMBER(10)
        CONSTRAINT maa_desk_fk REFERENCES cockpit.meta_desks(desk_id) ON DELETE SET NULL,
    username            VARCHAR2(128)    NOT NULL,
    action_type         VARCHAR2(50)     NOT NULL
        CONSTRAINT maa_type_ck CHECK (action_type IN (
            'LOGIN','LOGOUT',
            'VIEW_DESK','CREATE_DESK','DELETE_DESK',
            'VIEW_TAB','CREATE_TAB','DELETE_TAB',
            'VIEW_DATA','REFRESH_DATA','EXPORT_DATA',
            'ADD_WIDGET','REMOVE_WIDGET','MOVE_WIDGET',
            'CHANGE_PERMISSION'
        )),
    catalog_code        VARCHAR2(50),
    action_detail       VARCHAR2(4000),
    client_ip           VARCHAR2(45),
    user_agent          VARCHAR2(500),
    action_date         TIMESTAMP        DEFAULT SYSTIMESTAMP NOT NULL
);

CREATE INDEX cockpit.maa_desk_ix ON cockpit.meta_audit_actions(desk_id);
CREATE INDEX cockpit.maa_user_ix ON cockpit.meta_audit_actions(username);
CREATE INDEX cockpit.maa_date_ix ON cockpit.meta_audit_actions(action_date);
CREATE INDEX cockpit.maa_type_ix ON cockpit.meta_audit_actions(action_type);

-- ---------------------------------------------------------------------------
-- Purge old audit entries (no partitioning in SE2)
-- Schedule with DBMS_SCHEDULER
-- ---------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE cockpit.purge_audit (
    p_retention_days IN NUMBER DEFAULT 90
)
AS
BEGIN
    DELETE FROM cockpit.meta_audit_actions
    WHERE action_date < SYSTIMESTAMP - NUMTODSINTERVAL(p_retention_days, 'DAY');
    COMMIT;
END;
/
