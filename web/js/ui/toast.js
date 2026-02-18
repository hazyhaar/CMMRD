/* ============================================================================
   Toast - Notification toasts
   ============================================================================ */
'use strict';

var Toast = (function () {
    var container;

    function init() {
        container = DomUtils.qs('#toast-container');
    }

    function show(message, type, durationMs) {
        if (!container) init();
        type = type || 'info';
        durationMs = durationMs || 3000;

        var toast = DomUtils.el('div', { className: 'toast toast-' + type }, message);
        container.appendChild(toast);

        setTimeout(function () {
            toast.style.opacity = '0';
            toast.style.transition = 'opacity 0.3s';
            setTimeout(function () { toast.remove(); }, 300);
        }, durationMs);
    }

    function success(msg) { show(msg, 'success'); }
    function error(msg)   { show(msg, 'error', 5000); }
    function info(msg)    { show(msg, 'info'); }

    return { show: show, success: success, error: error, info: info };
})();
