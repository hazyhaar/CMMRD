# CMMRD — Cockpit Metadata-driven Monitoring for Relational Databases

A lightweight, metadata-driven DBA monitoring cockpit for **Oracle 19c SE2**, built entirely on **PL/SQL + ORDS + vanilla JavaScript**. No application server, no framework, no ORM — just the database, its native REST gateway, and the browser.

<p align="center">
  <img src="https://img.shields.io/badge/Oracle-19c_SE2-red?style=flat-square&logo=oracle" alt="Oracle 19c SE2">
  <img src="https://img.shields.io/badge/ORDS-24.x-blue?style=flat-square" alt="ORDS 24.x">
  <img src="https://img.shields.io/badge/Frontend-Vanilla_JS-yellow?style=flat-square&logo=javascript" alt="Vanilla JS">
  <img src="https://img.shields.io/badge/License-Apache_2.0-green?style=flat-square" alt="Apache 2.0">
</p>

---

## What it does

CMMRD turns Oracle system views into an interactive monitoring dashboard without leaving the Oracle ecosystem. New monitoring panels are added by inserting rows into Oracle tables — no code deployment, no frontend changes, no build step.

**Adding a widget is an INSERT statement.** The catalog, the layout, the data source, the rendering rules — everything lives in the database.

---

## Architecture

```
┌─────────────┐      ┌──────────────┐      ┌──────────────────────────┐
│   Browser   │─────▶│    Nginx     │─────▶│    ORDS 24.x             │
│  Vanilla JS │ TLS  │  TLS + CSP   │ HTTP │  REST → PL/SQL dispatch  │
│  GridStack  │◀─────│  Rate limit  │◀─────│  TSV for data, JSON for  │
│             │      │  WAF-ready   │      │  metadata                │
└─────────────┘      └──────────────┘      └────────────┬─────────────┘
                                                        │
                                                        ▼
                                           ┌──────────────────────────┐
                                           │     Oracle 19c SE2      │
                                           │                          │
                                           │  cockpit schema:         │
                                           │  ├─ meta_widget_catalog  │
                                           │  ├─ meta_data_sources    │
                                           │  ├─ meta_desks / tabs    │
                                           │  ├─ meta_widgets         │
                                           │  ├─ meta_users / roles   │
                                           │  ├─ meta_audit_actions   │
                                           │  └─ 5 PL/SQL packages   │
                                           │     (util, auth, redo,   │
                                           │      data, desk)         │
                                           └──────────────────────────┘
```

**Key design decision**: data travels as **TSV** (tab-separated values) from Oracle to the browser. JSON is reserved for metadata and desk structure. This keeps PL/SQL response generation trivial (`UTL_RAW` concatenation via `HTP.PRN`) and avoids the weight of JSON serialization for tabular result sets.

---

## Core concepts

### Metadata-driven widgets

Every widget on screen is defined by three Oracle rows:

| Table | Role |
|---|---|
| `meta_data_sources` | The SQL query or PL/SQL function that produces data |
| `meta_widget_catalog` | Display config: widget type (GRID, KPI, CHART), column definitions, formatting rules |
| `meta_widgets` | Instance placement: which tab, which position, which size |

To add redo log file monitoring, you insert one data source and one catalog entry. The frontend discovers it, renders it, and refreshes it — without touching JavaScript.

### Workspaces (Desks)

Three desk types enforce access boundaries:

| Type | Owner sees | Contractor sees | Shared access |
|---|---|---|---|
| `PERSONAL` | Everything | — | — |
| `CONTRACTOR` | Everything | Only whitelisted widgets, filtered by `desk_id` | — |
| `SHARED` | Everything | — | Explicit permission grants |

Contractor filtering is enforced at the PL/SQL layer (application-level, since Oracle SE2 lacks VPD). The `cockpit_data_pkg` injects a `WHERE desk_id = :bound_desk` predicate on contractor-flagged data sources, with SQL injection prevention via `DBMS_ASSERT.ENQUOTE_LITERAL` and regex whitelist validation.

### Drag & drop layout

