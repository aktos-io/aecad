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
        @active-schema = null
        @using = null

    register: (schema) ->
        name = schema.name
        unless name
            throw new Error "Schema must have a name."

        # auto activate last defined parent schema
        unless schema.parent
            @active-schema = name

        if name of @schemas
            console.log "Updating schema: #{name}"
            @schemas[name] = null
            delete @schemas[name]
        else
            console.log "Adding new schema: #{name}"

        @schemas[name] = schema

    curr: ~
        -> @active

    active: ~
        -> @schemas[@using or @active-schema]


    use: (name) ->
        @using = name
        unless @curr.compiled
            @curr.compile!
