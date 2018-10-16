export Freehand = (scope, layer) ->
    path = null
    freehand = new scope.Tool!
        ..onMouseDrag = (event) ~>
            path.add(event.point);

        ..onMouseDown = (event) ~>
            layer.activate!
            path := new scope.Path();
            path.strokeColor = 'black';
            path.add(event.point);
