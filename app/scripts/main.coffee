# Initialize foundation
$(document).foundation();

CodeMirror.fromTextArea document.getElementById("codemirror"),
    lineNumbers: true
    mode: "sparql"
    value: "sparql query"

CodeMirror.fromTextArea document.getElementById("codemirror_rdf"),
    lineNumbers: true
    mode: "n3"
    value: "rdf data"

CodeMirror.fromTextArea document.getElementById("codemirror_rif"),
    lineNumbers: true
    mode: "rif"
    value: "rif rules"

$("#errortoggle").click ->
  $("#error-list").toggle "slow", ->

  return



