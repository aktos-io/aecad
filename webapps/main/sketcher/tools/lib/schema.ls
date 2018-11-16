require! './find-comp': {find-comp}
require! 'prelude-ls': {
    find, empty, unique, difference, max, keys, flatten, filter, values
    group-by
}
require! '../../kernel': {PaperDraw}
require! './text2arr': {text2arr}
require! './get-class': {get-class}
require! './get-aecad': {get-aecad}
require! 'aea': {clone}

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


parse-name = (full-name, opts) ->
    unless opts => opts = {}
    link = no
    [...name, pin] = full-name.split '.'
    name = name.join '.'
    res = {name, pin}
    ext = [..name for (opts.external or [])]
    #console.log "externals: ", ext
    if name in ext
        res.link = yes
        res.name = full-name
        console.log "..............", full-name

    unless name
        # This is a cross reference
        res.name = full-name
        delete res.pin
        res.link = yes

    if opts.prefix
        res.raw = res.name
        res.name = "#{that}#{res.name}"
    return res

tests =
    1:
        full-name: "a.b.c.d"
        expected: {name: "a.b.c", pin: 'd'}
    2:
        full-name: "a"
        expected: {name: "a", link: yes}
    3:
        full-name: "a"
        opts: {prefix: 'hello.'}
        expected: {name: "hello.a", link: yes, raw: 'a'}
    4:
        full-name: "a.b"
        opts: {prefix: 'hello.'}
        expected: {name: "hello.a", pin: 'b', raw: 'a'}

for k, test of tests
    res = parse-name(test.full-name, test.opts)
    unless JSON.stringify(res) is JSON.stringify(test.expected)
        console.error "Expected: ", test.expected, "Got: ", res
        throw new Error "Test failed for 'parse-name': at test num: #{k}"


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
        unless opts
            throw new Error "Data should be provided on init."

        unless opts.name
            throw new Error "Name is required for Schema"
        @name = opts.schema-name or opts.name
        @data = opts.data
        @prefix = opts.prefix or ''

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
                        name: name
                        params: group.params
                        parent: @name
                        data: @data.schemas?[type]
                        type: type
                        schema-name: "#{@name}-#{name}" # for convenience in constructor
                        prefix: [@prefix.replace(/\.$/, ''), name, ""].join '.' .replace /^\./, ''
        #console.log "Compiled bom is: ", bom
        @bom = bom

    external-components: ~
        # Current schema's external components
        -> [.. for values @bom when ..data]

    flatten-netlist: ~
        ->
            netlist = {}
            for c-name, net of @data.netlist
                netlist[c-name] = text2arr net

            for @iface
                # interfaces are null nets
                unless .. of netlist
                    netlist[..] = []

            for c-name, circuit of @sub-circuits
                #console.log "adding sub-circuit #{c-name} to netlist:", circuit
                for trace-id, net of circuit.flatten-netlist
                    prefixed = "#{c-name}.#{trace-id}"
                    #console.log "...added #{trace-id} as #{prefixed}: ", net
                    netlist[prefixed] = net .map (-> "#{c-name}.#{it}")

                for circuit.iface
                    # interfaces are null nets
                    prefixed = "#{c-name}.#{..}"
                    unless prefixed of netlist
                        netlist[prefixed] = []
            #console.log "FLATTEN NETLIST: ", netlist
            netlist

    components-by-name: ~
        ->
            by-name = {}
            for @components
                by-name[..component.name] = ..component
            by-name

    is-link: (name) ->
        if name of @flatten-netlist
            yes
        else
            no

    iface: ~
        -> text2arr @data.iface

    compile: !->
        @compiled = true

        # Compile sub-circuits first
        for sch in values @get-bom! when sch.data
            #console.log "Initializing sub-circuit: #{sch.name} ", sch
            @sub-circuits[sch.name] = new Schema sch
                ..compile!

        # add needed footprints
        @add-footprints!

        # compile netlist
        # -----------------
        #
        #   @netlist = Object
        #       trace-id   : left-hand of netlist
        #           * src        : Exact name of node (same in netlist)
        #             c          : Component that holds this pin
        #             pad        : Pad object
        #           ...
        #
        @netlist = null
        @netlist = {}
        console.log "Compiling netlist for schema: #{@name}"
        console.log "--------------------------------------"
        for id, conn-list of @flatten-netlist
            # TODO: performance improvement:
            # use find-comp for each component only one time
            @netlist[id] = [] unless id of @netlist
            conn = {merge: null, list: []} # cache (list of connected nodes)
            for full-name in conn-list
                {name, pin, link, raw} = parse-name full-name, do
                    prefix: @prefix
                    external: @external-components
                console.log "Searching for component/entity: #{name} and pin: #{pin} (link: #{link}), pfx: #{@prefix}"
                if @is-link full-name
                    # Merge into parent net
                    # IMPORTANT: Links must be key of netlist in order to prevent accidental namings
                    console.log "Found link: #{full-name}"
                    console.warn "HANDLE LINK"
                else
                    comp = @components-by-name[name]
                    unless comp
                        if name in @iface
                            console.log "Found an interface handle: #{name}. Silently skipping."
                            continue
                        else
                            console.error "Current components: ", @components-by-name
                            console.warn "Current netlist: ", @flatten-netlist
                            throw new Error "No such component found: '#{name}' (full name: #{full-name}), pfx: #{@prefix}"

                    pad = (comp.get {pin}) or []
                    if empty pad
                        throw new Error "No such pin found: '#{pin}' of '#{name}'"
                    conn.list.push {name, c: comp, pad}

            @netlist[id] ++= conn

        console.warn "breakpoint."
        return


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

        # TODO: REFACTOR THIS

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
                {name, link} = parse-name n-name

                if name in text2arr @data.iface
                    # This is an interface reference, not a physical component
                    continue

                if link
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
        b = flatten [..name for filter (-> not it.data), values @get-bom!]
        #console.log "bom raw components found:", b
        return b

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

        console.log "Schema (#{@name}) components: ", @components

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
