/* ============================================================================
   GridRenderer - Renders tabular data as a <table>
   Uses columnsDef from widget catalog for formatting
   Never uses innerHTML with data - only textContent
   ============================================================================ */
'use strict';

var GridRenderer = (function () {

    function render(bodyEl, widget, rows) {
        DomUtils.clear(bodyEl);

        var colsDef = parseColumnsDef(widget.columnsDef);
        if (!colsDef || colsDef.length === 0) {
            // Auto-detect columns from data
            if (rows.length > 0) {
                colsDef = Object.keys(rows[0]).map(function (key) {
                    return { name: key, label: key, type: 'string', align: 'left' };
                });
            } else {
                bodyEl.textContent = 'Aucune donnee';
                return;
            }
        }

        if (rows.length === 0) {
            bodyEl.textContent = 'Aucune donnee';
            return;
        }

        var table = DomUtils.el('table', { className: 'data-table' });

        // Thead
        var thead = DomUtils.el('thead');
        var headerRow = DomUtils.el('tr');
        colsDef.forEach(function (col) {
            var th = DomUtils.el('th', {
                className: col.align ? ('align-' + col.align) : ''
            }, col.label || col.name);
            if (col.width) th.style.width = col.width + 'px';
            headerRow.appendChild(th);
        });
        thead.appendChild(headerRow);
        table.appendChild(thead);

        // Tbody
        var tbody = DomUtils.el('tbody');
        rows.forEach(function (row) {
            var tr = DomUtils.el('tr');
            colsDef.forEach(function (col) {
                var val = row[col.name];
                var td = DomUtils.el('td', {
                    className: col.align ? ('align-' + col.align) : ''
                });

                // Format value
                var displayVal = formatCell(val, col);
                td.textContent = displayVal;

                // Apply highlight if configured
                if (col.highlight && val && col.highlight[val]) {
                    td.classList.add('status-' + col.highlight[val]);
                }

                tr.appendChild(td);
            });
            tbody.appendChild(tr);
        });
        table.appendChild(tbody);

        bodyEl.appendChild(table);
    }

    function parseColumnsDef(colsDef) {
        if (!colsDef) return null;
        if (Array.isArray(colsDef)) return colsDef;
        if (typeof colsDef === 'string') {
            try { return JSON.parse(colsDef); } catch (e) { return null; }
        }
        return null;
    }

    function formatCell(val, col) {
        if (val === null || val === undefined) return '';
        if (col.format && col.type === 'number') {
            return DomUtils.formatNumber(val, col.format);
        }
        return String(val);
    }

    // Register with factory
    WidgetFactory.register('GRID', { render: render });

    return { render: render };
})();
