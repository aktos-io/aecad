# global imports
require! 'prelude-ls': {
    find, empty, unique, difference, max, keys, flatten, filter, values, map
}
# deps
require! './deps': {find-comp, PaperDraw, text2arr, get-class, get-aecad, parse-params}
require! './lib': {parse-name, replace-vars}
require! 'aea': {clone, merge}


export do
    get-bom: ->
        bom = {}
        if typeof! @data.bom is \Array
            throw new Error "BOM should be Object, not Array"

        for type, instances of replace-vars @params, @data.bom 
            if typeof! instances is 'String'
                # this is shorthand for "empty parametered instances"
                instances = {'': instances}

            # Support for simple strings in .schemas besides actual schemas 
            schema-data = @data.schemas?[type]
            if typeof! schema-data is \String
                type = schema-data
                schema-data = null 

            for params, names of instances
                # Handle params here 
                # "params" are mostly "value"s of instances, such as "10nF" or "3kohm"
                # However, "params" maybe real parameters in the form of "key:value|key2:value2"

                merged-params = if /:/.exec params 
                    # this is key:value parameters
                    (clone @params) `merge` (parse-params params) 
                else
                    params 
                #console.log "merged params: ", merged-params

                for name in text2arr names
                    # create every #name with params: params
                    if name of bom
                        throw new Error "Duplicate instance: #{name}"
                    #console.log "Creating bom item: ", name, "as an instance of ", type, "params:", params
                    calculated-schema = if typeof! schema-data is \Function 
                        schema-data params
                    else 
                        schema-data

                    if typeof! calculated-schema is \Function 
                        throw new Error "Sub-circuit \"#{type}\" should be simple function, not a factory function. Did you forget to initialize it?"
                    bom[name] =
                        name: name
                        params: merged-params
                        parent: @name
                        data: calculated-schema
                        type: type
                        schema-name: "#{@name}-#{name}" # for convenience in constructor
                        prefix: [@prefix.replace(/\.$/, ''), name, ""].join '.' .replace /^\./, ''

        @find-unused bom
        #console.log "Compiled bom is: ", bom
        @bom = bom

    get-bom-components: ->
        b = flatten [..name for filter (-> not it.data), values @get-bom!]
        #console.log "bom raw components found:", b
        return b
        
    get-component-names: -> 
        # Returns component names in {id, name} format  
        [{id: v.name, name: v.name} for k, v of @components]

    get-bom-list: -> 
        # group by type, and then value 
        comp = [{..type, ..value, ..name} for values @components when ..name.0 isnt '_']
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
        # detect unused pads of footprints in BOM:
        required-pads = {}
        for instance, args of bom
            #console.log "Found #{args.type} instance: #{instance}"
            if instance.starts-with '_'
                continue
            pads = if args.data
                # this is a sub-circuit, use its `iface` as `pad`s
                that.iface |> text2arr
            else
                # outsourced component, use its iface (pads)
                Component = get-class args.type
                sample = new Component (args.params or {})
                iface = values sample.iface
                sample.remove!
                iface

            for pad in pads or []
                required-pads["#{instance}.#{pad}"] = null

        # iface pins are required to be used
        for @iface
            required-pads["#{..}"] = "iface"

        # find used iface pins
        for id, net of @data.netlist
            for (text2arr net) ++ [id]
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
            throw new Error "#{msg} #{unused.map (~> "#{@prefix}#{it}") .join ','}"


        # Detect erroneous unused pad declaration
        used = (keys @data.netlist) ++ (values @data.netlist) 
            |> flatten 
            |> map text2arr 
            |> flatten

        false-unused = []
        for pad in used or [] when pad in @no-connect
            false-unused.push pad 
        unless empty false-unused
            throw new Error "False unused pads: #{false-unused.map (~> "#{@prefix}#{it}") .join ','}"
