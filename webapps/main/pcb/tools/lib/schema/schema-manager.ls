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
        unless schema.name
            throw new Error "Schema must have a name."

        # auto activate last defined parent schema
        unless schema.parent
            @active-schema = schema.name

        action = "Adding new"
        if name of @schemas
            action = "Updating"
            @schemas[name] = null
            delete @schemas[name]

        @schemas[schema.name] = schema

    curr: ~
        -> @active

    active: ~
        -> @schemas[@using or @active-schema]


    use: (name) ->
        @using = name
        unless @curr.compiled
            @curr.compile!

    clear: ->
        # clear all schemas
        for k of @schemas
            delete @schemas[k]
