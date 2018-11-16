require! './find-comp': {find-comp}
require! 'prelude-ls': {
    find, empty, unique, difference, max, keys, flatten, filter, values
}
require! '../../kernel': {PaperDraw}
require! './text2arr': {text2arr}
require! './get-class': {get-class}

combinations = (input, ffunc=(-> it)) ->
    comb = []
    for i in input.0
        :second for j in input.1
            continue if i is j
            for comb
                if empty difference [i, j].map(ffunc), ..map(ffunc)
                    continue second
            comb.push [i, j]
    comb

a = <[ a b c d ]>
out = combinations [a, a]
expected = [["a","b"],["a","c"],["a","d"],["b","c"],["b","d"],["c","d"]]
if JSON.stringify(out) isnt JSON.stringify(expected)
    throw "Problem in combinations: 1"

a =
    {src: 'a'}
    {src: 'b'}
    {src: 'c'}
    {src: 'd'}
out = combinations [a, a]
expected =
    [{src: 'a'},{src: "b"}]
    [{src: "a"},{src: "c"}]
    [{src: "a"},{src: "d"}]
    [{src: "b"},{src: "c"}]
    [{src: "b"},{src: "d"}]
    [{src: "c"},{src: "d"}]
if JSON.stringify(out) isnt JSON.stringify(expected)
    throw "Problem in combinations: 2"


'''
Usage:

    # create guide for specific source
    sch.guide-for \c1.vin

    # create all guides
    sch.guide-all!

    # get a schema (or "curr"ent schema) by SchemaManager
    sch2 = new SchemaManager! .curr

'''

# Will be used for Schema exchange between classes
export class SchemaManager
    @instance = null
    ->
        # Make this class Singleton
        # ------------------------------
        return @@instance if @@instance
        @@instance = this
        # ------------------------------
        @schemas = {}
        @curr-name = null
        @using = null

    register: (schema) ->
        name = schema.name
        unless name
            throw new Error "Schema must have a name."

        # auto activate last defined schema
        @curr-name = name

        if name of @schemas
            console.log "Updating schema: #{name}"
            @schemas[name] = null
            delete @schemas[name]
        else
            console.log "Adding new schema: #{name}"

        @schemas[name] = schema

    curr: ~
        -> @schemas[@using or @curr-name]

    use: (name) ->
        @using = name
        unless @curr.compiled
            @curr.compile!


