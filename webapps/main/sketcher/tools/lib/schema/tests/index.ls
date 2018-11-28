require! 'dcs/lib/test-utils': {make-tests}
require! './simple'
require! './errors'
require! './unused'
require! '../schema-manager': {SchemaManager}

tests = ->
    make-tests "schema", {
        simple, errors, unused
    }

export schema-tests = (handler) ->
    try
        tests!
        sm = new SchemaManager
            ..clear!
        handler!
    catch
        handler e
