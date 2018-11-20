require! 'prelude-ls': {round}

export class Line
    '''
    Documentation: https://github.com/paperjs/paper.js/issues/1589#issuecomment-434655245
    '''
    (opts, @paper) ->
        @p1 = new @paper.Point(opts.p1)
        @p2 = new @paper.Point(opts.p2 or (@p1.add new @paper.Point(100, 0)))
        if opts.rotate
            @p2.set @p2.rotate that, @p1

        @_line = new @paper.Line(@p1, @p2)
        @opts = opts  # backup the options for later use

    move: (delta1, delta2) ->
        # delta1: delta for p1
        # delta2: delta for p2
        unless delta2
            # move by keeping the angle intact
            delta2 = delta1

        @p1.set @p1.add delta1
        @p2.set @p2.add delta2
        @_line = new @paper.Line(@p1, @p2)

    through: (point) ->
        # make this line go through the point
        @move point.subtract @p1

    intersect: (other-line) ->
        @_line.intersect other-line._line, true

    get-angle: ->
        @_line.vector.angle

    rotate: (degree, opts={}) ->
        rotation = degree
        if opts.absolute
            rotation = degree - @_line.vector.angle
        if opts.round
            round-diff = @_line.vector.angle - round @_line.vector.angle
            rotation -= round-diff

        _p2 = @p2.rotate rotation, @p1
        if opts.inplace
            @p2.set _p2

            # TODO: Reuse the paper.Line instance
            @_line = new @paper.Line @p1, @p2
            return this
        else
            return new Line {p1: @p1, p2: _p2}, @paper
