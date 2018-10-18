require! 'prelude-ls': {empty}

export SelectTool = (scope, layer) ->
    # http://paperjs.org/tutorials/project-items/transforming-items/

    cache =
        selected: []
        dragging: null
        last-drag-point: null

    deselect-all = ->
        for cache.selected
            ..selected = no

        cache
            ..selected = []
            ..dragging = null
            ..pan = no

    select-tool = new scope.Tool!
        ..onMouseDrag = (event) ~>
            # panning
            if event.modifiers.shift
                offset = event.downPoint .subtract event.point
                scope.view.center = scope.view.center .add offset


        ..onMouseUp = (event) ~>
            cache.dragging = null
            cache.pan = no

        ..onMouseDown = (event) ~>
            layer.activate!
            deselect-all!

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
            # delete an item with Delete key
            if event.key is \delete
                for i in [til cache.selected.length]
                    item = cache.selected.pop!
                    if item.recache!
                        console.log ".........deleted: ", item
                    else
                        console.error "couldn't recache item: ", item
                        cache.selected.push item

                unless empty cache.selected
                    console.error "Why didn't we erase those selected items?: ", cache.selected
                    debugger

            # Press Esc to cancel a cache
            if (event.key is \escape) and cache.dragging?
                for cache.selected
                    ..position.set (..position .subtract cache.dragging)
                deselect-all!

    {select-tool}
