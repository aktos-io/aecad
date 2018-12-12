require! 'prelude-ls': {empty, flatten, group-by, filter, find}
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
            | \Shape => \ok
            | \Layer =>
                # do not add layers
                if debug-mode
                    console.log "...we are not selecting layers: ", ..
                continue
            | \Point => \ok
            |_ =>
                if typeof! .. is \Object
                    # This is a custom object: normally in {name, item?, aeobj?} format.
                    @selected.push ..
                    if opts.select
                        ..item?.selected = yes
                        ..aeobj?.selected = yes
                        if \selected of ..
                            ..selected = yes
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
        for elem in @selected
            console.log "Selected element is: ", elem
            if elem.aeobj
                that.owner.remove!
            else if elem.item? or elem.solver?
                # custom object
                continue if elem.solver?
                try
                    elem.item.remove!
                catch
                    elem.item._owner.remove!
            else
                item = elem
                try
                    item.remove!
                catch
                    item._owner.remove!

        cleanup @selected

    get-top-item: ->
        @selected.0

    bounds: ->
        # get selection bounds
        selected-items = for @selected
            if ..aeobj
                that.gbounds
            else if ..item
                that
            else
                ..

        @scope.get-bounds selected-items
