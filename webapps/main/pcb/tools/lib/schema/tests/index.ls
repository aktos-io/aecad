require! 'dcs/lib/test-utils': {make-tests}
require! './simple'
require! './errors'
require! './unused'
require! './parametric'
require! './unconnected'
require! '../schema-manager': {SchemaManager}

tests = ->
    make-tests "schema", {
        simple, errors, unused, parametric, unconnected
    }

export schema-tests = (handler) ->
    try
        tests!
        sm = new SchemaManager
            ..clear!
        handler!
    catch
        handler e
