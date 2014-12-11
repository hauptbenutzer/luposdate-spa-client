# Initialize foundation
$(document).foundation(); 

CodeMirror.fromTextArea document.getElementById("codemirror"),
    lineNumbers: true
    mode: "rif"

$("#errortoggle").click ->
  $("#error-list").toggle "slow", ->

  return



