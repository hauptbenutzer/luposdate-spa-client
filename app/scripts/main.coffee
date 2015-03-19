'use strict'
# Attach App as global variable for debugging
@App =
    isMergeView: false

App.init = ->
    # Load xml converter
    App.x2js = new X2JS
        attributeArray: '_attributes'

    # Load configuration
    App.URIQuery = URI(document.location.href).query(true)

    $.getJSON('config/config.json').done (data) ->
        App.config = data
        if App.URIQuery.config
            $.getJSON(App.URIQuery.config).done (addData) ->
                App.config = $.extend(data, addData, {})
                App.play()
        else
            App.play()

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
    $statusElement = $(".load-query-status[data-lang=#{lang}]")
    $statusElement.show().html '<i class="fa fa-spinner"></i>'
    $.ajax(
        url: App.config.defaultData[lang][index]
        dataType: 'text'
    ).done (data) ->
        $statusElement.html('<i class="fa fa-check-circle"></i>').fadeOut(500)
        App.cm[lang].getDoc().setValue(data)

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
            error: (xhr, status, error) ->
                App.logError error


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
            # Set query parameters from config
            for key of App.config['queryParameters']
                data[key] = App.config['queryParameters'][key]
            # Nonstandard endpoints expect JSON-string as request body
            data = JSON.stringify(data)
        else
            method = 'GET'
            locator = endpoint.without

        url = "#{App.config.endpoints[0].url}#{locator}"

        # Switch to results tab if needed
        if App.isMergeView
            $('.results-tab a').click()

        $('#results-tab').html JST['spinner']()

        $.ajax
            url: url
            method: method
            data: data
            success: (data) ->
                App.processResults data, target
            error: (xhr, status, error) ->
                App.logError error

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

App.insertQueryPicker = ->
    for lang of {'sparql', 'rdf', 'rif'}
        $("#query-select-#{lang}").html JST['query_picker']({options: App.config['defaultData'][lang]})


App.preprocessResults = (data, namespaces, colors) ->
    resultSets = []

    xml = data

    if App.config.endpoints[App.config.selectedEndpoint].nonstandard
        # Process specific response types for nonstandard
        if 'triples' of data
            resultSets.push App.processTriples(data.triples, namespaces, colors)
        if 'predicates' of data
            resultSets.push App.processPredicates(data.predicates, namespaces, colors)
        if 'XML' of data
            # Sometimes the server will return an empty string
            if data.XML[0] == ''
                resultSets.push App.emptyResultSet()
            else
                # In nonstandard we get XML as string
                try
                    xml = $.parseXML(data.XML[0])
                catch error
                    # Like we care

    if $.isXMLDoc(xml)
        sparql = App.x2js.xml2json(xml)
        resultSets.push App.processSparql(sparql, namespaces, colors)

    # # Save plain response just in case
    # if 'Plain' of data
    #     doc.plain = data.Plain

    return resultSets

App.processResults = (data, lang) ->

    # Find and save defined prefixes
    # Generate random colors while we're at it
    namespaces = {}
    colors = {}
	# define some standard prefixes:
    namespaces['rdf'] = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#'
    namespaces['rdfs'] = 'http://www.w3.org/2000/01/rdf-schema#'
    namespaces['owl'] = 'http://www.w3.org/2002/07/owl#'
    namespaces['xsd'] = 'http://www.w3.org/2001/XMLSchema#'
	# get prefixes from user's query, data and rules
    if App.config.sendRDF
        $.extend(namespaces, App.parseRDFPrefixes(App.cm['rdf'].getValue()))
    if lang == 'rif'
        $.extend(namespaces, App.parseRIFPrefixes(App.cm['rif'].getValue()))
    if lang == 'sparql'
        $.extend(namespaces, App.parseSPARQLPrefixes(App.cm['sparql'].getValue()))
    for key, value of namespaces
        colors[key] = randomColor({luminosity: 'dark'})
    # Actually use them in the result
    # Check validity, preprocess if necessary
    resultSets = App.preprocessResults(data, namespaces, colors)

    if resultSets.length
        $('#results-tab').html(
            JST['results']({
                resultSets: resultSets
                prefixes: namespaces
                colors: colors
            })
        )
    else
        if 'queryError' of data
            App.logError 'Sparql: ' + data.queryError.errorMessage, lang, data.queryError.line
        else if 'rdfError' of data
            App.logError 'RDF: ' + data.rdfError.errorMessage, 'rdf', data.rdfError.line
        else if 'rifError' of data
            App.logError 'RIF: ' + data.rifError.errorMessage, 'rif', data.rifError.line
        else if 'error' of data
            App.logError data.error
        else
            if App.config.endpoints[App.config.selectedEndpoint].nonstandard
                App.logError 'Endpoint answer was not valid.'
            else
                App.logError data

