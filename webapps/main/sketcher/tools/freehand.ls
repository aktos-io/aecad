export Freehand = (scope, layer) ->
    # pcb is the scope
    pcb = scope
    gui = layer

    path = null
    freehand = new pcb.Tool!
        ..onMouseDrag = (event) ~>
            path.add(event.point);

        ..onMouseDown = (event) ~>
            gui.activate!
            path := new pcb.Path();
            path.strokeColor = 'black';
            path.add(event.point);
