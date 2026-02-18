/* ============================================================================
   WidgetFactory - Creates the right renderer for a widget type
   ============================================================================ */
'use strict';

var WidgetFactory = (function () {

    var renderers = {};

    function register(widgetType, renderer) {
        renderers[widgetType] = renderer;
    }

    /**
     * Render data into a widget body element
     * @param {HTMLElement} bodyEl - The .widget-body element
     * @param {Object} widget - Widget definition
     * @param {Array} rows - Data rows from TsvParser
     */
    function render(bodyEl, widget, rows) {
        var type = widget.widgetType || 'GRID';
        var renderer = renderers[type];
        if (!renderer) {
            bodyEl.textContent = 'Unknown widget type: ' + type;
            return;
        }
        renderer.render(bodyEl, widget, rows);
    }

    return { register: register, render: render };
})();
