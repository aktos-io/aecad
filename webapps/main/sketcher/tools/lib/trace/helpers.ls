export helpers =
    set-helpers: (point) ->
        @remove-helpers!
        hide-slashes = yes

        @helpers.x = new @scope.Path.Line helper-opts =
                from: [-1000, point.y]
                to: [1000, point.y]
                data: {+tmp}
                strokeWidth: 0.5
                strokeColor: \white
                opacity: 0.3
                dashArray: [5, 1, 1, 1]
        @helpers.y = @helpers.x.clone!
            ..rotate 90, point
        @helpers.s = @helpers.x.clone!
            ..rotate 45, point
            ..opacity = 0 if hide-slashes
        @helpers.bs = @helpers.x.clone!
            ..rotate -45, point
            ..opacity = 0 if hide-slashes

        # visualize intersections
        # FIXME: We use these for another reason, so we can't remove them. Find
        # the usage
        for axis in <[ x y ]>
            for axis2 in <[ s bs ]>
                @helpers["#{axis}-#{axis2}"] = new @scope.Path.Circle do
                    center: point
                    radius: 2
                    stroke-color: \yellow
                    opacity: 0
                    data: {+tmp}

        @helpers-subs = @scope.on-zoom (norm, heartbeat) ~>
            for n, helper of @helpers
                helper.stroke-width = 1 * norm
                helper.dash-array = [8, 2, 2, 2].map (* norm)

            for a1 in <[ x y ]>
                for a2 in <[ s bs ]>
                    @helpers["#{a1}-#{a2}"].radius = 2 * norm

            heartbeat!
        console.log "zoom handler registered by set-helpers: ", @helpers-subs.id


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
