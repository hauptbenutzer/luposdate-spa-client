# Attach App as global variable for debugging
@App = {}

# Initialize foundation
$(document).foundation();

App.cmSparql = CodeMirror.fromTextArea document.getElementById("codemirror"),
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

App.init = -> 
    # Load configuration
    $.getJSON('scripts/config.json', (data) -> 
        App.config = data 
        App.play()
    )

App.bindEvents = -> 
    $('.query .evaluate').click -> 
        # Copy changes to textarea
        App.cmSparql.save()
        url = "#{App.config.endpoints[0].url}sparql"
        query = $(this).parents('.query').find('.editor').val()
        $.ajax 
            url: url
            method: 'GET' 
            data: {query: query}
            success: (data) -> 
                console.log data

App.play = -> 
    App.bindEvents()
    console.log "ready"

$(document).ready ->
    App.init()
