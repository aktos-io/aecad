try
    require! 'aea/defaults'
    require! 'components'

    # App scenes
    require! './terminal-block'
    require! './webcad'
    require! './pcb'

    new Ractive do
        el: \body
        template: require('./app.pug')
        data:
            dependencies: require('app-version.json')
        onrender: ->
            <~ getDep "js/app3.js"
            # send signal to Async Synchronizers
            @set "@shared.deps", {_all: yes}, {+deep}

catch
    loadingError (e.stack or e)
