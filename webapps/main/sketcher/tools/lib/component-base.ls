require! 'dcs/lib/keypath': {get-keypath, set-keypath}
require! '../../kernel': {PaperDraw}

# basic methods that every component should have
export class ComponentBase
    ->
        @scope = new PaperDraw

    set-data: (keypath, value) ->
        set-keypath @g.data.aecad, keypath, value

    get-data: (keypath) ->
        get-keypath @g.data.aecad, keypath

    send-to-layer: (layer-name) ->
        @g `@scope.send-to-layer` layer-name
