require! './find-comp': {find-comp}
require! 'prelude-ls': {find, empty}
require! '../../kernel': {PaperDraw}

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

    register: (schema) ->
        name = schema.name
        unless name
            throw new Error "Schema must have a name."
        @curr-name = name

        if name of @schemas
            console.log "Updating schema: #{name}"
            @schemas[name] = null
            delete @schemas[name]
        else
            console.log "Adding new schema: #{name}"

        @schemas[name] = schema

    curr: ~
        -> @schemas[@curr-name]

export class Schema
    (@data) ->
        '''
        # TODO: Implement parent schema handling

        data:
            netlist: Connection list
            bom: Bill of Materials
            name: Schema name
            iface: Interface labeling
        '''
        @scope = new PaperDraw
        @connections = []
        @manager = new SchemaManager
            ..register this
        if @data.netlist
            @load!

    name: ~
        -> @data.name

    load: (data) !->
        if data
            @data = data
        # compile schematic: format: {netlist, bom}
        @connections.length = 0
        for trace-id, conn of @data.netlist
            # TODO: performance improvement:
            # use find-comp for each component only one time
            @connections.push <| conn
                .split /[,\s]+/
                .map (.split '.')
                .map (x) ->
                    src = x.join '.'
                    comp = find-comp(x.0)
                    pad = comp?.get {pin: x.1}

                    if empty pad
                        throw new Error "No such pad found: #{src}"
                    return {src, pad, c: comp}

    guide-for: (src) ->
        for @connections when find (.src is src), ..
            @create-guide ..0.pad.0, ..1.pad.0

    guide-all: ->
        for @connections
            console.log "creating guide for: ", ..
            @create-guide ..0.pad.0, ..1.pad.0

    create-guide: (pad1, pad2) ->
        new @scope.Path.Line do
            from: pad1.g-pos
            to: pad2.g-pos
            stroke-color: 'lime'
            selected: yes
            data: {+tmp}