App.emptyResultSet = ->
    name: 'Results'
    head: []
    results: []

App.processSparql = (doc, namespaces, colors) ->
    resultSet = App.emptyResultSet()

    if 'boolean' of doc.sparql
        resultSet.head.push 'Boolean'
        resultSet.results.push [doc.sparql.boolean]
    else if doc.sparql.head != ""
        unless $.isArray doc.sparql.head.variable
            doc.sparql.head.variable = [doc.sparql.head.variable]
        i = 0
        varorder = []
        for variable in doc.sparql.head.variable
            resultSet.head.push variable._attributes.name
            varorder[variable._attributes.name] = i
            i++

        unless $.isArray doc.sparql.results.result
            doc.sparql.results.result = [doc.sparql.results.result]
        for result in doc.sparql.results.result
            presult = []
            unless $.isArray result.binding
                result.binding = [result.binding]
            varbinding = []
            for bind in result.binding
                value = ''
                if 'uri' of bind
                    value = App.replacePrefixes(bind.uri, namespaces, colors)
                else if 'literal' of bind
                    value = "\"" + _.escape(bind.literal) + "\""
                    if bind.literal._attributes and 'datatype' of bind.literal._attributes
                        value += "^^" + App.replacePrefixes(bind.literal._attributes.datatype, namespaces, colors)
                    if bind.literal._attributes and 'xml:lang' of bind.literal._attributes
                        value += "@" + bind.literal._attributes['xml:lang']
                else if 'bnode' of bind
                    value = "_:" + bind.bnode
                varbinding[bind._attributes.name] = value
            for varname,index of varorder
                if varbinding[varname]
                    presult[index] = varbinding[varname]
                else presult[index] = ''
            resultSet.results.push presult

    return resultSet

App.processTriples = (data, namespaces, colors) ->
    varnames = ['subject', 'predicate', 'object']
    resultSet =
        name: 'Triples'
        head: varnames
        results: []

    for triple in data
        result = []
        for variable in varnames
            App.processLiteral(triple[variable], namespaces, colors, result)
        resultSet.results.push result

    return resultSet

App.processPredicates = (preds, namespaces, colors) ->
    resultSet =
        name: 'Predicates'
        head: []
        results: []

    resultSet.head.push 'Predicate Name'

    if preds[0].parameters
        for v,k in preds[0].parameters
            resultSet.head.push "Arg. #{k+1}"

    for pred in preds
        result = []
        result.push App.replacePrefixes(pred.predicateName.value, namespaces, colors)
        if pred.parameters
            for para in pred.parameters
                App.processLiteral(para, namespaces, colors, result)
        resultSet.results.push result

    return resultSet

App.processLiteral = (para, namespaces, colors, result) ->
    para.value = _.escape(para.value)
    if para.datatype
        prefixeddatatype = App.replacePrefixes(para.datatype, namespaces, colors)
        result.push "\"#{para.value}\"^^#{prefixeddatatype}"
    else if para.type and para.type=='uri'
        result.push App.replacePrefixes(para.value, namespaces, colors)
    else if para.type and para.type=='bnode'
        result.push "_:#{para.value}"
    else
        r = "\"#{para.value}\""
        if para['xml:lang']
            r = r + '@' + para['xml:lang']
        result.push r

