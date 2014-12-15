# Attach App as global variable for debugging
@App = {}

# Initialize foundation
#$(document).foundation();

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

    # Load xml converter
    App.x2js = new X2JS()

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
            if content.find('.CodeMirror').length
                content.find('.CodeMirror')[0].CodeMirror.refresh()

    $('.error-log button').click ->
        $(this).next().toggleClass 'visible'
    $('.tabs .move').click ->
        currentTabs = $(this).parents('.tabs')
        currentContainer = $(this).parents('.tabs-container')
        $(this).parents('dd').appendTo($('.tabs').not(currentTabs))
        $($(this).siblings('a').attr('href')).appendTo($('.tabs-container').not(currentContainer).find('.tabs-content'))

App.play = ->
    App.bindEvents()
    console.log "ready"

App.processResults = (data) ->
    # Valid data
    if $.isXMLDoc(data)
        results = App.x2js.xml2json($(data).find('results').get(0))
        $('#panel10').append JST['results']({results: results.result})
    else
        $('.error-log .list').append "<li>#{data}</li>"

$(document).ready ->
    App.init()
