require! 'aea': {create-download}
require! './ractive-trace'
require! './ractive-drag'


handle = Ractive.extend do
    template: RACTIVE_PREPARSE('handle.pug')
    onrender: ->
        @set \position.left, (@get \x) / 0.26
        @set \position.top, (@get \y) / 0.26
    data: ->
        position: {top: 0, left: 0}

cpad = Ractive.extend do
    template: RACTIVE_PREPARSE('cpad.pug')
    components: {handle}

bga = Ractive.extend do
    template: RACTIVE_PREPARSE('bga.pug')
    components: {cpad}
    data: ->
        edgePins: 4
        circleCount: 2
        pinDistance: 5
        radius: 2
        position: {top: 0, left: 0}

rpad = Ractive.extend do
    template: RACTIVE_PREPARSE('rpad.pug')

wire = Ractive.extend do
    template: RACTIVE_PREPARSE('wire.pug')


Ractive.components['pcb'] = Ractive.extend do
    template: RACTIVE_PREPARSE('index.pug')
    on:
        download: (ctx) ->
            pcb = @find \#pcb
            # thanks to Joseph, https://gitter.im/ractivejs/ractive?at=5a44af8029ec6ac31190d2ee
            create-download 'pcb.svg', pcb.outerHTML

    components: {bga}
