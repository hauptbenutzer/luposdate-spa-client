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
    $statusElement = $(".load-query-status[data-lang=#{lang}")
    $statusElement.show().html '<i class="fa fa-spinner"></i>'
    $.ajax(
        url: App.config.defaultData[lang][index]
        dataType: 'text'
    ).done (data) ->
        $statusElement.html('<i class="fa fa-check-circle"></i>').fadeOut(500)
        App.cm[lang].getDoc().setValue(data)

App.init = ->
    # Load xml converter
    App.x2js = new X2JS
        attributeArray: '_attributes'

    # Load configuration
    App.URIQuery = URI(document.location.href).query(true)

    $.getJSON('scripts/config.json').done (data) ->
        App.config = data
        if App.URIQuery.config 
            $.getJSON(App.URIQuery.config).done (addData) ->
                App.config = $.extend(data, addData, {})
                App.play()
        else 
            App.play()

App.bindEvents = ->
    $('.query .get-graph').click ->
        request = {
            query: "SELECT * WHERE { ?s ?p ?o. } LIMIT 10"
        }
        $.ajax
            url: 'http://localhost:8080/nonstandard/sparql/info'
            method: 'POST'
            data: JSON.stringify(request)
            success: (data) ->
                createVerticalTree(data)


    # Send query to endpoint
    $('.query .evaluate').click ->
        # Copy changes to textarea
        for key of App.cm
            App.cm[key].save()

        target = $(this).data 'target'
        endpoint = App.config.endpoints[0]
        data =
            query: $(this).parents('.query').find('.editor').val()

        if endpoint.nonstandard
            folder = endpoint[target]
            if App.config['sendRDF']
                data['rdf'] = App.cm['rdf'].getValue()
            else
                data['rdf'] = ''

            method = folder[1]
            locator = folder[0]
            data['formats'] = ['xml', 'plain']
            # Nonstandard endpoints expect JSON-string as request body
            data = JSON.stringify(data)
        else
            method = 'GET'
            locator = endpoint.without

        url = "#{App.config.endpoints[0].url}#{locator}"

        # Switch to results tab if needed
        if App.isMergeView
            $('.results-tab a').click()

        $('#panel10').html JST['spinner']()

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

    $("#rule_radios input[value=#{App.config['defaultInference']}]").click()

App.preprocessResults = (data) ->
     # If this is nonstandard then we're getting JSON
    if 'triples' of data 
        doc = App.processTriples(data.triples)
    else if 'XML' of data
        data = $.parseXML(data.XML[0])
        # Sometimes will return empty XML envelope 
        if not data?
            doc = {sparql: {results: ""}}
    if doc? 
        return doc
    else if $.isXMLDoc(data)
        return App.x2js.xml2json(data)
    else 
        return false

App.processResults = (data) ->
    # Check validity, preprocess if necessary 
    doc = App.preprocessResults(data)
    if doc and doc.sparql.results != ""
        # Find and save defined prefixes
        # Generate random colors while we're at it
        namespaces = {}
        colors = {}
        for key, value of doc.sparql._attributes
            if key.indexOf('xmlns:') isnt -1
                prefix = key.substr(key.indexOf('xmlns:') + 6)
                namespaces[prefix] = value

        namespaces = $.extend(App.parseRDFPrefixes(App.cm['rdf'].getValue()), namespaces)

        for key, value of namespaces
            colors[key] = randomColor({luminosity: 'dark'})

        if 'boolean' of doc.sparql  
            $('#panel10').html(JST['results/boolean'](boolean: doc.sparql.boolean))
        else 
            # List all used variables
            variables = []
            unless $.isArray doc.sparql.head.variable 
                doc.sparql.head.variable = [doc.sparql.head.variable]
            for variable in doc.sparql.head.variable
                variables.push variable._attributes.name

            # Replace prefixes
            # TODO: optimize?
            for result in doc.sparql.results.result
                unless $.isArray result.binding
                    result.binding = [result.binding]
                for bind in result.binding
                    App.replacePrefixes bind, namespaces


            $('#panel10').html(
                JST['results']({
                    results: doc.sparql.results.result
                    prefixes: namespaces
                    colors: colors
                    variables: variables
                })
            )
    else if doc.sparql.results == ""
        $('#panel10').html JST['results/none']()
    else
        if 'queryError' of data
            App.logError 'Sparql: ' + data.queryError.errorMessage, 'sparql', data.queryError.line
        else if 'rdfError' of data
            App.logError 'RDF: ' + data.rdfError.errorMessage, 'rdf', data.rdfError.line
        else if 'rifError' of data
            App.logError 'RIF: ' + data.rifError.errorMessage, 'rif', data.rifError.line
        else
            App.logError 'Endpoint answer was not valid.'

App.processTriples = (data) -> 
    varnames = ['subject', 'predicate', 'object']
    doc = 
        sparql: 
            head: {variable: [] }
            results: {result: [] }

    for v in varnames
        doc.sparql.head.variable.push 
            _attributes: {name: v}

    for triple in data 
        result = {binding: []}
        for variable in varnames
            if triple[variable].type == "uri"
                result.binding.push {uri: triple[variable].value}
            else 
                result.binding.push {literal: triple[variable].value}
        doc.sparql.results.result.push result   

    return doc


App.replacePrefixes = (bind, namespaces) ->
    if bind.uri?
        for key, pre of namespaces
            if bind.uri.indexOf(pre) isnt -1
                bind.uri = bind.uri.replace pre, ''
                bind.prefix = key

        base = App.baseName(bind.uri)
        bind.uri = bind.uri.replace base, "<em>#{base}</em>"
        bind.type = 'uri'

App.parseRDFPrefixes = (data) ->
    reg = /@prefix\s+([A-z0-9-]+):\s*<([^>]+)>\s+\./g
    prefixes = {}
    while(m = reg.exec(data))
        prefixes[m[1]] = m[2]
    prefixes

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
    Check: (watchedElementSelector, defaultVal, callback) ->
        $(watchedElementSelector).click ->
            callback($(watchedElementSelector).is(':checked'))
            return true
        if defaultVal
            $(watchedElementSelector).click()

App.initConfigComponents = ->
    App.configComponents.Radio '#rule_radios input', (val) ->
        App.config['inference'] = val
    App.configComponents.Check '#send_rdf', App.config['defaultSendRDF'], (send) ->
        App.config['sendRDF'] = send

delay = (ms, func) -> setTimeout func, ms

$(document).ready ->
    App.init()
