/* ============================================================================
   Modal - Simple modal dialog
   ============================================================================ */
'use strict';

var Modal = (function () {

    function open(opts) {
        var overlay = DomUtils.el('div', { className: 'modal-overlay' });
        var box = DomUtils.el('div', { className: 'modal-box' });

        // Header
        var header = DomUtils.el('div', { className: 'modal-header' });
        header.appendChild(DomUtils.el('h3', null, opts.title || ''));
        var closeBtn = DomUtils.el('button', { className: 'btn btn-ghost', onClick: close }, 'X');
        header.appendChild(closeBtn);
        box.appendChild(header);

        // Body
        var body = DomUtils.el('div', { className: 'modal-body' });
        if (opts.content) {
            if (typeof opts.content === 'string') {
                body.textContent = opts.content;
            } else {
                body.appendChild(opts.content);
            }
        }
        box.appendChild(body);

        // Footer
        if (opts.buttons) {
            var footer = DomUtils.el('div', { className: 'modal-footer' });
            opts.buttons.forEach(function (btn) {
                var button = DomUtils.el('button', {
                    className: 'btn ' + (btn.className || ''),
                    onClick: function () {
                        if (btn.action) btn.action();
                        close();
                    }
                }, btn.label);
                footer.appendChild(button);
            });
            box.appendChild(footer);
        }

        overlay.appendChild(box);
        overlay.addEventListener('click', function (e) {
            if (e.target === overlay) close();
        });

        document.body.appendChild(overlay);

        function close() {
            overlay.remove();
        }

        return { close: close, body: body };
    }

    function confirm(message, onConfirm) {
        open({
            title: 'Confirmation',
            content: message,
            buttons: [
                { label: 'Annuler', className: 'btn-ghost' },
                { label: 'Confirmer', className: 'btn-primary', action: onConfirm }
            ]
        });
    }

    return { open: open, confirm: confirm };
})();
