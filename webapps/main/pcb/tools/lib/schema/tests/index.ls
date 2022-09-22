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
        make-tests "schema-simple", simple 
        make-tests "schema-errors", errors 
        make-tests "schema-unused", unused 
        make-tests "schema-parametric", parametric 
        PaperDraw.instance.remove-layer \testing
        sm = new SchemaManager
            ..clear!
        handler!
    catch
        handler e
