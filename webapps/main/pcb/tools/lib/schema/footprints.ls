# global imports
require! 'prelude-ls': {
    find, empty, unique, difference, max, keys, flatten, filter, values
}

# deps
require! './deps': {
    find-comp, PaperDraw, text2arr, get-class, get-aecad, get-rev
}

export do
    get-upgrades: ->
        [.. for @components when ..upgrade-needed]

    remove-footprints: ->
        console.log "Removing created components by this schema (#{@name})"
        for @components or []
            ..component.remove!

    add-footprints: (opts) !->
        missing = @get-netlist-components! `difference` @get-bom-components!
        unless empty missing
            throw new Error "Components missing in BOM: #{missing.join(',')}"

        @components = []
        # add sub-circuit components
        for name, sch of @sub-circuits
            for sch.components
                @components.push .. <<< {source: sch}

        curr = @scope.get-components {exclude: <[ Trace ]>}
        for {name, type, data, params} in values @get-bom! when not data # loop through only raw components
            pfx-name = "#{@prefix}#{name}"
            _Component = getClass(type)
            #console.log "...adding component: #{name} type: #{type} params: ", params
            if pfx-name not in [..name for curr]
                # This component hasn't been created yet, create it
                @components.push do
                    component: new _Component {name: pfx-name, value: params}
                    type: type 
                    name: pfx-name
                    value: params
            else
                existing = find (.name is pfx-name), curr
                @components.push comp =
                    component: get-aecad existing.item
                    existing: yes
                    upgrade-needed: ''
                    type: existing.type
                    value: params 
                    name: pfx-name

                
                reason = ''
                if type isnt existing.type
                    comp.upgrade-needed = yes
                    reason += "Type changed from #{existing.type} to #{type}"
                    comp.type = type
                else
                    # update the value in any case
                    comp.component.set-data \value, params


                curr-rev = get-rev _Component
                if curr-rev isnt (existing.rev or 0)
                    comp.upgrade-needed = yes
                    reason += "Revision changed from #{existing.rev} to #{curr-rev}"

                if comp.upgrade-needed
                    reason = "Component #{pfx-name} needs upgrade: " + reason
                    comp.reason = reason
                    console.warn reason

        #console.log "Schema (#{@name}) components: ", @components

        unless @parent
            # fine tune initial placement
            # ----------------------------
            # Place left of current bounds by fitting in a height of
            # current bounds height
            current = @scope.get-bounds!
            allowed-height = current?.height or 300
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
