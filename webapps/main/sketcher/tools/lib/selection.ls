require! 'prelude-ls': {empty, flatten, group-by, filter}
require! 'dcs/lib/event-emitter': {EventEmitter}


export class Selection extends EventEmitter
    @instance = null
    ->
        # Make this class Singleton
        return @@instance if @@instance
        @@instance = this
        super!

        @selected = []
        @_active = []
        @_passive = []
        @scope = null # assigned in PaperDraw

    deselect: (opts={}) ->
        for @selected
            if ..getClassName?! is \Curve
                ..getPath!.selected = no
            else if ..selected?
                ..selected = no
            else if ..item?selected?
                # for custom selections
                ..item.selected = no
            if ..data?.tmp
                #console.log "removing temporary path: ", ..
                ..remove!

        # do cleanup
        cleanup @selected
        cleanup @_active
        cleanup @_passive

        # FIXME: remove this extra precaution
        @scope.project.deselect-all!
        
        # FIXME: remove this extra caution
        @scope.clean-tmp!

        @trigger \cleared


    clear: ->
        @deselect!

    filter: (_filter) ->
        filter _filter, @selected

    group-by: -> (_filter) ->
        group-by _filter, @selection

    count: ~
        ->
            console.log "selected count: ", @selected.length
            @selected.length

    add: (items, opts={select: yes}) ->
        debug-mode = off
        for flatten [items]
            switch ..getClassName?!
            | \Path => \ok
            | \Curve => \ok
            | \Segment => \ok
            | \Group => \ok
            | \Layer =>
                # do not add layers
                if debug-mode
                    console.log "...we are not selecting layers: ", ..
                continue
            | \Point => \ok
            |_ =>
                if typeof! .. is \Object
                    # This is a custom object: normally in {name, item} format.
                    # name is the group name, item is the value
                    @selected.push ..
                    if ..item
                        if opts.select
                            ..item.selected = yes
                    continue
                else
                    console.warn ".........unrecognized selection: ", ..
                    continue

            if ..id? and find (.id is ..id), @selected
                console.log "duplicate item, not adding: ", ..
                continue
            if ..selected
                console.log "already selected, not adding"
                continue
            @selected.push ..
            if opts.select
                ..selected = yes
                @_active.push ..
            else
                @_passive.push ..
        #console.log "Selected items so far: #{@selected.length}", @selected
        @trigger \selected, @selected

    get-selection: ->
        active = null
        if @_passive.length > 0
            # if we have passive selection,
            # we must have only one active
            # selection at most
            if @_active.length > 1
                throw do
                    message: "More than one active selection"
                    selection: @selection
                    active: @_active
                    passive: @_passive
        return {
            active: @_active.0
            rest: @_passive
        }


    delete: !->
        for i, item of @selected
            #console.log "item is: ", item
            if item.item? or item.solver?
                # custom object
                continue if item.solver?
                try
                    item.item.remove!
                catch
                    item.item._owner.remove!
            else
                try
                    item.remove!
                catch
                    item._owner.remove!

        cleanup @selected

    get-top-item: ->
        @selected.0
