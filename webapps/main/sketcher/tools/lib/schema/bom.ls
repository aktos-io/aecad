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

    get-bom-components: ->
        b = flatten [..name for filter (-> not it.data), values @get-bom!]
        #console.log "bom raw components found:", b
        return b
