export MoveTool = (scope, layer) ->
    # http://paperjs.org/tutorials/project-items/transforming-items/

    cache =
        selected: []

    move-tool = new scope.Tool!
        ..onMouseDrag = (event) ~>
            for cache.selected
                ..position = event.point

        ..onMouseDown = (event) ~>
            layer.activate!
            hit = scope.project.hitTest event.point
            console.warn "Hit: ", hit
            for cache.selected => ..selected = no
            cache.selected = []
            if hit?item
                that.selected = yes
                cache.selected.push that
