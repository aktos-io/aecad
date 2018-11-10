export _default =
    set-helpers: (point) ->
        @remove-helpers!

        @helpers.x = new @scope.Path.Line helper-opts =
                from: [-1000, point.y]
                to: [1000, point.y]
                data: {+tmp}
                strokeWidth: 0.5
                strokeColor: \white
                opacity: 0.4
                dashArray: [5, 1, 1, 1]
        @helpers.y = @helpers.x.clone!
            ..rotate 90, point
        @helpers.s = @helpers.x.clone!
            ..rotate 45, point
        @helpers.bs = @helpers.x.clone!
            ..rotate -45, point

        @helpers-subs = @scope.on-zoom {width: 1}, (val) ~>
            console.log "Updating helpers width: ", val.width
            for n, helper of @helpers
                helper.stroke-width = val.width

        # visualize intersections
        for axis in <[ x y ]>
            for axis2 in <[ s bs ]>
                @helpers["#{axis}-#{axis2}"] = new @scope.Path.Circle do
                    center: point
                    radius: 3
                    stroke-color: \yellow
                    opacity: 0

    remove-helpers: ->
        for h, p of @helpers
            p.remove!
        @helpers-subs?.remove!

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
