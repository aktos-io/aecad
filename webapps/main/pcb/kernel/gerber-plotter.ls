remove-bash-comments = (.replace /\s*#.*$/mg, '')

export class GerberLayerReducer
    -> 
        @reset! 
        
    reset: -> 
        @apertures = {} # key: geometry, value: aperture id
        @format = "LAX35Y35"
        @aperture-id = 10
        @unit = 'MM'
        @gerber-start = """
            G04 project-name*               # comment 
            %FS#{@format}*%                 # set number format
            %MOMM*%                         # set units to MM
            """
        @gerber-end = """
            M02*                            # End of file 
            """

        @gerber-parts = []

    append: (data) -> 
        # append a gerber drawing
        if data 
            gdata = data |> remove-bash-comments
            #console.log "orig gerber data is:"
            #console.log gdata
            
            # ignore anything after M02*
            gdata = gdata.replace /M02\*[^^]*/, ''

            # enumerate the aperture definitions from the beginning
            aperture-replace = {}
            gdata = gdata.replace /^%ADD([1-9][0-9])(.+)\*%/gm, (orig, id, geometry) ~>
                #console.log "examining aperture D#{id} = #{geometry}"
                if geometry of @apertures
                    existing-id = @apertures[geometry]
                    #console.log "already defined", @apertures
                    if existing-id is id 
                        # this geometry is already defined with the same id
                        return ''
                    else 
                        # same geometry exists with different id
                        aperture-replace[id] = existing-id
                        return ''
                else 
                    new-id = @aperture-id++
                    @apertures[geometry] = new-id
                    aperture-replace[id] = new-id
                    #console.log "enumerate new id: #{new-id}"
                    return "%ADD#{new-id}#{geometry}*%"

            gdata = gdata.replace /^%MO([^*]+)\*%$/gm, ~> 
                if arguments.1 isnt @unit
                    throw "Not in the same unit: #{arguments.1}"
                else
                    return '' 


            gdata = gdata.replace /^%FS([^*]+)\*%$/gm, ~> 
                if arguments.1 isnt @format 
                    throw "Not in the same format: #{arguments.1}"
                else 
                    return '' 

            # replace aperture ids
            for _old, _new of aperture-replace
                continue if "#{_old}" is "#{_new}" 
                reg = new RegExp "^D#{_old}\\*", 'gm'
                gdata = gdata.replace reg, "D#{_new}*"

            # remove unnecessary newlines
            gdata = gdata.replace /\n+\s*\n+/gm, "\n"

            @gerber-parts.push gdata 

    export: -> 
        """
        #{@gerber-start |> remove-bash-comments}
        #{@gerber-parts.join '\n'}
        #{@gerber-end |> remove-bash-comments}
        """

export class GerberReducer # Singleton
    '''
    This is a singleton class where any aeObj will use to send 
    its Gerber data. 

    The data is registered into its relevant GerberLayerReducer.
    '''
    @extension =  
        # Suggested extensions from: https://github.com/aktos-io/aecad/issues/52
        "F.Cu"      : "GTL"
        "B.Cu"      : "GBL"
        "drill"     : "XLN"
        "Cut.Edge"  : "GKO"
        "F.Mask"    : "GTS"
        "B.Mask"    : "GBS"
        "F.Silk"    : "GTO"
        "B.Silk"    : "GBO"

    @instance = null
    ->
        return @@instance if @@instance
        @@instance = this
        @reducers = {} # {layer: {side: Reducer, ...}, ...}

    reset: !-> 
        for layer, sides of @reducers 
            for side, reducer of sides 
                reducer.reset!
        @drills = {}

    append: ({layer, side, gerber}) -> 
        '''
        layer   : 
            Required: Physical Layer. One of: 

                * Cu (Copper layer)
                * Mask (Solder Mask) 
                * Silk  (Names, values, outlines)
                * Paste (Solder Paste)
                * Edge (Mechanical Layer)

        side    : 
            Required. One of: 

                * "B" (for Back)
                * "F" (for Front)
                * null (for "Symmetric")

        gerber  : Gerber data 


        Usage: 

            .append {layer: "Cu", gerber: data}
            .append {layer: "Mask", side: "F", gerber: data}

        '''
        sides = if layer is \Edge 
            <[ Cut ]>
        else 
            if side then [side] else <[ F B ]>

        for _side in sides  
            @reducers{}[layer]{}[_side] ?= new GerberLayerReducer
                ..append gerber 
 
    add-drill: (dia, coord) -> 
        @drills[][dia.to-fixed 1].push coord 

    export-excellon: -> 
        # https://web.archive.org/web/20071030075236/http://www.excellon.com/manuals/program.htm
        tool-table = {}
        for index, dia of Object.keys @drills
            tool-table[index+1] = dia 

        excellon-start = """
            M48
            FMAT,2
            METRIC,TZ
            #{[ "T#{i}C#{dia}" for i, dia of tool-table].join '\n'}
            %
            G90
            G05
            M71
            """

        excellon-job = []
        for tool-index, dia of tool-table 
            excellon-job.push "T#{tool-index}"
            for @drills[dia]
                excellon-job.push "X#{..x}Y#{..y}"

        excellon-end = """
            M30
            """

        return """
            #{excellon-start}
            #{excellon-job.join '\n'}
            #{excellon-end}
            """
   
    export: -> 
        output = {}
        for layer, sides of @reducers
            for side, reducer of sides 
                output["#{side}.#{layer}"] = 
                    content: reducer.export!
                    ext: @@extension["#{side}.#{layer}"] or "gbr"

        output["drill"] = 
            content: @export-excellon!
            ext: @@extension["drill"]

        return output

