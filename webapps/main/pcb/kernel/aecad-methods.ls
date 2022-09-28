require! '../tools/lib/get-aecad': {get-aecad}

# dig item untill it has no children or it's an aeCAD object
dig-for-aecad = (item) ->

export do
    get-components: (opts) ->
        '''
        Returns all aeCAD components in {item, type, name, rev} form within the drawing area.

        opts:
            include: Array of Component.type's that should be included to the search
            exclude: Array of Component.type's that should be excluded from the search.
                Wildcard exclude (`*`) is possible by `exclude: "*"`.
            skip-exclude: Skips any type passed by `opts.exclude` property.
        '''
        unless opts
            opts = {}
        items = []
        if opts.exclude is '*'
            opts.exclude = ['*']
        for <[ include exclude skipExclude ]>            
            if opts[..]? and typeof! opts[..] isnt \Array
                throw new Error "'#{..}' argument must be array, not #{typeof! opts[..]}"
            
        for @project.layers
            for item in ..getItems {-recursive}
                if type=(item.data?aecad?type)
                    skip-exclude = no
                    if opts.include
                        if type in that
                            skip-exclude = yes
                    if not skip-exclude and opts.exclude
                        if '*' in opts.exclude or type in opts.exclude
                            continue
                    name = item.data.aecad.name
                    rev = item.data.aecad.rev
                    items.push {item, type, name, rev}
        items

    get-aeobjs: (opts) -> 
        aeobjs = []
        for @get-components opts 
            aeobjs.push get-aecad ..item
        aeobjs

    get-traces: -> 
        return for @get-components {include: ['Trace'], exclude: ['*']}
            get-aecad ..item 

    vertex-marker: (point) ->
        @_prev_vertex_marker?remove!
        @_prev_vertex_marker = new @Shape.Circle do
            center: point
            radius: 5
            stroke-width: 1
            opacity: 0.8
            stroke-color: 'yellow'
            data: {+tmp}

    marker-clear: ->
        @_prev_vertex_marker?remove!
        @_prev_vertex_marker = null

    marker-point: ->
        @_prev_vertex_marker?.bounds.center