App.replacePrefixes = (str, namespaces, colors) ->
    str = _.escape(str)
    for key, prefix of namespaces
        if str.indexOf(prefix) isnt -1
            return str.replace prefix, JST['results/prefix']({prefix: key, color: colors[key]})

    base = App.baseName(str)
    return "&lt;"+str.replace(base, "<em>#{base}</em>")+"&gt;"

App.parseRDFPrefixes = (data) ->
    prefixes = {}
    # first detect base
    reg = /@prefix\s+:\s*<([^>]+)>\s*\./g
    while(m = reg.exec(data))
        prefixes[''] = m[1]
    # now detect prefixes
    reg = /@prefix\s+([A-z0-9-]+):\s*<([^>]+)>\s*\./g
    while(m = reg.exec(data))
        prefixes[m[1]] = m[2]
    prefixes

App.parseSPARQLPrefixes = (data) ->
    prefixes = {}
    # first detect base
    reg = /base\s+<([^>]+)>/ig
    while(m = reg.exec(data))
        prefixes[''] = m[1]
    # now detect prefixes
    reg = /prefix\s+([A-z0-9-]+)\s*:\s*<([^>]+)>/ig
    while(m = reg.exec(data))
        prefixes[m[1]] = m[2]
    prefixes

App.parseRIFPrefixes = (data) ->
    prefixes = {}
    # first detect base
    reg = /base\(\s*<([^>]+)>\s*\)/ig
    while(m = reg.exec(data))
        prefixes[''] = m[1]
    # now detect prefixes
    reg = /prefix\(([^\s]+)\s+<([^>]+)>\s*\)/ig
    while(m = reg.exec(data))
        prefixes[m[1]] = m[2]
    prefixes

App.logError = (msg, editor, line) ->
    if editor and line
        line--
        App.cm[editor].setSelection {line: (line), ch: 0}, {line: (line), ch: 80 }
        $(".#{editor}-tab a").click()
    $('#results-tab').html JST['results/error'](msg: msg)

App.baseName = (str) ->
    base = new String(str).substring(str.lastIndexOf('/') + 1)
    base = base.substring(0, base.lastIndexOf('.'))  unless base.lastIndexOf('.') is -1
    base

App.configComponents =
    Radio: (watchedElementsSelector, defaultVal, callback) ->
        $(watchedElementsSelector).change ->
            callback($(watchedElementsSelector).filter(':checked').val())
            return true
        if defaultVal
            $(watchedElementsSelector).filter("[value=#{defaultVal}]").click()
    Check: (watchedElementSelector, defaultVal, callback) ->
        $(watchedElementSelector).click ->
            callback($(watchedElementSelector).is(':checked'))
            return true
        if defaultVal
            $(watchedElementSelector).click()

App.initConfigComponents = ->
    for tab in App.config.hiddenTabs
        $("##{tab}-tab").hide().removeClass 'active'
        $("a[href=##{tab}-tab]").parent("dd").hide().removeClass 'active'
    # Find first visible tab and focus it
    # delay is due to foundation initialization
    # TODO: use promise instead
    delay 1000, ->
        $('.tabs').each ->
            $(this).find('dd:visible a').first().click()

    for tab in App.config.readOnlyTabs
        $("##{tab}-tab, a[href=##{tab}-tab]").addClass 'read-only'
        $("##{tab}-tab").find('input, textarea, select').attr('readonly', true)

    App.configComponents.Radio '#rule_radios input', App.config['queryParameters']['inference'], (val) ->
        App.config['queryParameters']['inference'] = val
    App.configComponents.Check '#send_rdf', App.config.sendRDF, (send) ->
        App.config.sendRDF = send

delay = (ms, func) -> setTimeout func, ms

$(document).ready ->
    App.init()
