require! 'svgson'

export svgson-to-svg = (sson) ->
    svgson.stringify sson, do
        transformAttr: (key, value, escape) ->
            switch key
            | 'data-paper-data' =>
                "#{key}='#{escape JSON.stringify value}'"
            |_ =>
                "#{key}='#{escape value}'"
