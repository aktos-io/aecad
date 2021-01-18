add-class class RefCross extends Footprint
    create: (data) ->
        @side = "Edge"
        @send-to-layer "gui"
        @add-part 'v', new Path.Line do
            from: [-20, 0]
            to: [20, 0]
            stroke-color: \white
            parent: @g

        @add-part 'h', new Path.Line do
            from: [0, -20]
            to: [0, 20]
            stroke-color: \white
            parent: @g

        @set-data 'helper', yes

    print-mode: (val) ->
        @g.stroke-color = 'black'


#new RefCross