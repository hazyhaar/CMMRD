-- ============================================================================
-- DBA Cockpit - Seed Data: Datasources + Widget Catalog
-- Oracle 19c SE2 compatible
-- ============================================================================

-- ===================== DATA SOURCES =====================

-- DS: Redo log groups
INSERT INTO cockpit.meta_data_sources (ds_code, ds_name, ds_type, plsql_call)
VALUES ('DS_REDO_GROUPS', 'Groupes de Redo Logs', 'PLSQL_FUNCTION', 'cockpit.cockpit_redo_pkg.get_log_groups');

-- DS: Redo log files
INSERT INTO cockpit.meta_data_sources (ds_code, ds_name, ds_type, plsql_call)
VALUES ('DS_REDO_FILES', 'Fichiers de Redo Logs', 'PLSQL_FUNCTION', 'cockpit.cockpit_redo_pkg.get_log_files');

-- DS: Redo groups + files joined
INSERT INTO cockpit.meta_data_sources (ds_code, ds_name, ds_type, plsql_call)
VALUES ('DS_REDO_FULL', 'Redo Logs Complets', 'PLSQL_FUNCTION', 'cockpit.cockpit_redo_pkg.get_log_groups_with_files');

-- DS: Redo statistics (KPI)
INSERT INTO cockpit.meta_data_sources (ds_code, ds_name, ds_type, plsql_call)
VALUES ('DS_REDO_STATS', 'Statistiques Redo', 'PLSQL_FUNCTION', 'cockpit.cockpit_redo_pkg.get_log_statistics');

-- DS: Log switch history
INSERT INTO cockpit.meta_data_sources (ds_code, ds_name, ds_type, plsql_call)
VALUES ('DS_REDO_HISTORY', 'Historique Log Switches', 'PLSQL_FUNCTION', 'cockpit.cockpit_redo_pkg.get_log_switch_history');

-- ===================== WIDGET CATALOG =====================

-- Widget: Redo Groups Grid
INSERT INTO cockpit.meta_widget_catalog (
    catalog_code, catalog_name, category, widget_type,
    datasource_id, columns_def, default_refresh_sec,
    icon_name, description
) VALUES (
    'REDO_GROUPS', 'Redo Log Groups', 'REDO', 'GRID',
    (SELECT datasource_id FROM cockpit.meta_data_sources WHERE ds_code = 'DS_REDO_GROUPS'),
    '[' ||
        '{"name":"GROUP_NUM","label":"Groupe #","type":"number","align":"right","width":80},' ||
        '{"name":"THREAD_NUM","label":"Thread","type":"number","align":"right","width":70},' ||
        '{"name":"SEQUENCE_NUM","label":"Sequence","type":"number","align":"right","width":90},' ||
        '{"name":"SIZE_MB","label":"Taille (Mo)","type":"number","align":"right","width":100,"format":"0.00"},' ||
        '{"name":"MEMBERS","label":"Membres","type":"number","align":"right","width":80},' ||
        '{"name":"ARCHIVED","label":"Archive","type":"string","align":"center","width":70},' ||
        '{"name":"STATUS","label":"Statut","type":"string","align":"center","width":100,"highlight":{"CURRENT":"success","ACTIVE":"info","INACTIVE":"muted"}},' ||
        '{"name":"FIRST_TIME","label":"Premier changement","type":"string","align":"left","width":160}' ||
    ']',
    30, 'database', 'Affiche les groupes de redo log (v$log)'
);

