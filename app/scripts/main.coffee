require.config baseUrl: "/bower_components"

require [
    "codemirror/lib/codemirror"
    "codemirror/mode/javascript/javascript"
], (CodeMirror) ->
    CodeMirror.fromTextArea document.getElementById("codemirror"),
        lineNumbers: true
        mode: "javascript"


