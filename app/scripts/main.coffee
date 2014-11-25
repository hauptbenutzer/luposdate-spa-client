require.config baseUrl: "/"

require [
    "bower_components/codemirror/lib/codemirror"
    "scripts/codemirror-modes/sparql/sparql.js"
], (CodeMirror) ->
    CodeMirror.fromTextArea document.getElementById("codemirror"),
        lineNumbers: true
        mode: "sparql"


