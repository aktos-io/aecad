try
    require! 'aea/defaults'
    require! 'components'
    require! './terminal-block'
    new Ractive do
        el: \body
        template: RACTIVE_PREPARSE('app.pug')
        on:
            complete: ->
                <~ getDep "js/app3.js"
                # send signal to Async Synchronizers
                @set "@shared.deps", {_all: yes}, {+deep}

catch
    loadingError (e.stack or e)
