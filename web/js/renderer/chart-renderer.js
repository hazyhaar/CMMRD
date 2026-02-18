/* ============================================================================
   ChartRenderer - Simple text-based chart (no external charting lib)
   Renders horizontal bar charts using CSS
   ============================================================================ */
'use strict';

var ChartRenderer = (function () {

    function render(bodyEl, widget, rows) {
        DomUtils.clear(bodyEl);

        if (!rows || rows.length === 0) {
            bodyEl.textContent = 'Aucune donnee';
            return;
        }

        var colsDef = widget.columnsDef;
        if (typeof colsDef === 'string') {
            try { colsDef = JSON.parse(colsDef); } catch (e) { colsDef = []; }
        }

        // Find label and value columns (first string col = label, first number col = value)
        var labelCol = null;
        var valueCol = null;
        if (colsDef && colsDef.length >= 2) {
            for (var i = 0; i < colsDef.length; i++) {
                if (!labelCol && colsDef[i].type === 'string') labelCol = colsDef[i].name;
                if (!valueCol && colsDef[i].type === 'number') valueCol = colsDef[i].name;
            }
        }
        if (!labelCol) labelCol = Object.keys(rows[0])[0];
        if (!valueCol) valueCol = Object.keys(rows[0])[1];

        // Find max value for scaling
        var maxVal = 0;
        rows.forEach(function (r) {
            var v = parseFloat(r[valueCol]) || 0;
            if (v > maxVal) maxVal = v;
        });
        if (maxVal === 0) maxVal = 1;

        var container = DomUtils.el('div', { className: 'chart-bars' });
        container.style.display = 'flex';
        container.style.flexDirection = 'column';
        container.style.gap = '4px';
        container.style.padding = '4px';

        rows.forEach(function (row) {
            var label = String(row[labelCol] || '');
            var value = parseFloat(row[valueCol]) || 0;
            var pct = Math.round((value / maxVal) * 100);

            var barRow = DomUtils.el('div');
            barRow.style.display = 'flex';
            barRow.style.alignItems = 'center';
            barRow.style.gap = '8px';

            var labelEl = DomUtils.el('span', null, label);
            labelEl.style.minWidth = '100px';
            labelEl.style.fontSize = 'var(--font-size-xs)';
            labelEl.style.color = 'var(--text-secondary)';
            labelEl.style.textAlign = 'right';

            var barOuter = DomUtils.el('div');
            barOuter.style.flex = '1';
            barOuter.style.height = '16px';
            barOuter.style.background = 'var(--bg-elevated)';
            barOuter.style.borderRadius = 'var(--radius-sm)';
            barOuter.style.overflow = 'hidden';

            var barInner = DomUtils.el('div');
            barInner.style.height = '100%';
            barInner.style.width = pct + '%';
            barInner.style.background = 'var(--accent-primary)';
            barInner.style.borderRadius = 'var(--radius-sm)';
            barInner.style.transition = 'width 0.3s ease';

            barOuter.appendChild(barInner);

            var valEl = DomUtils.el('span', null, String(value));
            valEl.style.minWidth = '50px';
            valEl.style.fontSize = 'var(--font-size-xs)';
            valEl.style.color = 'var(--text-primary)';

            DomUtils.append(barRow, [labelEl, barOuter, valEl]);
            container.appendChild(barRow);
        });

        bodyEl.appendChild(container);
    }

    WidgetFactory.register('CHART', { render: render });

    return { render: render };
})();