Widgets are placed on a 12-column grid powered by [GridStack.js](https://gridstackjs.com/). Position changes fire an ORDS call that persists the new coordinates — the layout is always in the database.

---

## What it monitors (shipped)

The first monitoring pack covers **Oracle Redo Logs**:

| Widget | Type | Source |
|---|---|---|
| Redo Groups | GRID | `V$LOG` — status, size, sequence#, archival state |
| Redo Files | GRID | `V$LOGFILE` — member paths, file statuses |
| Redo KPIs | KPI | Total groups, total files, total size, switches/24h, switches/1h |
| Switch History | GRID | `V$LOG_HISTORY` — chronological log switch events |
| Full View | GRID | Joined `V$LOG` + `V$LOGFILE` with status highlighting |

Status cells are color-coded: `CURRENT` (green), `ACTIVE` (blue), `INACTIVE` (muted) — configured in the catalog JSON, not hardcoded in CSS.

Adding a new monitoring pack (tablespaces, sessions, ASH, AWR) follows the same pattern: write the PL/SQL function, insert the catalog rows.

---

## Project structure

```
CMMRD/
├── db/
│   ├── 01_schema.sql              # Schema creation + V$ grants
│   ├── 02_tables_catalog.sql      # Widget catalog + data sources
│   ├── 03_tables_desk.sql         # Desks, tabs, widgets, permissions
│   ├── 04_tables_auth.sql         # Users, roles, user_roles
│   ├── 05_tables_audit.sql        # Audit trail + purge procedure
│   ├── 06_pkg_util.sql            # TSV/JSON output, error handling, audit logging
│   ├── 07_pkg_auth.sql            # Authorization checks, role verification
│   ├── 08_pkg_redo.sql            # Redo log monitoring functions
│   ├── 09_pkg_data.sql            # Dynamic datasource execution + contractor filter
│   ├── 10_pkg_desk.sql            # Full desk/tab/widget CRUD
│   ├── 11_ords_endpoints.sql      # 13 ORDS REST endpoint definitions
│   ├── 20_data_catalog.sql        # Seed data: redo datasources + catalog entries
│   ├── 21_data_default_desk.sql   # Default DBA desk with pre-placed widgets
│   └── 99_install.sql             # Master install script (run this)
├── nginx/
│   └── cockpit.conf               # Production Nginx: TLS 1.3, CSP, rate limiting
└── web/
    ├── index.html                 # SPA entry point
    ├── css/
    │   ├── theme.css              # CSS custom properties (dark theme)
    │   ├── base.css               # Reset + globals
    │   ├── layout.css             # App shell layout
    │   └── components.css         # Widgets, tables, KPIs, modals, toasts
    └── js/
        ├── app.js                 # Bootstrap + module wiring
        ├── core/
        │   ├── event-bus.js       # Pub/sub for decoupled communication
        │   ├── state.js           # Centralized app state
        │   ├── api-client.js      # ORDS HTTP client (Bearer auth, TSV/JSON detection)
        │   └── router.js          # Hash-based SPA router
        ├── data/
        │   ├── tsv-parser.js      # TSV → JS objects with type coercion
        │   └── data-fetcher.js    # Auto-refresh with staggered timers
        ├── desk/
        │   ├── desk-manager.js    # Workspace navigation + CRUD
        │   ├── tab-manager.js     # Tab bar management
        │   └── widget-manager.js  # GridStack integration + widget lifecycle
        ├── renderer/
        │   ├── widget-factory.js  # Type → renderer dispatch
        │   ├── grid-renderer.js   # Data tables with status highlighting
        │   ├── kpi-renderer.js    # Key metric cards
        │   └── chart-renderer.js  # CSS-only horizontal bar charts
        └── ui/
            ├── dom-utils.js       # Safe DOM helpers (no innerHTML)
            ├── catalog-panel.js   # Widget catalog sidebar
            ├── modal.js           # Dialog component
            └── toast.js           # Notification toasts
```

---

## Installation

### Prerequisites

- Oracle 19c (SE2 or EE) with a CDB/PDB
- ORDS 24.x configured and running
- Nginx (for TLS termination and security headers)
- Grants on `V$LOG`, `V$LOGFILE`, `V$LOG_HISTORY` for the cockpit schema

### Database setup

Connect as SYSDBA and run the master install script:

```sql
@db/99_install.sql
```

This creates the `cockpit` schema, all tables, all five PL/SQL packages, the ORDS module with thirteen endpoints, and seeds the redo log monitoring pack with a default DBA desk.

### ORDS configuration

The endpoints are registered under the module `cockpit_desk_v1` at base path `/desk/v1/`. Ensure ORDS is configured for the cockpit schema with the `cockpit_user` and `cockpit_admin` roles.

### Nginx

Copy `nginx/cockpit.conf` and adjust:
- `server_name` to your domain
- TLS certificate paths
- ORDS backend address (default: `localhost:8080`)

### Frontend

Serve the `web/` directory as static files from Nginx. No build step required.

---

## Security model

| Layer | Mechanism |
|---|---|
| **Transport** | TLS 1.2/1.3 (Nginx), Mozilla Intermediate cipher suite |
| **HTTP headers** | HSTS, CSP (no inline scripts), X-Frame-Options DENY, COOP, COEP, CORP |
| **Rate limiting** | 30 req/s API, 5 req/s auth (Nginx) |
| **Authentication** | ORDS OAuth2 Bearer tokens |
| **Authorization** | Application-level role checks in PL/SQL (DBA_ADMIN, DBA_VIEWER, CONTRACTOR) |
| **Contractor isolation** | Parameterized `desk_id` filter injected by PL/SQL, not by the client |
| **SQL injection prevention** | `DBMS_ASSERT.ENQUOTE_LITERAL` + regex whitelist for dynamic predicates |
| **XSS prevention** | `textContent` only — no `innerHTML` with user data anywhere in the frontend |
| **Audit** | Every mutation logged in `meta_audit_actions` (autonomous transaction) |

---

## Design principles

1. **The database is the application.** Business logic lives in PL/SQL packages. The frontend is a thin rendering layer. ORDS is a transparent REST gateway.

2. **Metadata over code.** Adding monitoring capability is a data operation, not a code change. Widget definitions, data sources, column formats, status colors — all stored in Oracle tables.

3. **Zero build, zero framework.** Twenty JavaScript files loaded in dependency order. No webpack, no React, no npm. The CSP policy can be strict because there's nothing to bundle.

4. **TSV for bulk, JSON for structure.** Tabular data uses TSV to avoid JSON serialization overhead in PL/SQL. Desk structure and catalog metadata use JSON.

5. **SE2-compatible.** No Enterprise Edition features (no VPD, no Resource Manager, no In-Memory). Contractor isolation is enforced at the application layer with full audit trail.

---

## Extending with new monitoring

To add tablespace monitoring:

1. Write a PL/SQL function in a new or existing package that queries `DBA_TABLESPACES` / `DBA_DATA_FILES`
2. Insert a row into `meta_data_sources` pointing to that function
3. Insert a row into `meta_widget_catalog` defining the widget type, columns, and formatting
4. The widget appears in the catalog panel — drag it onto any desk

No frontend deployment. No JavaScript changes. No restart.

---

## Tech stack

| Component | Choice | Rationale |
|---|---|---|
| Database | Oracle 19c SE2 | Target environment — monitor the database from within itself |
| REST layer | ORDS 24.x | Native Oracle REST gateway, zero middleware |
| PL/SQL | 5 packages, ~1500 lines | All business logic, auth, data access, CRUD |
| Reverse proxy | Nginx | TLS termination, security headers, rate limiting |
| Frontend | Vanilla JS | No build toolchain, strict CSP, minimal attack surface |
| Layout engine | GridStack.js 10.x | Only external dependency — drag & drop grid |
| Styling | CSS custom properties | Dark theme, status colors configurable via variables |
| Data transport | TSV (data), JSON (metadata) | Lightweight serialization from PL/SQL |

---

## License

Apache 2.0 — see [LICENSE](LICENSE).
