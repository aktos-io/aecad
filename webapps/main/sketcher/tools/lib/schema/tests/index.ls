require! 'dcs/lib/test-utils': {make-tests}
require! './simple'
require! './errors'
require! './unterminated'

tests = ->
    make-tests "schema", {
        simple, errors, unterminated
    }

export schema-tests = (handler) ->
    try
        tests!
        handler!
    catch
        handler e
