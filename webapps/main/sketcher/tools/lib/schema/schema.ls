# global imports
require! 'prelude-ls': {
    find, empty, unique, difference, max, keys, flatten, filter, values
    first
}

# deps
require! './deps': {find-comp, PaperDraw, text2arr, get-class, get-aecad}
require! './lib': {parse-name}

# Class parts
require! './bom'
require! './footprints'
require! './netlist'
require! './guide'
require! './schema-manager': {SchemaManager}


export class Schema implements bom, footprints, netlist, guide
    (opts) ->
        '''
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
        @parent = opts.parent
        @scope = new PaperDraw
        @connections = []
        @manager = new SchemaManager
            ..register this
        @compiled = false
        @sub-circuits = {}
        @netlist = []

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
        netlist = {}
        console.log "Compiling netlist for schema: #{@name}"
        for id, conn-list of @flatten-netlist
            # TODO: performance improvement:
            # use find-comp for each component only one time
            net = [] # cache (list of connected nodes)
            for full-name in conn-list
                {name, pin, link, raw} = parse-name full-name, do
                    prefix: @prefix
                    external: @external-components
                #console.log "Searching for entity: #{name} and pin: #{pin}, pfx: #{@prefix}"
                if @is-link full-name
                    # Merge into parent net
                    # IMPORTANT: Links must be key of netlist in order to prevent accidental namings
                    #console.warn "HANDLE LINK: #{full-name}"
                    net.push {link: yes, name: full-name}
                    continue
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

                    pads = (comp.get {pin}) or []
                    if empty pads
                        throw new Error "No such pin found: '#{pin}' of '#{name}'"
                    net.push {name, pads}
            netlist[id] = net

        unless @parent
            #console.log "Flatten netlist:", @flatten-netlist
            console.log "Netlist: ", netlist

        # Recursively walk through links
        get-net = (id) ~>
            #console.log "...getting net for #{id}"
            reduced = []
            for netlist[id]
                if ..link
                    # follow the link
                    #reduced.unshift ..
                    reduced ++= get-net ..name
                else
                    reduced ++= ..pads
            reduced

        unless @parent
            # Report only for the top level circuit
            @netlist.length = 0
            for id of netlist
                @netlist.push get-net id

            for index, pads of @netlist
                console.log "Netlist: #{index}: netlist: ", pads.map (.pin)
