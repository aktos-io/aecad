export _default = 
    set-helpers: (point) ->
        @remove-helpers!

        helper-opts =
            from: point
            to: point
            data: {+tmp}
            strokeWidth: 1
            strokeColor: \blue
            opacity: 0.8
            dashArray: [10, 4]

        for axis in <[ x y s bs ]>
            @helpers[axis] = new @scope.Path.Line helper-opts


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
                        ..x = point.x
                        ..y = -1000
                    ..lastSegment.point
                        ..x = point.x
                        ..y = 1000
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
