/* ============================================================================
   DataFetcher - Loads data for widgets via ORDS, parses TSV
   Manages auto-refresh timers with stagger
   ============================================================================ */
'use strict';

var DataFetcher = (function () {

    // Track stagger timeouts separately to cancel them before they fire
    var pendingTimeouts = {};

    /**
     * Fetch data for a widget
     * @param {Object} widget - Widget definition from desk JSON
     * @param {number} deskId - Current desk ID (for contractor filtering)
     * @returns {Promise<Array>} Parsed rows
     */
    function fetchWidgetData(widget, deskId) {
        var dsCode = widget.dsCode;
        if (!dsCode) return Promise.resolve([]);

        var path = '/api/v1/data/' + encodeURIComponent(dsCode);
        if (deskId) path += '?desk_id=' + encodeURIComponent(deskId);

        var columnsDef = null;
        try {
            columnsDef = typeof widget.columnsDef === 'string'
                ? JSON.parse(widget.columnsDef)
                : widget.columnsDef;
        } catch (e) { /* ignore parse error */ }

        return ApiClient.get(path, { abortKey: 'widget-' + widget.widgetId })
            .then(function (resp) {
                if (resp.type === 'tsv') {
                    return TsvParser.parse(resp.data, columnsDef);
                }
                if (resp.type === 'json') {
                    return Array.isArray(resp.data) ? resp.data : [resp.data];
                }
                return [];
            });
    }

    /**
     * Start auto-refresh for a widget
     * Adds random stagger 0-2s to avoid burst
     */
    function startRefresh(widgetId, widget, deskId, callback) {
        stopRefresh(widgetId);

        var sec = widget.refreshSec || 0;
        if (sec <= 0) return;

        var stagger = Math.random() * 2000;

        // Track the stagger timeout so stopRefresh/stopAll can cancel it
        var timeoutId = setTimeout(function () {
            delete pendingTimeouts[widgetId];

            var intervalId = setInterval(function () {
                fetchWidgetData(widget, deskId)
                    .then(function (rows) { callback(rows); })
                    .catch(function () { /* silent refresh failure */ });
            }, sec * 1000);

            var timers = State.get('widgetTimers');
            timers[widgetId] = intervalId;
        }, stagger);

        pendingTimeouts[widgetId] = timeoutId;
    }

    /**
     * Stop auto-refresh for a widget
     */
    function stopRefresh(widgetId) {
        // Cancel pending stagger timeout
        if (pendingTimeouts[widgetId]) {
            clearTimeout(pendingTimeouts[widgetId]);
            delete pendingTimeouts[widgetId];
        }

        var timers = State.get('widgetTimers');
        if (timers[widgetId]) {
            clearInterval(timers[widgetId]);
            delete timers[widgetId];
        }
    }

    /**
     * Stop all refresh timers (on desk/tab change)
     */
    function stopAll() {
        // Cancel all pending stagger timeouts
        Object.keys(pendingTimeouts).forEach(function (id) {
            clearTimeout(pendingTimeouts[id]);
        });
        pendingTimeouts = {};

        var timers = State.get('widgetTimers');
        Object.keys(timers).forEach(function (id) {
            clearInterval(timers[id]);
        });
        State.set('widgetTimers', {});
    }

    return {
        fetchWidgetData: fetchWidgetData,
        startRefresh: startRefresh,
        stopRefresh: stopRefresh,
        stopAll: stopAll
    };
})();
