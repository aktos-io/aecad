# global imports
require! 'prelude-ls': {
    find, empty, unique, difference, max, keys, flatten, filter, values
}

# deps
require! './deps': {find-comp, PaperDraw, text2arr, get-class, get-aecad}
require! './lib': {parse-name}

export do
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
                    if name of bom
                        throw new Error "Duplicate instance: #{name}"
                    bom[name] =
                        name: name
                        params: group.params
                        parent: @name
                        data: @data.schemas?[type]
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

    find-unused: (bom) ->
        # detect unused pads of footprints in BOM:
        required-pads = {}
        for instance, args of bom
            console.log "Found #{args.type} instance: #{instance}"
            pads = if args.data
                # this is a sub-circuit, use its `iface` as `pad`s
                that.iface |> text2arr
            else
                # outsourced component, use its iface (pads)
                Component = get-class args.type
                sample = new Component ((args.params or {}) <<< {+silent})
                values sample.iface

            for pad in pads or []
                required-pads["#{instance}.#{pad}"] = null
        console.log "Required pads333:", JSON.stringify required-pads
        # find used iface pins
        for id, net of @data.netlist
            for text2arr net
                console.log "...pad #{..} is used."
                if .. of required-pads
                    delete required-pads[..]

        console.log "Required pads2:", required-pads
        # throw the exception if there are unused pads
        unused = keys required-pads
        unless empty unused
            throw new Error "Unterminated pads: #{unused.map (~> "#{@prefix}#{it}") .join ','}"
