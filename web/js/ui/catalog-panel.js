/* ============================================================================
   CatalogPanel - Widget catalog sidebar
   ============================================================================ */
'use strict';

var CatalogPanel = (function () {
    var panel;
    var isOpen = false;

    function init() {
        panel = DomUtils.qs('#catalog-panel');
        DomUtils.qs('#btn-catalog').addEventListener('click', toggle);
        DomUtils.qs('#btn-close-catalog').addEventListener('click', close);
    }

    function toggle() {
        if (isOpen) close(); else openPanel();
    }

    function openPanel() {
        panel.classList.remove('panel-hidden');
        isOpen = true;
        loadCatalog();
    }

    function close() {
        panel.classList.add('panel-hidden');
        isOpen = false;
    }

    function loadCatalog() {
        var catalog = State.get('catalog');
        if (catalog && catalog.length > 0) {
            render(catalog);
            return;
        }

        ApiClient.get('/api/v1/catalog')
            .then(function (resp) {
                var data = resp.data;
                State.set('catalog', data);
                render(data);
            })
            .catch(function (err) {
                Toast.error('Erreur chargement catalogue: ' + err.message);
            });
    }

    function render(catalog) {
        var container = DomUtils.qs('#catalog-categories');
        DomUtils.clear(container);

        // Group by category
        var categories = {};
        catalog.forEach(function (item) {
            if (!categories[item.category]) categories[item.category] = [];
            categories[item.category].push(item);
        });

        Object.keys(categories).sort().forEach(function (cat) {
            var section = DomUtils.el('div', { className: 'catalog-category' });
            section.appendChild(DomUtils.el('div', { className: 'catalog-category-title' }, cat));

            categories[cat].forEach(function (item) {
                var card = DomUtils.el('div', {
                    className: 'catalog-item',
                    dataset: { catalogId: item.catalogId },
                    draggable: 'true'
                });
                card.appendChild(DomUtils.el('div', { className: 'item-name' }, item.catalogName));
                if (item.description) {
                    card.appendChild(DomUtils.el('div', { className: 'item-desc' }, item.description));
                }

                // Click to add widget to current tab
                card.addEventListener('click', function () {
                    EventBus.emit('catalog:add-widget', item);
                });

                section.appendChild(card);
            });

            container.appendChild(section);
        });
    }

    return { init: init, toggle: toggle, close: close };
})();
