/* ============================================================================
   KpiRenderer - Renders key-value metrics as KPI cards
   Expects rows with METRIC and VALUE columns (from redo stats etc.)
   ============================================================================ */
'use strict';

var KpiRenderer = (function () {

    var metricLabels = {
        'TOTAL_GROUPS':   'Groupes',
        'TOTAL_FILES':    'Fichiers',
        'TOTAL_SIZE_MB':  'Taille totale (Mo)',
        'CURRENT_GROUP':  'Groupe courant',
        'SWITCHES_24H':   'Switches 24h',
        'SWITCHES_1H':    'Switches 1h'
    };

    function render(bodyEl, widget, rows) {
        DomUtils.clear(bodyEl);

        if (!rows || rows.length === 0) {
            bodyEl.textContent = 'Aucune donnee';
            return;
        }

        var container = DomUtils.el('div', { className: 'kpi-container' });

        rows.forEach(function (row) {
            var metric = row.METRIC || row.metric || '';
            var value = row.VALUE || row.value || '';

            var card = DomUtils.el('div', { className: 'kpi-card' });
            card.appendChild(DomUtils.el('div', { className: 'kpi-value' }, value));
            card.appendChild(DomUtils.el('div', { className: 'kpi-label' },
                metricLabels[metric] || metric));

            container.appendChild(card);
        });

        bodyEl.appendChild(container);
    }

    WidgetFactory.register('KPI', { render: render });

    return { render: render };
})();
