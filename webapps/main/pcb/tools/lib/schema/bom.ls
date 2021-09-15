# global imports
require! 'prelude-ls': {
    find, empty, unique, difference, max, keys, flatten, filter, values, map
}
# deps
require! './deps': {find-comp, PaperDraw, text2arr, get-class, get-aecad, parse-params}
require! './lib': {parse-name}
require! 'aea': {clone, merge}


export do
    get-bom: ->
        bom = {}
        if typeof! @data.bom is \Array
            throw new Error "BOM should be Object, not Array"

        for type, instances of @data.bom 
            if typeof! instances is 'String'
                # this is shorthand for "empty parametered instances"
                instances = {'': instances}

            # Support for simple strings in .schemas besides actual schemas 
            schema-data = @data.schemas?[type]
            if typeof! schema-data is \String
                type = schema-data
                schema-data = null 

            for value, names of instances
                instance-names = {}
                if typeof! names in <[ String Array ]>
                    for text2arr names
                        instance-names[..] = null # null means "use default labels"
                else 
                    # detect quick labels
                    # keys: instance names (text2arr)
                    # value: (Object) labels
                    for i, labels of names 
                        for text2arr i 
                            instance-names[..] = labels 

                for name, labels of instance-names
                    # create every #name with params: params
                    if name of bom
                        throw new Error "Duplicate instance: #{name}"
                    #console.log "Creating bom item: ", name, "as an instance of ", type, "params:", params
                    calculated-schema = if typeof! schema-data is \Function 
                        schema-data value, labels 
                    else 
                        schema-data

                    if typeof! calculated-schema is \Function 
                        throw new Error "Sub-circuit \"#{type}\" should be simple function, not a factory function. Did you forget to initialize it?"
                    bom[name] =
                        name: name
                        value: value
                        labels: labels
                        parent: @name
                        data: calculated-schema
                        type: type
                        schema-name: "#{@name}-#{name}" # for convenience in constructor
                        prefix: [@prefix.replace(/\.$/, ''), name, ""].join '.' .replace /^\./, ''

        @find-unused bom
        #console.log "Compiled bom is: ", bom
        return @bom = bom

    get-bom-components: ->
        b = flatten [..name for filter (-> not it.data), values @get-bom!]
        #console.log "bom raw components found:", b
        return b
        
    get-component-names: -> 
        # Returns component names in {id, name} format  
        [{id: v.name, name: v.name} for k, v of @components]

    get-bom-list: -> 
        # group by type, and then value 
        comp = [{..type, ..value, ..name, ..labels} for values @components 
            when (not ..name.match /(^|\.)_.+/) and (..value?0 isnt '_')]
        arr = comp 
        g1 = {}
        for i in arr
            type1 = i["type"]
            unless g1[type1]
                g1[type1] = [] 
            g1[type1].push i
            
        g2 = {}
        for type1, arr of g1 
            g2[type1] = {}
            for i in arr 
                type2 = i["value"]
                unless g2[type1][type2]
                    g2[type1][type2] = [] 
                g2[type1][type2].push i 

        flatten-bom = []
        for type, v of g2
            for value, c of v 
                flatten-bom.push {
                    count: c.length, 
                    type, 
                    value, 
                    instances: [..name for c]
                }

        return flatten-bom

    find-unused: (bom) ->
        if "unused" in text2arr @data.disable-drc
            console.warn ".find-unused() is disabled by @data.disable-drc"
            return 

        # detect unused pads of footprints in BOM:
        required-pads = {}
        for instance, args of bom
            #console.log "Found #{args.type} instance: #{instance}"
            if instance.starts-with '__'
                # Completely exclude double underscored components from 
                # connections and bom
                continue

            if args.data
                # this is a sub-circuit, use its quick labels or `iface` as `pad`s
                #console.log "iface of subcircuit: ", that.iface
                if values args.labels .length > 0 
                    # use quick labels 
                    _pads = values args.labels
                else 
                    # use `iface`
                    _pads = args.data.iface |> text2arr

                pads = _pads |> map (.replace /[^.]+\./, '')
            else
                # outsourced component, use its iface (pads)
                Component = get-class args.type
                sample = new Component {args.value, args.labels}
                #console.log ".iface of #{Component.name}: ", sample.iface
                if Object.keys(sample.iface).length is 0
                    throw new Error "@iface can not be an empty object. If this is 
                        intended, set #{Component.name}.iface to {+ignore} to explicitly disable."

                iface = if sample.iface.ignore? is true 
                    []
                else
                    values sample.iface

                sample.remove!
                pads = iface

            for pad in pads or []
                required-pads["#{instance}.#{pad}"] = null

        # Schema interface 
        for (if args.labels then values(that) else @iface)
            required-pads["#{..}"] = "iface"

        # find used iface pins
        for id, net of @_netlist
            for net ++ [id]
                #console.log "...pad #{..} is used."
                if .. of required-pads
                    delete required-pads[..]

        for @no-connect
            if .. of required-pads
                delete required-pads[..]

        # throw the exception if there are unused pads
        unused = keys required-pads
        unless empty unused
            msg = if required-pads[unused.0] is \iface
                "Unconnected iface:"
            else
                "Unused pads:"
            throw new Error "#{msg} #{unused.map (~> "#{@prefix}#{it}") .join ', '}"

        # Detect erroneous unused pad declaration
        # (the pads that are declared as "no-connect" but are actually used in the circuit)
        used = flatten ((keys @_netlist) ++ (values @_netlist))
        false-unused = []
        for pad in used or [] when pad in @no-connect
            false-unused.push pad 
        unless empty false-unused
            throw new Error "False unused pads: #{false-unused.map (~> "#{@prefix}#{it}") .join ','}"
