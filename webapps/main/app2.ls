try
    require! 'aea/defaults'
    require! 'components'

    # App scenes
    require! './terminal-block'
    require! './sketcher'
    require! './webcad'

    new Ractive do
        el: \body
        template: RACTIVE_PREPARSE('app.pug')
        onrender: ->
            <~ getDep "js/app3.js"
            # send signal to Async Synchronizers
            @set "@shared.deps", {_all: yes}, {+deep}

catch
    loadingError (e.stack or e)
