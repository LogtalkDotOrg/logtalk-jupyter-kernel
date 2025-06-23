(function() {
    // Load jupyter-api.js first
    const apiScript = document.createElement('script');
    apiScript.src = './jupyter-api.js';
    apiScript.onload = function() {
        // Then load logtalk_widgets.js
        const widgetsScript = document.createElement('script');
        widgetsScript.src = './logtalk_widgets.js';
        document.head.appendChild(widgetsScript);
    };
    document.head.appendChild(apiScript);
    console.log('Logtalk widget loader injected');
})();
