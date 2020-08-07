require! 'svgson'

export svgson-to-svg = (sson) ->
    svgson.stringify sson, do
        transformAttr: (key, value, escape) ->
            switch key
            | 'data-paper-data' =>
                "#{key}='#{escape JSON.stringify value}'"
            | 'data' => 
                if typeof! value is \Object 
                    "#{key}='#{escape JSON.stringify value}'"
                else
                    "#{key}='#{escape value}'"                
            |_ =>
                "#{key}='#{escape value}'"
