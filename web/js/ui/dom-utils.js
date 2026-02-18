/* ============================================================================
   DomUtils - Safe DOM helper functions
   Never uses innerHTML with untrusted data
   ============================================================================ */
'use strict';

var DomUtils = (function () {

    /**
     * Create an element with attributes and optional text content
     */
    function el(tag, attrs, textContent) {
        var node = document.createElement(tag);
        if (attrs) {
            Object.keys(attrs).forEach(function (key) {
                if (key === 'className') {
                    node.className = attrs[key];
                } else if (key === 'dataset') {
                    Object.keys(attrs[key]).forEach(function (dk) {
                        node.dataset[dk] = attrs[key][dk];
                    });
                } else if (key.indexOf('on') === 0) {
                    node.addEventListener(key.substring(2).toLowerCase(), attrs[key]);
                } else {
                    node.setAttribute(key, attrs[key]);
                }
            });
        }
        if (textContent !== undefined && textContent !== null) {
            node.textContent = String(textContent);
        }
        return node;
    }

    /**
     * Append multiple children to a parent
     */
    function append(parent, children) {
        children.forEach(function (child) {
            if (child) parent.appendChild(child);
        });
        return parent;
    }

    /**
     * Clear all children of an element
     */
    function clear(node) {
        while (node.firstChild) node.removeChild(node.firstChild);
    }

    /**
     * Query shortcut
     */
    function qs(selector, parent) {
        return (parent || document).querySelector(selector);
    }

    function qsa(selector, parent) {
        return Array.from((parent || document).querySelectorAll(selector));
    }

    /**
     * Format a number with specified decimal places
     */
    function formatNumber(val, format) {
        if (val === null || val === undefined) return '';
        if (!format) return String(val);
        var decimals = (format.split('.')[1] || '').length;
        return Number(val).toFixed(decimals);
    }

    return { el: el, append: append, clear: clear, qs: qs, qsa: qsa, formatNumber: formatNumber };
})();
