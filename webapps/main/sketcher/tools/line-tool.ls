export LineTool = (scope) ->
    path = null

    freehand = new scope.Tool!
        ..onMouseDown = (event) ~>
            scope.use-layer \gui
            unless path
                path := new scope.Path(event.point);
                path.strokeColor = 'white';
            path.add(event.point);

        ..onMouseMove = (event) ->
            path?.segments[*-1].point = event.point

        ..onKeyDown = (event) ~>
            switch event.key
            | \escape =>
                # Press Esc to cancel a cache
                path?.segments[*-1].remove! # remove last segment
                path := null
