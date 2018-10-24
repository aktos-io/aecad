export _default =
    set-helpers: (point) ->
        @remove-helpers!

        helper-opts =
            from: [-1000, point.y]
            to: [1000, point.y]
            data: {+tmp}
            strokeWidth: 0.5
            strokeColor: \blue
            opacity: 0.8
            dashArray: [10, 1, 1, 1]

        @helpers.x = new @scope.Path.Line helper-opts
        @helpers.y = @helpers.x.clone!
            ..rotate 90, point
        @helpers.s = @helpers.x.clone!
            ..rotate 45, point
        @helpers.bs = @helpers.x.clone!
            ..rotate -45, point

        for axis in <[ x y ]>
            for axis2 in <[ s bs ]>
                # create intersections
                @helpers["#{axis}-#{axis2}"] = new @scope.Path.Circle do
                    center: point
                    radius: 5
                    stroke-width: 3
                    stroke-color: \green

    remove-helpers: ->
        for h, p of @helpers
            p.remove!

    update-helpers: (point, names=<[ x y s bs ]>) ->
        for name, h of @helpers when name in names
            switch name
            | 'x' =>
                h
                    ..firstSegment.point
                        ..x = -1000
                        ..y = point.y
                    ..lastSegment.point
                        ..x = 1000
                        ..y = point.y
            | 'y' =>
                h
                    ..firstSegment.point
                        ..x = -1000
                        ..y = point.y
                    ..lastSegment.point
                        ..x = 1000
                        ..y = point.y
                    ..rotate(90, point)
            | 's' =>
                h
                    ..firstSegment.point
                        ..x = -1000
                        ..y = point.y
                    ..lastSegment.point
                        ..x = 1000
                        ..y = point.y

                    ..rotate(45, point)
            | 'bs' =>
                h
                    ..firstSegment.point
                        ..x = -1000
                        ..y = point.y
                    ..lastSegment.point
                        ..x = 1000
                        ..y = point.y

                    ..rotate(-45, point)

        for axis in <[ x y ]>
            for axis2 in <[ s bs ]>
                name = "#{axis}-#{axis2}"
                isec = @helpers[axis].getIntersections @helpers[axis2]
                if isec.length > 1
                    console.warn "how come: ", isec
                @helpers[name].position = isec.0?.point
