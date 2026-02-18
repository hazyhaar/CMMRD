/* ============================================================================
   State - Application state manager
   ============================================================================ */
'use strict';

var State = (function () {
    var state = {
        user: null,
        desks: [],
        currentDeskId: null,
        currentDesk: null,
        currentTabId: null,
        catalog: [],
        widgetTimers: {}  // widgetId -> intervalId
    };

    function get(key) {
        return state[key];
    }

    function set(key, value) {
        state[key] = value;
        EventBus.emit('state:' + key, value);
    }

    function getAll() {
        return state;
    }

    return { get: get, set: set, getAll: getAll };
})();
