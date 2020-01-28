remove-bash-comments = (.replace /\s*#.*$/mg, '')

export class GerberPlotter

export class GerberReducer
    @instance = null
    ->
        # Make this class Singleton
        return @@instance if @@instance
        @@instance = this

    reset: -> 
        @apertures = {} # key: geometry, value: aperture id
        @format = "LAX25Y25"
        @aperture-id = 10
        @unit = 'MM'
        @gerber-start = """
            G04 project-name*               # comment 
            %FSLAX25Y25*%                   # set number format to 2.5
            %MOMM*%                         # set units to MM
            """
        @gerber-end = """
            M02*                            # End of file 
            """

        @gerber-parts = []

    append: (layer, data) -> 
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