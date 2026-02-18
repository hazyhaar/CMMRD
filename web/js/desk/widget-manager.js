/* ============================================================================
   WidgetManager - Widget lifecycle, Gridstack integration, data loading
   ============================================================================ */
'use strict';

var WidgetManager = (function () {
    var grid = null;

    function init() {
        EventBus.on('catalog:add-widget', onCatalogAdd);
    }

    function initGrid() {
        if (grid) {
            grid.removeAll();
            grid.destroy(false);
        }

        grid = GridStack.init({
            column: 12,
            cellHeight: 60,
            margin: 4,
            animate: true,
            float: false,
            disableResize: false,
            disableDrag: false
        }, '#widget-grid');

        grid.on('change', function (event, items) {
            if (!items) return;
            items.forEach(function (item) {
                saveWidgetPosition(item);
            });
        });
    }

    function renderWidgets(widgets) {
        initGrid();

        if (!widgets || widgets.length === 0) return;

        var deskId = State.get('currentDeskId');

        widgets.forEach(function (w) {
            addWidgetToGrid(w, deskId);
        });
    }

    function addWidgetToGrid(widget, deskId) {
        // Create widget DOM
        var card = DomUtils.el('div', { className: 'widget-card' });

        // Header
        var header = DomUtils.el('div', { className: 'widget-header' });
        header.appendChild(DomUtils.el('span', { className: 'widget-title' },
            widget.widgetTitle || widget.catalogName || 'Widget'));

        var controls = DomUtils.el('div', { className: 'widget-controls' });
        var refreshBtn = DomUtils.el('button', {
            className: 'widget-btn',
            title: 'Rafraichir',
            onClick: function (e) {
                e.stopPropagation();
                loadWidgetData(widget, bodyEl, deskId);
            }
        }, '↻');
        var removeBtn = DomUtils.el('button', {
            className: 'widget-btn',
            title: 'Retirer',
            onClick: function (e) {
                e.stopPropagation();
                removeWidget(widget.widgetId);
            }
        }, 'x');
        DomUtils.append(controls, [refreshBtn, removeBtn]);
        header.appendChild(controls);
        card.appendChild(header);

        // Body
        var bodyEl = DomUtils.el('div', { className: 'widget-body' });
        bodyEl.appendChild(DomUtils.el('div', { className: 'widget-loading' }, 'Chargement...'));
        card.appendChild(bodyEl);

        // Footer
        var footer = DomUtils.el('div', { className: 'widget-footer' });
        var statusSpan = DomUtils.el('span', null, '');
        var refreshInfo = DomUtils.el('span', null,
            widget.refreshSec > 0 ? ('↻ ' + widget.refreshSec + 's') : 'Manuel');
        DomUtils.append(footer, [statusSpan, refreshInfo]);
        card.appendChild(footer);

        // Add to gridstack
        var wrapper = DomUtils.el('div', { className: 'grid-stack-item-content' });
        wrapper.appendChild(card);

        grid.addWidget({
            x: widget.positionX || 0,
            y: widget.positionY || 0,
            w: widget.sizeW || 6,
            h: widget.sizeH || 4,
            id: 'widget-' + widget.widgetId,
            content: wrapper.outerHTML
        });

        // Replace the generated content with our live DOM
        var gsItem = DomUtils.qs('[gs-id="widget-' + widget.widgetId + '"]');
        if (gsItem) {
            var content = gsItem.querySelector('.grid-stack-item-content');
            if (content) {
                DomUtils.clear(content);
                content.appendChild(card);
            }
        }

        // Load data
        loadWidgetData(widget, bodyEl, deskId);

        // Start auto-refresh
        if (widget.refreshSec > 0) {
            DataFetcher.startRefresh(widget.widgetId, widget, deskId, function (rows) {
                WidgetFactory.render(bodyEl, widget, rows);
                statusSpan.textContent = 'MAJ ' + new Date().toLocaleTimeString('fr-FR');
            });
        }
    }

    function loadWidgetData(widget, bodyEl, deskId) {
        DomUtils.clear(bodyEl);
        bodyEl.appendChild(DomUtils.el('div', { className: 'widget-loading' }, 'Chargement...'));

        DataFetcher.fetchWidgetData(widget, deskId)
            .then(function (rows) {
                DomUtils.clear(bodyEl);
                WidgetFactory.render(bodyEl, widget, rows);
            })
            .catch(function (err) {
                DomUtils.clear(bodyEl);
                bodyEl.appendChild(DomUtils.el('div', { className: 'widget-loading status-danger' },
                    'Erreur: ' + err.message));
            });
    }

    function saveWidgetPosition(gsItem) {
        var id = gsItem.id;
        if (!id) return;
        var widgetId = id.replace('widget-', '');

        ApiClient.put('/api/v1/widgets/' + widgetId, {
            positionX: gsItem.x,
            positionY: gsItem.y,
            sizeW: gsItem.w,
            sizeH: gsItem.h
        }).catch(function () { /* silent save failure */ });
    }

    function removeWidget(widgetId) {
        Modal.confirm('Retirer ce widget ?', function () {
            ApiClient.del('/api/v1/widgets/' + widgetId)
                .then(function () {
                    DataFetcher.stopRefresh(widgetId);
                    var node = DomUtils.qs('[gs-id="widget-' + widgetId + '"]');
                    if (node && grid) grid.removeWidget(node);
                    Toast.success('Widget retire');
                })
                .catch(function (err) {
                    Toast.error('Erreur: ' + err.message);
                });
        });
    }

    function onCatalogAdd(catalogItem) {
        var tabId = State.get('currentTabId');
        if (!tabId) {
            Toast.error('Selectionnez un onglet d\'abord');
            return;
        }

        ApiClient.post('/api/v1/tabs/' + tabId + '/widgets', {
            catalogId: catalogItem.catalogId,
            widgetTitle: catalogItem.catalogName,
            positionX: 0,
            positionY: 0,
            sizeW: 6,
            sizeH: 4,
            refreshSec: catalogItem.defaultRefresh || 30
        })
        .then(function () {
            Toast.success('Widget ajoute');
            // Reload current desk/tab
            var deskId = State.get('currentDeskId');
            State.set('currentDeskId', null);
            EventBus.emit('route:change', { deskId: deskId, tabId: tabId });
        })
        .catch(function (err) {
            Toast.error('Erreur: ' + err.message);
        });
    }

    return { init: init, renderWidgets: renderWidgets };
})();