export class Schema
    (opts) ->
        '''
        # TODO: Implement parent schema handling


        opts:
            name: Name of schema
            prefix: *Optional* Prefix of components
            params: Variant definition
            data:
                iface: Interface labeling
                netlist: Connection list
                schemas: [Object] Available sub-circuits
                bom: Bill of Materials

                    key: value => Component's exact name: List of instances

                    # or

                    key:
                        params: value
                notes: Notes for each component
        '''
        if opts
            unless that.name
                throw new Error "Name is required for Schema"
            @name = that.name
            @data = that.data
            @prefix = that.prefix or ''
        else
            throw new Error "Data should be provided in {name, data} format."
        @scope = new PaperDraw
        @connections = []
        @manager = new SchemaManager
            ..register this
        @compiled = false
        @sub-circuits = {}

    get-bom: ->
        bom = {}
        if typeof! @data.bom is \Array
            throw new Error "BOM should be Object, not Array"
        for type, val of @data.bom
            if typeof! val is 'String'
                # this is shorthand for "empty parametered instances"
                val = {'': val}

            # params: list of instances
            instances = []
            for params, names of val
                instances.push do
                    params: params
                    names: text2arr names

            # create
            for group in instances
                for name in group.names
                    # create every #name with params: group.params
                    bom[name] =
                        name: "#{@name}-#{name}"
                        params: group.params
                        prefix: name
                        data: @data.schemas?[type]
        #console.log "Compiled bom is: ", bom
        @bom = bom
        bom

    compile: !->
        @compiled = true

        # Compile sub-circuits first
        for sch in filter (.data), values @get-bom!
            console.log "Initializing sub-circuit: #{sch.name} ", sch
            @sub-circuits[sch.prefix] = new Schema sch
                ..compile!

        # add needed footprints
        @add-footprints!

        return

        @netlist = null
        @netlist = {}
        # @netlist = Object
        #     trace-id   : left-hand of netlist
        #         * src        : Exact name of node (same in netlist)
        #           c          : Component that holds this pin
        #           pad        : Pad object
        #         ...
        #
        for id, conn-list of _netlist
            # TODO: performance improvement:
            # use find-comp for each component only one time
            @netlist[id] = [] unless id of @netlist
            conn = [] # cache (list of connected nodes)
            for fname in text2arr conn-list
                [...name, pin] = (opts.prefix + fname).split('.')
                name = name.join '.'
                console.log "Searching for component/entity: #{name} and pin: #{pin}"

                # Look for component in sub-schemas first:
                if name of @netlist
                    # This component might be already included by sub-schema
                    continue
                comp = find-comp name
                unless comp
                    throw new Error "No such pad found: '#{name}'"

                pad = (comp.get {pin}) or []
                if empty pad
                    throw new Error "No such pin found: '#{pin}' of '#{name}'"
                conn.push {src: p-name, c: comp, pad}

            @_netlist[id] ++= conn


        #console.log "current raw netlist: ", @_netlist
        merge-connections = (target) ~>
            #console.log "merging connection: #{target}"
            unless target of @get-netlist(opts)
                throw new Error "No such trace found: '#{target}' (opts: #{JSON.stringify opts})"
            c = @get-netlist(opts)[target]
            for c
                if ..connect
                    c ++= merge-connections that
            c

        @connections.length = 0
        refs = [] # store ref labels in order to exclude from @connections
        for id, connections of @get-netlist(opts)
            flat = []
            for node in connections
                if node.connect
                    refs.push that
                    flat ++= merge-connections that
                else
                    unless id in refs
                        flat.push node
            @connections.push flat
        #console.log "Compiled connections: ", @connections

    get-netlist: (opts={}) ->
        # prefixed netlist
        pfx = opts.prefix or ''
        netlist = {}
        for trace-id, conn-list of @_netlist
            netlist[pfx + trace-id] = []
            for conn-list
                netlist[pfx + trace-id].push if ..connect
                    # This is a cross reference
                    {connect: ..connect}
                else
                    {src: "#{pfx}#{..src}", ..c, ..pad}

        for name, sch of @sub-schemas
            netlist <<< sch.schema.get-netlist({prefix: "#{name}."})
        #console.log "returning netlist: ", netlist
        netlist

    get-netlist-components: ->
        components = []
        for id, conn-list of @data.netlist
            for n-name in text2arr conn-list # node-name
                [...name, pin] = n-name.split '.'
                name = name.join '.'
                unless name
                    # This is a cross reference
                    name = n-name

                if name in text2arr @data.iface
                    # This is an interface reference, not a physical component
                    continue

                if name in keys @data.netlist
                    # this is only a cross reference, ignore it
                    continue

                if name in keys @sub-circuits
                    # this is a sub-circuit element, it has been handled in its Schema
                    continue

                unless name in components
                    components.push name

        #console.log "netlist raw components found: ", components
        return components

    get-bom-components: ->
        b = flatten [..prefix for filter (-> not it.data), values @get-bom!]
        #console.log "bom raw components found:", b
        return b

    add-footprints: (opts) !->
        missing = @get-netlist-components! `difference` @get-bom-components!
        unless empty missing
            throw new Error "Netlist components missing in BOM: \n\n#{missing.join(', ')}"


        return
        created-components = []
        # create sub-schema components
        for name, sch of @sub-schemas
            created-components ++= sch.schema.components

        @components = []
        curr = @scope.get-components {exclude: <[ Trace ]>}
        for type, names of @data.bom
            for c in text2arr names
                prefixed = "#{opts.prefix or ''}#{c}"
                if prefixed not in [..name for curr]
                    console.log "Component #{prefixed} (#{type}) is missing, will be created now."
                    _Component = getClass(type)
                    @components.push new _Component {name: prefixed}
                else
                    existing = find (.name is prefixed), curr
                    if type isnt existing.type
                        console.log "Component #{prefixed} exists,
                        but its type (#{existing.type})
                        is wrong, should be: #{type}"

        unless opts.prefix
            # fine tune initial placement
            # ----------------------------
            # Place left of current bounds by fitting in a height of
            # current bounds height
            current = @scope.get-bounds!
            allowed-height = current.height
            prev = {}
            placement = []
            voffset = 10
            created-components ++= @components
            for created-components
                lp = placement[*-1]
                if (empty placement) or ((lp?.height or + voffset) + ..bounds.height > allowed-height)
                    # create a new column
                    placement.push {list: [], height: 0, width: 0}
                    lp = placement[*-1]
                lp.list.push ..
                lp.height += ..bounds.height + voffset
                lp.width = max lp.width, ..bounds.width

            console.log "Placements so far: ", placement
            prev-width = 0
            hoffset = 50
            for index, pl of placement
                for pl.list
                    ..position = ..position.subtract [pl.width + hoffset + prev-width, 0]
                    if prev.pos
                        ..position.y = prev.pos.y + prev.height / 2 + ..bounds.height / 2 + voffset
                    prev.height = ..bounds.height
                    prev.pos = ..position
                prev.pos = null
                prev-width += pl.width + hoffset

    guide-for: (src) ->
        guides = []
        for node in @connections
            if src
                # Only create a specific guide for "src", skip the others
                if src not in [..src for node]
                    continue
                console.log "Creating guide for #{src}"
            if node.length < 2
                console.warn "Connection has very few nodes, skipping guiding: ", node
                continue

            for combinations [node, node], (.src)
                [f, s] = ..
                if src in ..map (.src)
                    continue
                console.log "creating gude #{f.src} -> #{s.src} (#{f.pad.0.g-pos} -> #{s.pad.0.g-pos})"
                guides.push @create-guide f.pad.0, s.pad.0
        return guides

    guide-all: ->
        @guide-for!

    create-guide: (pad1, pad2) ->
        new @scope.Path.Line do
            from: pad1.g-pos
            to: pad2.g-pos
            stroke-color: 'lime'
            stroke-width: 0.1
            selected: yes
            data: {+tmp, +guide}

    clear-guides: ->
        for @scope.project.layers
            for ..getItems {-recursive} when ..data.tmp and ..data.guide
                ..remove!
