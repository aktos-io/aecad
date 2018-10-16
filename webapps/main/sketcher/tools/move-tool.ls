export MoveTool = (scope, layer) ->
    # http://paperjs.org/tutorials/project-items/transforming-items/

    cache =
        selected: []

    move-tool = new scope.Tool!
        ..onMouseDrag = (event) ~>
            for cache.selected
                ..position
                    ..x += event.delta.x
                    ..y += event.delta.y

        ..onMouseDown = (event) ~>
            layer.activate!
            for cache.selected => ..selected = no
            cache.selected = []

            hit = scope.project.hitTest event.point
            if hit?item
                that.selected = yes
                cache.selected.push that
                console.warn "Hit: ", hit

                if @get \selectAllLayer
                    all = hit.item.getLayer().children
                    console.log "...will select all items in current layer", all
                    all.for-each (.selected = yes)
                    cache.selected = all


    {move-tool, cache}
