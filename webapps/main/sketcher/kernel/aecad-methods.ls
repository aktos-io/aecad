
# dig item untill it has no children or it's an aeCAD object
dig-for-aecad = (item) ->

export do
    get-components: (opts) ->
        '''
        Returns all aeCAD components in {item, type, name, rev} form
        '''
        unless opts
            opts = {}
        items = []
        for @project.layers
            for item in ..getItems {-recursive}
                if type=(item.data?aecad?type)
                    skip-exclude = no
                    if opts.include
                        if type in that
                            skip-exclude = yes
                    if not skip-exclude and opts.exclude
                        if that is '*' or type in that
                            continue
                    name = item.data.aecad.name
                    rev = item.data.aecad.rev
                    items.push {item, type, name, rev}
        items

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
