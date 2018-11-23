# global imports
require! 'prelude-ls': {
    find, empty, unique, difference, max, keys, flatten, filter, values
}

# deps
require! './deps': {
    find-comp, PaperDraw, text2arr, get-class, get-aecad
}

get-rev = (cls) ->
    rev = 0
    for to 100
        if cls["rev_#{cls.name}"]
            rev += +that
        if cls.superclass
            cls = that
        else
            break
    rev

# Usage of `get-rev`
class C
    @rev_C = "4"

class B extends C
    #@rev_B = "3"

class A extends B
    @rev_A = "2"

unless get-rev(A) is 6
    throw new Error "get-rev doesn't work correctly"


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
            throw new Error "Netlist components missing in BOM: #{missing.join(',')}"

        @components = []
        # add sub-circuit components
        for name, sch of @sub-circuits
            for sch.components
                @components.push .. <<< {source: sch}

        curr = @scope.get-components {exclude: <[ Trace ]>}
        for {name, type, data} in values @get-bom! when not data # loop through only raw components
            pfx-name = "#{@prefix}#{name}"
            _Component = getClass(type)
            if pfx-name not in [..name for curr]
                # This component hasn't been created yet, create it
                @components.push do
                    component: new _Component {name: pfx-name}
            else
                existing = find (.name is pfx-name), curr
                @components.push comp =
                    component: get-aecad existing.item
                    existing: yes
                    upgrade-needed: ''

                reason = ''
                if type isnt existing.type
                    comp.upgrade-needed = yes
                    reason += "Type changed from #{existing.type} to #{type}"

                curr-ver = get-rev _Component
                if curr-ver isnt (existing.version or 0)
                    comp.upgrade-needed = yes
                    reason += "Version changed from #{existing.version} to #{curr-ver}"

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
