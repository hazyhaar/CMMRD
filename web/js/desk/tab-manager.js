/* ============================================================================
   TabManager - Tab rendering and switching
   ============================================================================ */
'use strict';

var TabManager = (function () {

    function init() {
        DomUtils.qs('#btn-new-tab').addEventListener('click', promptNewTab);
    }

    function renderTabs(tabs) {
        var list = DomUtils.qs('#tab-list');
        DomUtils.clear(list);

        tabs.forEach(function (tab) {
            var li = DomUtils.el('li', {
                dataset: { tabId: tab.tabId },
                onClick: function () {
                    switchTab(tab.tabId);
                }
            });

            if (tab.tabIcon) {
                li.appendChild(DomUtils.el('span', { className: 'tab-icon' }, tab.tabIcon));
            }
            li.appendChild(DomUtils.el('span', null, tab.tabName));

            var closeBtn = DomUtils.el('span', {
                className: 'tab-close',
                onClick: function (e) {
                    e.stopPropagation();
                    deleteTab(tab.tabId);
                }
            }, 'x');
            li.appendChild(closeBtn);

            list.appendChild(li);
        });
    }

    function switchTab(tabId) {
        State.set('currentTabId', tabId);

        // Highlight active tab
        DomUtils.qsa('#tab-list li').forEach(function (li) {
            li.classList.toggle('active', parseInt(li.dataset.tabId) === tabId);
        });

        // Stop all refresh timers
        DataFetcher.stopAll();

        // Load widgets for this tab
        var desk = State.get('currentDesk');
        if (!desk || !desk.tabs) return;

        var tab = desk.tabs.find(function (t) { return t.tabId === tabId; });
        if (!tab) return;

        WidgetManager.renderWidgets(tab.widgets || []);
    }

    function promptNewTab() {
        var deskId = State.get('currentDeskId');
        if (!deskId) return;

        var form = DomUtils.el('div');
        var nameGroup = DomUtils.el('div', { className: 'form-group' });
        nameGroup.appendChild(DomUtils.el('label', { className: 'form-label' }, 'Nom de l\'onglet'));
        var nameInput = DomUtils.el('input', { className: 'form-input', type: 'text', placeholder: 'Ex: Redo Logs' });
        nameGroup.appendChild(nameInput);
        form.appendChild(nameGroup);

        Modal.open({
            title: 'Nouvel onglet',
            content: form,
            buttons: [
                { label: 'Annuler', className: 'btn-ghost' },
                {
                    label: 'Creer', className: 'btn-primary',
                    action: function () {
                        var name = nameInput.value.trim();
                        if (!name) return;
                        var code = name.toUpperCase().replace(/[^A-Z0-9]/g, '_').substring(0, 50);
                        createTab(deskId, { tabCode: code, tabName: name });
                    }
                }
            ]
        });

        setTimeout(function () { nameInput.focus(); }, 100);
    }

    function createTab(deskId, opts) {
        ApiClient.post('/api/v1/desks/' + deskId + '/tabs', opts)
            .then(function (resp) {
                Toast.success('Onglet cree');
                // Reload desk to get updated tabs
                EventBus.emit('route:change', { deskId: deskId, tabId: resp.data.tabId });
                State.set('currentDeskId', null); // Force reload
                EventBus.emit('route:change', { deskId: deskId, tabId: resp.data.tabId });
            })
            .catch(function (err) {
                Toast.error('Erreur: ' + err.message);
            });
    }

    function deleteTab(tabId) {
        Modal.confirm('Supprimer cet onglet et tous ses widgets ?', function () {
            ApiClient.del('/api/v1/tabs/' + tabId)
                .then(function () {
                    Toast.success('Onglet supprime');
                    var deskId = State.get('currentDeskId');
                    State.set('currentDeskId', null);
                    EventBus.emit('route:change', { deskId: deskId });
                })
                .catch(function (err) {
                    Toast.error('Erreur: ' + err.message);
                });
        });
    }

    return { init: init, renderTabs: renderTabs, switchTab: switchTab };
})();