-- Widget: Redo Files Grid
INSERT INTO cockpit.meta_widget_catalog (
    catalog_code, catalog_name, category, widget_type,
    datasource_id, columns_def, default_refresh_sec,
    icon_name, description
) VALUES (
    'REDO_FILES', 'Redo Log Files', 'REDO', 'GRID',
    (SELECT datasource_id FROM cockpit.meta_data_sources WHERE ds_code = 'DS_REDO_FILES'),
    '[' ||
        '{"name":"GROUP_NUM","label":"Groupe #","type":"number","align":"right","width":80},' ||
        '{"name":"STATUS","label":"Statut","type":"string","align":"center","width":80},' ||
        '{"name":"FILE_TYPE","label":"Type","type":"string","align":"center","width":80},' ||
        '{"name":"FILE_PATH","label":"Chemin du fichier","type":"string","align":"left","width":400},' ||
        '{"name":"IS_FRA","label":"FRA","type":"string","align":"center","width":50}' ||
    ']',
    60, 'file', 'Affiche les fichiers de redo log (v$logfile)'
);

-- Widget: Redo Stats KPI
INSERT INTO cockpit.meta_widget_catalog (
    catalog_code, catalog_name, category, widget_type,
    datasource_id, columns_def, default_refresh_sec,
    icon_name, description
) VALUES (
    'REDO_STATS', 'Redo Statistics', 'REDO', 'KPI',
    (SELECT datasource_id FROM cockpit.meta_data_sources WHERE ds_code = 'DS_REDO_STATS'),
    '[' ||
        '{"name":"METRIC","label":"Metrique","type":"string"},' ||
        '{"name":"VALUE","label":"Valeur","type":"string"}' ||
    ']',
    15, 'activity', 'Indicateurs cles des redo logs'
);

-- Widget: Log Switch History Grid
INSERT INTO cockpit.meta_widget_catalog (
    catalog_code, catalog_name, category, widget_type,
    datasource_id, columns_def, default_refresh_sec,
    icon_name, description
) VALUES (
    'REDO_HISTORY', 'Log Switch History', 'REDO', 'GRID',
    (SELECT datasource_id FROM cockpit.meta_data_sources WHERE ds_code = 'DS_REDO_HISTORY'),
    '[' ||
        '{"name":"THREAD_NUM","label":"Thread","type":"number","align":"right","width":70},' ||
        '{"name":"SEQUENCE_NUM","label":"Sequence","type":"number","align":"right","width":90},' ||
        '{"name":"FIRST_CHANGE","label":"First Change#","type":"number","align":"right","width":120},' ||
        '{"name":"SWITCH_TIME","label":"Heure du switch","type":"string","align":"left","width":160},' ||
        '{"name":"CHANGES","label":"Changements","type":"number","align":"right","width":120}' ||
    ']',
    30, 'history', 'Historique des log switches (v$log_history)'
);

-- Widget: Redo Groups + Files joined
INSERT INTO cockpit.meta_widget_catalog (
    catalog_code, catalog_name, category, widget_type,
    datasource_id, columns_def, default_refresh_sec,
    icon_name, description
) VALUES (
    'REDO_FULL', 'Redo Logs Complets', 'REDO', 'GRID',
    (SELECT datasource_id FROM cockpit.meta_data_sources WHERE ds_code = 'DS_REDO_FULL'),
    '[' ||
        '{"name":"GROUP_NUM","label":"Groupe #","type":"number","align":"right","width":80},' ||
        '{"name":"THREAD_NUM","label":"Thread","type":"number","align":"right","width":70},' ||
        '{"name":"SIZE_MB","label":"Taille (Mo)","type":"number","align":"right","width":100},' ||
        '{"name":"GROUP_STATUS","label":"Statut Groupe","type":"string","align":"center","width":110,"highlight":{"CURRENT":"success","ACTIVE":"info","INACTIVE":"muted"}},' ||
        '{"name":"ARCHIVED","label":"Archive","type":"string","align":"center","width":70},' ||
        '{"name":"FILE_PATH","label":"Fichier","type":"string","align":"left","width":350},' ||
        '{"name":"FILE_STATUS","label":"Statut Fichier","type":"string","align":"center","width":100},' ||
        '{"name":"FILE_TYPE","label":"Type","type":"string","align":"center","width":70}' ||
    ']',
    30, 'layers', 'Vue jointe groupes + fichiers de redo log'
);

COMMIT;
