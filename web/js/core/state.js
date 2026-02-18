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
        if (!Object.prototype.hasOwnProperty.call(state, key)) return undefined;
        return state[key];
    }

    function set(key, value) {
        if (!Object.prototype.hasOwnProperty.call(state, key)) return;
        state[key] = value;
        EventBus.emit('state:' + key, value);
    }

    function getAll() {
        return state;
    }

    return { get: get, set: set, getAll: getAll };
})();
