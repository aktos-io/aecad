export Freehand = (scope) ->
    path = null

    freehand = new scope.Tool!
        ..onMouseDrag = (event) ~>
            path.add(event.point);

        ..onMouseDown = (event) ~>
            scope.use-layer \gui
            scope.history.commit!
            path := new scope.Path();
            path.strokeColor = 'white';
            path.add(event.point);
