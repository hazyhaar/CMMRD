/* ============================================================================
   EventBus - Pub/Sub for decoupled component communication
   ============================================================================ */
'use strict';

var EventBus = (function () {
    var listeners = {};

    function on(event, fn) {
        if (!listeners[event]) listeners[event] = [];
        listeners[event].push(fn);
    }

    function off(event, fn) {
        if (!listeners[event]) return;
        listeners[event] = listeners[event].filter(function (f) { return f !== fn; });
    }

    function emit(event, data) {
        if (!listeners[event]) return;
        listeners[event].forEach(function (fn) {
            try { fn(data); } catch (e) { console.error('EventBus error on ' + event, e); }
        });
    }

    return { on: on, off: off, emit: emit };
})();
