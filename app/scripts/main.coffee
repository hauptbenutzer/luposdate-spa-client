'use strict'
# Attach App as global variable for debugging
@App =
    isMergeView: false

App.loadEditors = ->
    # Initialize editors
    App.cm = {}

    App.cm['sparql'] = CodeMirror.fromTextArea document.getElementById('codemirror'),
        mode: 'sparql'
        lineNumbers: true
        matchBrackets: true
        autoCloseBrackets: true

    App.loadQuery('sparql', 0)

    App.cm['rdf'] = CodeMirror.fromTextArea document.getElementById('codemirror_rdf'),
        lineNumbers: true
        mode: 'n3'
        matchBrackets: true
        autoCloseBrackets: true

    App.loadQuery('rdf', 0)


    App.cm['rif'] = CodeMirror.fromTextArea document.getElementById('codemirror_rif'),
        lineNumbers: true
        mode: 'rif'
        matchBrackets: true
        autoCloseBrackets: true

    App.loadQuery('rif', 0)

App.loadQuery = (lang, index) ->
    $.ajax(
        url: App.config.defaultData[lang][index]
        dataType: 'text'
    ).done (data) ->
        App.cm[lang].getDoc().setValue(data)

App.init = ->
    # Load xml converter
    App.x2js = new X2JS
        attributeArray: '_attributes'

    # Load configuration
    $.getJSON('scripts/config.json', (data) ->
        App.config = data
        App.play()
    )


App.bindEvents = ->
    # Send query to endpoint
    $('.query .evaluate').click ->
        # Copy changes to textarea
        for key of App.cm
            App.cm[key].save()

        endpoint = App.config.endpoints[0][ App.config['ontology'] ]
        data =
            query: $(this).parents('.query').find('.editor').val()

        if $.isArray endpoint
            method = endpoint[1]
            endpoint = endpoint[0]
            data[App.config['ontology']] = App.cm[App.config['ontology']].getValue()
            data['formats'] = ['xml']
            data = JSON.stringify(data)
        else
            method = 'GET'

        url = "#{App.config.endpoints[0].url}#{endpoint}"

        # Switch to results tab if needed
        if App.isMergeView
            $('.results-tab a').click()
        $.ajax
            url: url
            method: method
            data: data
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

    $('.query-select').change ->
        lang = $(this).data('lang')
        index = $(this).find('option:selected').index()
        App.loadQuery lang, index

    # Toggle fullscreen and other view options
    $('.fullscreen-toggle').click ->
        $('.main-section').toggleClass 'full'
        $(this).toggleClass 'active'

    # Merge/split tabs
    $('.right-side-toggle').click ->
        if $('.left-side .right-side-tab').length
            $('.right-side-tab-content').appendTo($('.right-side .tabs-content'))
            $('.right-side-tab').appendTo($('.right-side .tabs'))
            $('.right-side').show()
            # Auto-click first tab to refresh view
            $('.right-side .tabs a').get(0).click()
        else
            $('.right-side-tab-content').appendTo($('.left-side .tabs-content'))
            $('.right-side-tab').appendTo($('.left-side .tabs'))
            $('.right-side').hide()

        $(this).toggleClass 'active'
        $('.left-side').toggleClass 'medium-6 medium-12'
        $('.left-side .tabs a').get(0).click()
        App.isMergeView = not App.isMergeView

App.play = ->
    App.loadEditors()
    App.bindEvents()
    App.initConfigComponents()
    App.insertQueryPicker()

    # CodeMirror is display:none during loading screen so we need
    # a delayed refresh to have it display properly
    pleaseWait.finish()
    delay 1500, ->
        App.cm['sparql'].refresh()

App.insertQueryPicker = ->
    for lang of {'sparql', 'rdf', 'rif'}
        $("#query-select-#{lang}").html JST['query_picker']({options: App.config['defaultData'][lang]})

    $("#rule_radios input[value=#{App.config['defaultOntology']}]").click()



App.processResults = (data) ->
    # Valid data
    if 'XML' of data
        data = $.parseXML(data.XML)
    if $.isXMLDoc(data)
        document = App.x2js.xml2json(data)

    #try
    # Find and save defined prefixes
    # Generate random colors while we're at it
        namespaces = {}
        colors = {}
        for key, value of document.sparql._attributes
            if key.indexOf('xmlns:') isnt -1
                prefix = key.substr(key.indexOf('xmlns:') + 6)
                namespaces[prefix] = value
                colors[prefix] = randomColor({luminosity: 'dark'})

        # List all used variables
        variables = []
        for variable in document.sparql.head.variable
            variables.push variable._attributes.name

        # Replace prefixes
        # TODO: optimize?
        trie = new Trie()
        for result in document.sparql.results.result
            for bind in result.binding
                if bind.uri?
                    trie.add bind.uri
                    for key, pre of namespaces
                        if bind.uri.indexOf(pre) isnt -1
                            bind.uri = bind.uri.replace pre, ''
                            bind.prefix = key

                    base = App.baseName(bind.uri)
                    bind.uri = bind.uri.replace base, "<em>#{base}</em>"
                    bind.type = 'uri'

        $('#panel10').html(
            JST['results']({
                results: document.sparql.results.result
                prefixes: namespaces
                colors: colors
                variables: variables
            })
        )
    else
        if 'queryError' of data
            App.logError 'Sparql: ' + data.queryError.errorMessage, 'sparql', data.queryError.line
        else if 'rdfError' of data
            App.logError 'RDF: ' + data.rdfError.errorMessage, 'rdf', data.rdfError.line
        else if 'rifError' of data
            App.logError 'RIF: ' + data.rifError.errorMessage, 'rif', data.rifError.line
        else
            App.logError 'Endpoint answer was not valid.'


App.logError = (msg, editor, line) ->
    if editor
        line--
        App.cm[editor].setSelection {line: (line), ch: 0}, {line: (line), ch: 80 }
        $(".#{editor}-tab a").click()
    $('.error-log .list').append "<li>#{msg}</li>"
    $('.error-log button').next().addClass 'visible'

App.baseName = (str) ->
    base = new String(str).substring(str.lastIndexOf('/') + 1)
    base = base.substring(0, base.lastIndexOf('.'))  unless base.lastIndexOf('.') is -1
    base

App.configComponents =
    Radio: (watchedElementsSelector, callback) ->
        $(watchedElementsSelector).change ->
            callback($(watchedElementsSelector).filter(':checked').val())

App.initConfigComponents = ->
    App.configComponents.Radio '#rule_radios input', (val) ->
        App.config['ontology'] = val

delay = (ms, func) -> setTimeout func, ms

$(document).ready ->
    App.init()
