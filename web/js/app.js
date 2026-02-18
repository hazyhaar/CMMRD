/* ============================================================================
   App - Main entry point
   Initializes all modules and starts the application
   ============================================================================ */
'use strict';

(function () {

    // Configuration - adjust baseUrl to your ORDS instance
    var CONFIG = {
        baseUrl: '/ords/cockpit',  // ORDS base path for COCKPIT schema
        appName: 'DBA Cockpit'
    };

    function init() {
        // Configure API client
        ApiClient.configure({ baseUrl: CONFIG.baseUrl });

        // Initialize UI modules
        CatalogPanel.init();
        TabManager.init();
        WidgetManager.init();

        // Initialize router (will trigger first route)
        Router.init();

        // Load desk list (triggers desk loading chain)
        DeskManager.init();

        // Show user info
        loadUserInfo();

        console.log(CONFIG.appName + ' initialized');
    }

    function loadUserInfo() {
        ApiClient.get('/api/v1/auth/me')
            .then(function (resp) {
                var user = resp.data;
                State.set('user', user);
                var badge = DomUtils.qs('#user-info');
                badge.textContent = user.displayName || user.username || '';
            })
            .catch(function () {
                DomUtils.qs('#user-info').textContent = 'Non connecte';
            });
    }

    // Start when DOM is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }

})();
