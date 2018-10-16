require! 'prelude-ls': {empty}

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

        ..onKeyDown = (event) ~>
            if event.key is \delete
                # FIXME: It's interesting to be forced to re-check
                # cache.selected array.
                for i in [til cache.selected.length]
                    item = cache.selected.pop!
                    if item.remove!
                        console.log ".........deleted: ", item
                    else
                        console.error "couldn't remove item: ", item
                        cache.selected.push item

                unless empty cache.selected
                    console.error "Why didn't we erase those selected items?: ", cache.selected
                    debugger

    {move-tool, cache}
