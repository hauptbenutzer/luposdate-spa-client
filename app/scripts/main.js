require.config({
  baseUrl: "/bower_components"
});

require(["codemirror/lib/codemirror", "codemirror/mode/javascript/javascript"], function(CodeMirror) {
  return CodeMirror.fromTextArea(document.getElementById("codemirror"), {
    lineNumbers: true,
    mode: "javascript"
  });
});
