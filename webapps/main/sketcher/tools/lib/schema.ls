require! './find-comp': {find-comp}
require! 'prelude-ls': {find, empty}
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
        @connections = []
        @manager = new SchemaManager
            ..register this

        if data.netlist and data.bom
            @compile!

    name: ~
        -> @data.name

    compile: (data) !->
        if data
            @data = data

        # add needed footprints
        @add-footprints!

        # compile schematic: format: {netlist, bom}
        @connections.length = 0
        for trace-id, conn-list of @data.netlist
            # TODO: performance improvement:
            # use find-comp for each component only one time
            conn = for p-name in text2arr conn-list
                [name, pin] = p-name.split '.'
                comp = find-comp name
                pad = (comp?.get {pin}) or []
                if empty pad
                    throw new Error "No such pad found: #{p-name}"
                {src: p-name, c: comp, pad}

            @connections.push conn

        # place all guides
        @guide-all!

    add-footprints: ->
        pos = null
        curr = @scope.get-components {exclude: <[ Trace ]>}
        for type, names of @data.bom
            for c in text2arr names
                if c not in [..name for curr]
                    console.log "Component #{c} is missing (type: #{type})"
                    _Component = getClass(type)
                    comp = new _Component {name: c}
                    if pos
                        comp.position = pos.add [50, 50]
                    pos = comp.position
                else
                    existing = find (.name is c), curr
                    if type isnt existing.type
                        console.log "Component #{c} exists,
                        but its type (#{existing.type})
                        is wrong, should be: #{type}"



    guide-for: (src) ->
        for @connections when find (.src is src), ..
            @create-guide ..0.pad.0, ..1.pad.0

    guide-all: ->
        for @connections
            #console.log "creating guide for: ", ..
            @create-guide ..0.pad.0, ..1.pad.0

    create-guide: (pad1, pad2) ->
        new @scope.Path.Line do
            from: pad1.g-pos
            to: pad2.g-pos
            stroke-color: 'lime'
            selected: yes
            data: {+tmp, +guide}

    clear-guides: ->
        for @scope.project.layers
            for ..getItems {-recursive} when ..data.tmp and ..data.guide
                ..remove!
