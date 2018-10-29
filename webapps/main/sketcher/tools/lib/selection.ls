require! 'prelude-ls': {empty, flatten}
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
            if ..getClassName! is \Curve
                ..getPath!.selected = no
            else
                ..selected = no
            if ..data?.tmp
                #console.log "removing temporary path: ", ..
                ..remove!

        # FIXME: remove this extra precaution
        for @scope.project.getItems({+selected})
            ..selected = no

        @selected.length = 0
        @_active.length = 0
        @_passive.length = 0

        # FIXME: remove this extra caution
        @scope.clean-tmp!

        @trigger \cleared


    clear: ->
        @deselect!

    add: (items, opts={select: yes}) ->
        for flatten [items]
            try
                switch ..getClassName!
                | \Path => \ok
                | \Curve => \ok
                | \Segment => \ok
                | \Group => \ok
                | \Layer =>
                    # do not add layers
                    console.log "...we are not selecting layers: ", ..
                    continue
                | \Point => \ok
                |_ =>
                    console.warn "unrecognized", ..
                    throw
            catch
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
            console.log "item is: ", item
            try
                item.remove!
            catch
                item._owner.remove!

        @selected.length = 0

    get-top-item: ->
        @selected.0
