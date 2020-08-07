Ractive.components['terminal-block'] = Ractive.extend do
    template: require('./index.pug')
    data: ->
        sofar: 0
        cumulative: (index) ->
            switch index
            | 0 => 0
            | 1 => 80

        terminal-groups:
            xg1:
                "motor1.L": null
                "motor1.N": null
                "led1.Q1": null
                "led1.GND": null
            xg2:
                'remote.inp1': null
                'remote.inp2': null
                'remote.inp3': null
