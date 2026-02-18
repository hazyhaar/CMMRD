/* ============================================================================
   ApiClient - HTTP layer for ORDS REST calls
   Handles auth token, base URL, error handling
   ============================================================================ */
'use strict';

var ApiClient = (function () {
    var baseUrl = '';
    var token = null;
    var abortControllers = {};

    function configure(opts) {
        baseUrl = opts.baseUrl || '';
        token = opts.token || null;
    }

    function setToken(t) {
        token = t;
    }

    function headers(contentType) {
        var h = {};
        if (token) h['Authorization'] = 'Bearer ' + token;
        if (contentType) h['Content-Type'] = contentType;
        return h;
    }

    function abortPrevious(key) {
        if (key && abortControllers[key]) {
            abortControllers[key].abort();
        }
        if (key) {
            abortControllers[key] = new AbortController();
            return abortControllers[key].signal;
        }
        return undefined;
    }

    function request(method, path, body, opts) {
        opts = opts || {};
        var signal = abortPrevious(opts.abortKey);
        var url = baseUrl + path;
        var fetchOpts = {
            method: method,
            headers: headers(body ? 'application/json' : undefined),
            signal: signal
        };
        if (body) fetchOpts.body = JSON.stringify(body);

        return fetch(url, fetchOpts).then(function (resp) {
            // Handle 401 - redirect to login
            if (resp.status === 401) {
                var authErr = new Error('Non authentifie');
                authErr.status = 401;
                EventBus.emit('auth:unauthorized');
                throw authErr;
            }

            if (!resp.ok) {
                return resp.text().then(function (text) {
                    var err;
                    try { err = JSON.parse(text); } catch (e) { err = { error: { message: text } }; }
                    var error = new Error(err.error ? err.error.message : 'HTTP ' + resp.status);
                    error.status = resp.status;
                    error.body = err;
                    throw error;
                });
            }
            var ct = resp.headers.get('content-type') || '';
            if (ct.indexOf('tab-separated-values') >= 0) {
                return resp.text().then(function (text) {
                    return { type: 'tsv', data: text };
                });
            }
            if (ct.indexOf('json') >= 0) {
                return resp.json().then(function (json) {
                    return { type: 'json', data: json };
                });
            }
            return resp.text().then(function (text) {
                return { type: 'text', data: text };
            });
        }).catch(function (err) {
            // Silently swallow AbortError (request was intentionally cancelled)
            if (err.name === 'AbortError') {
                return Promise.reject({ message: '', aborted: true, silent: true });
            }
            throw err;
        });
    }

    function get(path, opts) { return request('GET', path, null, opts); }
    function post(path, body, opts) { return request('POST', path, body, opts); }
    function put(path, body, opts) { return request('PUT', path, body, opts); }
    function del(path, opts) { return request('DELETE', path, null, opts); }

    return {
        configure: configure,
        setToken: setToken,
        get: get,
        post: post,
        put: put,
        del: del
    };
})();
