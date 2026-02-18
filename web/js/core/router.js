/* ============================================================================
   Router - Hash-based SPA router
   Routes: #/desk/:deskId  or  #/desk/:deskId/tab/:tabId
   ============================================================================ */
'use strict';

var Router = (function () {

    function parseHash() {
        var hash = window.location.hash || '#/';
        var parts = hash.replace('#/', '').split('/');
        var route = { deskId: null, tabId: null };

        // #/desk/42
        // #/desk/42/tab/7
        if (parts[0] === 'desk' && parts[1]) {
            route.deskId = parseInt(parts[1], 10);
        }
        if (parts[2] === 'tab' && parts[3]) {
            route.tabId = parseInt(parts[3], 10);
        }

        return route;
    }

    function navigate(deskId, tabId) {
        var hash = '#/desk/' + deskId;
        if (tabId) hash += '/tab/' + tabId;
        window.location.hash = hash;
    }

    function init() {
        window.addEventListener('hashchange', function () {
            EventBus.emit('route:change', parseHash());
        });

        // Trigger initial route
        var initial = parseHash();
        if (initial.deskId) {
            EventBus.emit('route:change', initial);
        }
    }

    return { init: init, navigate: navigate, parseHash: parseHash };
})();
