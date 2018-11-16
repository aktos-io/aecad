# global imports
require! 'prelude-ls': {
    find, empty, unique, difference, max, keys, flatten, filter, values
}

# deps
require! './deps': {
    find-comp, PaperDraw, text2arr, get-class, get-aecad
}

export do
    add-footprints: (opts) !->
        missing = @get-netlist-components! `difference` @get-bom-components!
        unless empty missing
            throw new Error "Netlist components missing in BOM: \n\n#{missing.join(', ')}"

        @components = []
        # add sub-circuit components
        for name, sch of @sub-circuits
            for sch.components
                @components.push do
                    component: ..component
                    source: sch
                    existing: ..existing
                    update-needed: ..update-needed

        curr = @scope.get-components {exclude: <[ Trace ]>}
        for {name, type, data} in values @get-bom! when not data # loop through only raw components
            pfx-name = "#{@prefix}#{name}"
            if pfx-name not in [..name for curr]
                # This component hasn't been created yet, create it
                _Component = getClass(type)
                @components.push do
                    component: new _Component {name: pfx-name}
            else
                existing = find (.name is pfx-name), curr
                @components.push do
                    component: get-aecad existing.item
                    existing: yes
                    update-needed: type isnt existing.type

        #console.log "Schema (#{@name}) components: ", @components

        unless @prefix
            # fine tune initial placement
            # ----------------------------
            # Place left of current bounds by fitting in a height of
            # current bounds height
            current = @scope.get-bounds!
            allowed-height = current.height
            placement = []
            voffset = 10
            for {component, existing} in @components when not existing
                lp = placement[*-1]
                if (empty placement) or ((lp?.height or + voffset) + component.bounds.height > allowed-height)
                    # create a new column
                    placement.push {list: [], height: 0, width: 0}
                    lp = placement[*-1]
                lp.list.push component
                lp.height += component.bounds.height + voffset
                lp.width = max lp.width, component.bounds.width

            #console.log "Placements so far: ", placement
            prev = {}
            prev-width = 0
            hoffset = 50
            for index, pl of placement
                #console.log "Actually placing index: #{index}"
                for pl.list
                    ..position = ..position.subtract [pl.width + hoffset + prev-width, 0]
                    if prev.pos
                        ..position.y = prev.pos.y + prev.height / 2 + ..bounds.height / 2 + voffset
                    prev.height = ..bounds.height
                    prev.pos = ..position
                prev.pos = null
                prev-width += pl.width + hoffset
