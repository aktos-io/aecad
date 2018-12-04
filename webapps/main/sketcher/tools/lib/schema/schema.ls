# global imports
require! 'prelude-ls': {
    find, empty, unique, difference, max, keys, flatten, filter, values
    first, unique-by, compact
}

# deps
require! './deps': {find-comp, PaperDraw, text2arr, get-class, get-aecad}
require! './lib': {parse-name, next-id}

# Class parts
require! './bom'
require! './footprints'
require! './netlist'
require! './guide'
require! './schema-manager': {SchemaManager}

# Recursively walk through links
get-net = (netlist, id, included=[], mark) ~>
    #console.log "...getting net for #{id}"
    reduced = []
    included.push id
    if find (.remove), netlist[id]
        #console.warn "Netlist(#{id}) is marked to be removed (already merged?)"
        return []
    for netlist[id]
        if ..link
            # follow the link
            unless ..target in included
                linked = get-net netlist, ..target, included, {+remove}
                for linked
                    unless ..uname in reduced
                        reduced.push ..
                    else
                        console.warn "Skipping duplicate pads from linked net"
        else
            reduced ++= ..pads
    if mark
        # do not include this net in further lookups
        netlist[id].push mark
    reduced

the-one-in = (arr) ->
    # expect only one truthy value in the array
    # and return it
    the-value = null
    for arr when ..?
        unless the-value
            the-value = ..
        else if "#{the-value}" isnt "#{..}"
            console.error "the-one-in: ", arr
            throw new Error "We have multiple values in this array"
    the-value


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
        @manager = new SchemaManager
            ..register this
        @compiled = false
        @connection-list = {}           # key: trace-id, value: array of related Pads
        @sub-circuits = {}              # TODO: DOCUMENT THIS
        @netlist = []                   # array of "array of Pads which are on the same net"

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

    no-connect: ~
        -> text2arr @data.no-connect

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
        console.log "* Compiling schema: #{@name}"
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
                    net.push {link: yes, target: full-name}

                    # create a cross link
                    unless full-name of netlist
                        netlist[full-name] = []
                    netlist[full-name].push {link: yes, target: id, type: \cross-link}
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
                        console.error "Current iface:", comp.iface
                        throw new Error "No such pin found: '#{pin}' of '#{name}'"

                    # find duplicate pads (shouldn't be)
                    if (unique-by (.uname), pads).length isnt pads.length
                        console.error "FOUND DUPLICATE PADS in ", name

                    net.push {name, pads}
            unless id of netlist
                netlist[id] = []
            netlist[id] ++= net  # it might be already created by cross-link

        unless @parent
            #console.log "Flatten netlist:", @flatten-netlist
            #console.log "Netlist (raw) (includes links and cross-links): ", netlist
            @reduce netlist

    get-required-pads: ->
        all-pads = {}
        for @components
            # request all connectable pads from components
            for ..component.get {+connectable}
                all-pads[..pin] = null
        return all-pads

    build-connection-list: !->
        # Re/Build the connection name table for the net
        # ------------------------------------------------
        # * use the existing netid that supplied by any of net's pads
        # * assign the rest of nets' netid's sequentially
        @connection-list = {}
        # Collect already assigned netid's
        newly-created = []
        for net in @netlist
            try
                netid = '' + the-one-in [..netid for net]
            catch
                # just in case
                console.error "#{net.map ((p) -> "#{p.uname}[#{p.netid}]") .join ', '}"
                throw new Error "Multiple netid's assigned to the pads in the same net"

            # use existing netid extracted from one of the pads
            if netid?.match /[0-9]+/
                if netid of @connection-list
                    existing = @connection-list[netid].map (.uname) .join ', '
                    curr = net.map (.uname) .join ', '
                    throw new Error "Duplicate netid found: #{netid} (#{curr} already occupied by #{existing}"
                @connection-list[netid] = net
                # Propagate netid's to all pads in the same net
                for pad in net
                    pad.netid = netid
            else
                # this net is newly created, take your note to assign next possible
                # netid
                newly-created.push net

        # Assign newly created net's netid's
        for til newly-created.length
            net = newly-created.pop!
            # generate the next netid
            netid = next-id @connection-list
            @connection-list[netid] = net
            for pad in net
                pad.netid = netid

    reduce: (netlist) ->
        # Create reduced netlist
        @netlist.length = 0
        for id of netlist
            net = get-net netlist, id
            unless empty net
                @netlist.push net

        # build the @connection-list
        @build-connection-list!

        # Check errors
        @post-check!

        # Output the generated report
        #console.log "... #{@name}: Connection list:", @connection-list
        #console.log "... #{@name}: Netlist", @netlist

    post-check: ->
        # Error report (will stay for Alpha stage)
        for index, pads of @netlist
            # Check for duplicate pads in the same net
            for _i1, p1 of pads
                for _i2, p2 of pads when _i2 > _i1
                    if p1.uname and p2.uname and p1.uname is p2.uname
                        console.error "Duplicate pads found: #{p1.cid} and #{p2.cid}: in #{_i1} and #{_i2} ", p1.uname, p1

            # Find unmerged nets
            for _i, _pads of @netlist when _i > index
                for p1 in pads
                    for p2 in _pads
                        if p1.uname is p2.uname
                            console.error "Unmerged nets found
                            : Netlist(#{index}) and Netlist(#{_i}) both contains #{p1.uname}"