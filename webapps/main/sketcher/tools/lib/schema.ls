require! './find-comp': {find-comp}
require! 'prelude-ls': {find, empty, unique, difference, max, keys}
require! '../../kernel': {PaperDraw}
require! './text2arr': {text2arr}
require! './get-class': {get-class}

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
        @curr.compile!


export class Schema
    (data) ->
        '''
        # TODO: Implement parent schema handling

        data:
            netlist: Connection list
            bom: Bill of Materials
            name: Schema name
            iface: Interface labeling
        '''
        if data
            @data = data
        @scope = new PaperDraw
        @_netlist = {}
        @connections = []
        @manager = new SchemaManager
            ..register this

    name: ~
        -> @data.name

    compile: (opts={prefix: ''}) !->
        # add needed footprints
        @add-footprints opts

        # compile schematic. input format: {netlist, bom}
        @_netlist = null
        @_netlist = {}
        for id, conn-list of @data.netlist
            # TODO: performance improvement:
            # use find-comp for each component only one time
            conn = [] # list of connected nodes
            unless @_netlist[id]
                @_netlist[id] = []
            for p-name in text2arr conn-list
                [name, pin] = p-name.split '.'
                if name.starts-with '*'
                    # this is a reference to another trace-id
                    ref = p-name.substr 1
                    ref = opts.prefix + ref
                    console.log "found a reference to another id (to: #{ref})"
                    @_netlist[id] ++= {connect: ref}
                else
                    name = opts.prefix + name
                    if name in keys @sub-schemas
                        # this is a sub-schema, do not search for a regular component
                        # it should be already handled in "add-footprints" step
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

    sub-schemas: ~
        ->
            # Return sub-schemas
            sch = {}
            if @data.schemas
                for cls, instances of that
                    for instance in text2arr instances
                        #console.log "Found sub-schema: #{instance} (an instance of #{cls})"
                        sch[instance] = {type: cls, schema: @manager.schemas[cls]}
            sch


    get-netlist-components: ->
        components = []
        for id, conn-list of @data.netlist
            for p-name in text2arr conn-list
                unless p-name.starts-with '*'
                    #console.log "examining #{p-name}"
                    [name, pin] = p-name.split '.'
                    components.push name
        res = unique components
        #console.log "netlist components found: ", res
        return res

    get-bom-components: ->
        components = []
        for type, comp-list of @data.bom
            for name in text2arr comp-list
                components.push name
        res = unique components
        #console.log "bom components found: ", res
        return res

    add-footprints: (opts) !->
        missing = @get-netlist-components(opts) `difference` @get-bom-components(opts)
        missing = missing `difference` keys(@sub-schemas)
        unless empty keys @sub-schemas
            #console.log "Sub-schemas found: ", @sub-schemas
            void
        unless empty missing
            throw new Error "Netlist components missing in BOM: \n\n#{missing.join(', ')}"

        created-components = []
        # create sub-schema components
        for name, sch of @sub-schemas
            sch.schema.compile {prefix: "#{name}."}
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
            if src and src not in [..src for node]
                continue # Only create a specific guide for "src", skip the others
            if node.length < 2
                console.warn "Connection has very few nodes, skipping guiding: ", node
                continue
            for i in node
                for j in node
                    guides.push @create-guide i.pad.0, j.pad.0
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
