require! 'actors': {BrowserStorage}
require! 'aea': {hash, clone}
require! 'prelude-ls': {values, difference, keys, empty}

export class History
    (opts) ->
        @parent = opts.parent
        @project = opts.project
        @ractive = opts.ractive
        @selection = opts.selection
        @vlog = opts.vlog
        @db = new BrowserStorage opts.name
        @commits = []
        @limit = 200

    commit: ->
        json = @project.exportJSON {as-string: no}
        try
            backup = clone json
            @commits.push backup
        catch
            @vlog.error "Huston, we have a problem: \n\n #{e.message}"
            return
        console.log "added to history"
        if @commits.length > @limit
            console.log "removing old history"
            @commits.shift!

    back: ->
        if @commits.pop!
            console.log "Going back in the history. Left: #{@commits.length}"
            @load-project that
        else
            console.warn "No commits left, sorry."


    load-project: (data) ->
        # data: stringified JSON
        if data
            @parent.clear-canvas! # use (<= this) instead of (this =>) @project.clear!
            @selection.clear!
            @project.importJSON data

            while true
                needs-rerun = false
                for layer in @project.layers
                    unless layer
                        # workaround for possible Paper.js bug
                        # which can not handle more than a few
                        # hundred layers
                        console.warn "...we have an null layer!"
                        needs-rerun = true
                        continue
                    if layer.getChildren!.length is 0
                        console.log "removing layer..."
                        layer.remove!
                        continue

                    if layer.name
                        @ractive.set "project.layers.#{Ractive.escapeKey layer.name}", layer
                    else
                        layer.selected = yes

                    for layer.getItems!
                        ..selected = no
                        if ..data?.tmp
                            ..remove!
                break unless needs-rerun
                console.warn "Workaround for load-project works."
            #console.log "Loaded project: ", @project

    reset-script-diffing: ->
        @ractive.set \scriptHashes, null

    load-scripts: (saved) ->
        orig = @ractive.get \drawingLs
        curr-orig-h = @ractive.get \scriptHashes
        prev-orig-h = (@db.get \scriptHashes) or {}
        saved-h = do ->
            x = {}
            for n, c of saved
                x[n] = hash(c)
            return x

        updated-scripts = values(curr-orig-h) `difference` values(prev-orig-h)
        name-of-hash = (x) ->
            for name, h of curr-orig-h
                return name if h is x

        _names = []
        for h in updated-scripts
            name = name-of-hash h
            if h in values(saved-h)
                console.log "We already have this, skipping: ", name
                continue

            @ractive.set "drawingLsUpdates.#{Ractive.escapeKey name}", do
                remote: orig[name]
                current: saved[name]

            _names.push name
        unless empty _names
            PNotify.notice hide: yes, text: """
                Script update:
                -----------------------
                #{_names.map (-> "* #{it}\n")}
                """
        @ractive.set \drawingLs, saved
        #console.log "loaded scripts: ", data

    save: ->
        # Save history into browser's local storage
        # -----------------------------------------
        # save current project
        data = @project.exportJSON!
        @db.set \project, data

        # save scripts
        scripts = @ractive.get \drawingLs
        @db.set \scripts, scripts
        #@db.set \scriptHashes, @ractive.get \scriptHashes

        # Save settings
        # TODO: provide a proper way for this, it's too messy now
        @db.set \settings, do
            scriptName: @ractive.get \scriptName
            projectName: @ractive.get \project.name
            autoCompile: @ractive.get \autoCompile
            currTrace: @ractive.get \currTrace

        # save last 10 commits of history
        @db.set \history, @commits.slice(-10)

        console.log "Saved at ", Date!, "project length: #{parseInt(data.length/1024)}KB"

    load: ->
        # Load from browser's local storage
        # --------------------------------------
        if @db.get \project
            @load-project that

        if @db.get \scripts
            @load-scripts that

        if @db.get \settings
            # TODO: see save/settings
            @ractive.set \scriptName, that.scriptName
            @ractive.set \project.name, that.projectName
            @ractive.set \autoCompile, that.autoCompile
            @ractive.set \currTrace, that.currTrace

        if commits=(@db.get \history)
            if @commits.length is 0 and typeof! commits is \Array
                @commits = commits
            else
                @ractive.get \vlog .error "How come the history isn't empty?"
                console.error "Commit history isn't empty: ", @commits
