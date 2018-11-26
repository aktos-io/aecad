require! 'dcs/lib/test-utils': {make-tests}
require! './simple'
require! './errors'
require! './unused'

tests = ->
    make-tests "schema", {
        simple, errors, unused
    }

export schema-tests = (handler) ->
    try
        tests!
        handler!
    catch
        handler e
