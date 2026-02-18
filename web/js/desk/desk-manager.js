/* ============================================================================
   DeskManager - Desk CRUD and loading
   ============================================================================ */
'use strict';

var DeskManager = (function () {

    function init() {
        EventBus.on('route:change', onRouteChange);
        loadDeskList();
    }

    function loadDeskList() {
        ApiClient.get('/api/v1/desks/mine')
            .then(function (resp) {
                var desks = resp.data || [];
                State.set('desks', desks);
                renderDeskList(desks);

                // Navigate to first desk if no route set
                var route = Router.parseHash();
                if (!route.deskId && desks.length > 0) {
                    Router.navigate(desks[0].deskId);
                }
            })
            .catch(function (err) {
                Toast.error('Erreur chargement desks: ' + err.message);
            });
    }

    function renderDeskList(desks) {
        var list = DomUtils.qs('#desk-list');
        DomUtils.clear(list);

        desks.forEach(function (desk) {
            var li = DomUtils.el('li', {
                dataset: { deskId: desk.deskId },
                onClick: function () { Router.navigate(desk.deskId); }
            });

            li.appendChild(DomUtils.el('span', null, desk.deskName));

            if (desk.deskType === 'CONTRACTOR') {
                li.appendChild(DomUtils.el('span', { className: 'desk-type-badge badge-contractor' }, 'P'));
            } else if (desk.deskType === 'SHARED') {
                li.appendChild(DomUtils.el('span', { className: 'desk-type-badge badge-shared' }, 'S'));
            }

            list.appendChild(li);
        });
    }

    function onRouteChange(route) {
        if (!route.deskId) return;

        // Highlight active desk in sidebar
        DomUtils.qsa('#desk-list li').forEach(function (li) {
            li.classList.toggle('active', parseInt(li.dataset.deskId) === route.deskId);
        });

        // Load desk if different from current
        if (State.get('currentDeskId') !== route.deskId) {
            loadDesk(route.deskId, route.tabId);
        } else if (route.tabId) {
            TabManager.switchTab(route.tabId);
        }
    }

    function loadDesk(deskId, tabId) {
        DataFetcher.stopAll();

        ApiClient.get('/api/v1/desks/' + deskId)
            .then(function (resp) {
                var desk = resp.data;
                State.set('currentDeskId', deskId);
                State.set('currentDesk', desk);

                DomUtils.qs('#desk-name').textContent = desk.deskName;

                TabManager.renderTabs(desk.tabs || []);

                // Switch to requested tab or first tab
                var targetTab = tabId;
                if (!targetTab && desk.tabs && desk.tabs.length > 0) {
                    targetTab = desk.tabs[0].tabId;
                }
                if (targetTab) {
                    TabManager.switchTab(targetTab);
                }
            })
            .catch(function (err) {
                Toast.error('Erreur chargement desk: ' + err.message);
            });
    }

    function createDesk(opts) {
        return ApiClient.post('/api/v1/desks', opts)
            .then(function (resp) {
                Toast.success('Desk cree');
                loadDeskList();
                return resp.data;
            });
    }

    function deleteDesk(deskId) {
        return ApiClient.del('/api/v1/desks/' + deskId)
            .then(function () {
                Toast.success('Desk supprime');
                loadDeskList();
            });
    }

    return { init: init, loadDeskList: loadDeskList, createDesk: createDesk, deleteDesk: deleteDesk };
})();
