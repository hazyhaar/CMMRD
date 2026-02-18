/* ============================================================================
   TsvParser - Parse TSV (tab-separated values) responses
   Header line = column names, data lines follow
   \N = null
   ============================================================================ */
'use strict';

var TsvParser = (function () {

    /**
     * Parse a TSV string into an array of objects.
     * @param {string} tsv - Raw TSV text
     * @param {Array} columnsDef - Optional column definitions from catalog
     *                             [{name, type, ...}] for type casting
     * @returns {Array} Array of row objects
     */
    function parse(tsv, columnsDef) {
        if (!tsv || typeof tsv !== 'string') return [];

        var lines = tsv.split('\n');
        if (lines.length < 1) return [];

        // Header
        var headers = lines[0].split('\t');
        var typeMap = {};
        if (columnsDef) {
            columnsDef.forEach(function (col) {
                typeMap[col.name] = col.type;
            });
        }

        var rows = [];
        for (var i = 1; i < lines.length; i++) {
            var line = lines[i];
            if (!line || line.length === 0) continue;

            var values = line.split('\t');
            var row = {};
            for (var j = 0; j < headers.length; j++) {
                var raw = j < values.length ? values[j] : '';
                var key = headers[j];

                if (raw === '\\N') {
                    row[key] = null;
                } else {
                    row[key] = castValue(raw, typeMap[key]);
                }
            }
            rows.push(row);
        }
        return rows;
    }

    function castValue(raw, type) {
        if (!type) return raw;
        switch (type) {
            case 'number':
                var n = parseFloat(raw);
                return isNaN(n) ? raw : n;
            default:
                return raw;
        }
    }

    /**
     * Get column headers from TSV string
     */
    function getHeaders(tsv) {
        if (!tsv) return [];
        var firstLine = tsv.split('\n')[0];
        return firstLine ? firstLine.split('\t') : [];
    }

    return { parse: parse, getHeaders: getHeaders };
})();
