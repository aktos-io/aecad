require! 'dcs/lib/test-utils': {make-tests}
require! './simple'
require! './errors'
require! './unused'
require! './parametric'
require! '../schema-manager': {SchemaManager}
require! '../../../../kernel': {PaperDraw}

export schema-tests = (handler) ->
    try
        PaperDraw.instance.use-layer \testing
        make-tests "schema", simple 
        make-tests "schema", errors 
        make-tests "schema", unused 
        make-tests "schema", parametric 
        PaperDraw.instance.remove-layer \testing
        sm = new SchemaManager
            ..clear!
        handler!
    catch
        handler e
