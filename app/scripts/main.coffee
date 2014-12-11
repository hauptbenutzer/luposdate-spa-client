# Attach App as global variable for debugging
@App = {}

# Initialize foundation
#$(document).foundation();

$("#errortoggle").click ->
    $("#error-list").toggle "slow", ->

    return

App.init = ->
    # Initialize editors
    App.cm = {}
    App.cm['sparql'] = CodeMirror.fromTextArea document.getElementById("codemirror"),
        lineNumbers: true
        mode: "sparql"
        value: "sparql query"

    App.cm['rdf'] = CodeMirror.fromTextArea document.getElementById("codemirror_rdf"),
        lineNumbers: true
        mode: "n3"
        value: "rdf data"


    App.cm['rif'] = CodeMirror.fromTextArea document.getElementById("codemirror_rif"),
        lineNumbers: true
        mode: "rif"
        value: "rif rules"

    # Load configuration
    $.getJSON('scripts/config.json', (data) ->
        App.config = data
        App.play()
    )

App.bindEvents = ->
    # Send query to endpoint
    $('.query .evaluate').click ->
        # Copy changes to textarea
        App.cm['sparql'].save()
        url = "#{App.config.endpoints[0].url}sparql"
        query = $(this).parents('.query').find('.editor').val()
        $.ajax
            url: url
            method: 'GET'
            data: {query: query}
            success: (data) ->
                App.processResults data

    # Reload editor when changing tabs
    $(document).foundation
        tab:
          callback: (tab) ->
            content = $(tab.children('a').attr('href'))
            content.find('.CodeMirror')[0].CodeMirror.refresh()

App.play = ->
    App.bindEvents()
    console.log "ready"

App.processResults = (data, json) ->
    if json
        try
            data = $.parseJSON(data)
        catch error
            console.log error
        finally
            return data
    else
        $data = $(data)
        $data.find('uri').each ->
            $('#panel10').append "<p>#{$(this).text()}</p>" # TODO: This is just proof of concept


$(document).ready ->
    App.init()
