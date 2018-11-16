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
        unless @curr.compiled
            @curr.compile!
