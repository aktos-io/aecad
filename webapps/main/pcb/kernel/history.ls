require! 'aea': {hash, clone}
require! 'prelude-ls': {values, difference, keys, empty}
require! './LdbStorage': {LdbStorage}

export class History
    (opts) ->
        @parent = opts.parent
        @project = opts.project
        @ractive = opts.ractive
        @selection = opts.selection
        @vlog = opts.vlog
        @db2 = new LdbStorage opts.name, ctx=this
        @commits = []
        @limit = 200
        @history-limit = 5

        @history-loaded = no 
        @loaded-callbacks = []

    commit: ->
        json = @project.exportJSON {as-string: no}
        try
            backup = clone json
            @commits.push {layout: backup, name: @parent.active-layout}
        catch
            @vlog.error "Huston, we have a problem: \n\n #{e.message}"
            return
        console.log "added to history"
        if @commits.length > @limit
            console.log "removing old history"
            @commits.shift!

    back: (cb) ->
        err=false
        res=null 
        if @commits.pop!
            console.log "Going back in the history. Left: #{@commits.length}"
            @load-project that.layout, that.name
            res = {left: @commits.length}
        else
            console.warn "No commits left, sorry."
            err=true

        if typeof! cb is \Function
            cb(err, res)


    load-project: (data, name) ->
        # data: stringified JSON
        if data
            @parent.clear-canvas! # use (<= this) instead of (this =>) @project.clear!
            @parent.importLayout data, name

    reset-script-diffing: ->
        @ractive.set \scriptHashes, null

    load-scripts: (saved) ->
        @ractive.set \drawingLs, saved
        #console.log "loaded scripts: ", saved

    save: (cb) ->
        # Save history into browser's local storage
        # -----------------------------------------
        # save current project
        data = @project.exportJSON!
        @db2.set \project, data
        @db2.set \layouts, @parent.layouts 
        @db2.set \activeLayout, @parent.activeLayout

        # save scripts
        /*
        scripts = @ractive.get \drawingLs
        @db2.set \scripts, scripts
        */

        # Save settings
        # TODO: provide a proper way for this, it's too messy now
        @db2.set \settings, do
            scriptName: @ractive.get \scriptName
            projectName: @ractive.get \project.name
            autoCompile: @ractive.get \autoCompile
            currTrace: @ractive.get \currTrace

        # save last 10 commits of history
        @db2.set \history, @commits.slice(- @history-limit)

        res = 
            message: "Saved at #{Date!}"
            size: "#{parseInt(data.length/1024)}KB"

        console.log "#{res.message}, size: #{res.size}"

        if typeof! cb is \Function 
            cb(err=null, res)

    load: ->
        # Load from browser's local storage
        # --------------------------------------

        commits <~ @db2.get \history
        if commits
            if @commits.length is 0 and typeof! commits is \Array
                @commits = commits
            else
                @ractive.get \vlog .error "How come the history isn't empty?"
                console.error "Commit history isn't empty: ", @commits

        value <~ @db2.get \layouts
        if value
            @parent.layouts = that 

        value <~ @db2.get \activeLayout
        if value
            @parent.activeLayout = that 

        value <~ @db2.get \project 
        if value 
            @load-project that

        value <~ @db2.get \scripts
        if value 
            @load-scripts that

        value <~ @db2.get \settings 
        if value
            # TODO: see save/settings
            @ractive.set \scriptName, that.scriptName
            @ractive.set \project.name, that.projectName
            @ractive.set \autoCompile, that.autoCompile
            @ractive.set \currTrace, that.currTrace
        
        unless @history-loaded
            while @loaded-callbacks.length > 0
                {callback, ctx} = @loaded-callbacks.shift!
                callback?call ctx

        @history-loaded = yes 

    loaded: (ctx, callback) ->
        # indicates that the history is loaded.
        if typeof! ctx is \Function 
            callback = ctx 
            ctx = this 

        if @history-loaded
            callback.call ctx
        else
            @loaded-callbacks.push {ctx, callback}
        