require! 'dcs/lib/test-utils': {make-tests}
require! './sgw-example'
require! './simple'
require! './errors'

tests = ->
    make-tests "schema", {
        simple, sgw-example, errors
    }

export schema-tests = (handler) ->
    try
        tests!
        handler!
    catch
        handler e
