export script =
    "lib":
        '''
        mm2px = ( / 25.4 * 96)
        px2mm = (x) -> 1 / mm2px(x)
        P = (x, y) -> new Point (x |> mm2px), (y |> mm2px)
        S = (a, b) -> new Size (a |> mm2px), (b |> mm2px)

        pad = (width, height, position=P(10mm, 10mm)) ->
            p = new Rectangle position, S(width, height)
            pad = new Path.Rectangle p
                ..fillColor = 'black'
                ..rect = p
                ..data.project = {layer: 'scripting'}
            pad

        
        '''
    "LM 2576":
        '''
        mm2px = ( / 25.4 * 96)
        px2mm = (x) -> 1 / mm2px(x)
        P = (x, y) -> new Point (x |> mm2px), (y |> mm2px)
        S = (a, b) -> new Size (a |> mm2px), (b |> mm2px)

        pad = (width, height, position=P(10mm, 10mm)) ->
            p = new Rectangle position, S(width, height)
            pad = new Path.Rectangle p
                ..fillColor = 'black'
                ..rect = p
                ..data.project = {layer: 'scripting'}
            pad

        do ->
            # From: http://www.ti.com/lit/ds/symlink/lm2576.pdf
            H = 14.17mm
            d1 = {w: 8mm, h: 10.8mm}
            d2 = {w: 2.16mm, h: 1.07mm}
            pd = 1.702mm

            _x = H - d1.w - d2.w/2

            p1 = pad d1.w, d1.h
            p2 = pad d2.w, d2.h, new Point(\
                p1.bounds.right + (_x |> mm2px), \
                p1.bounds.center.y - d2.w / 2)

            p3 = p2.clone!
                ..position.y += pd |> mm2px

            p4 = p3.clone!
                ..position.y += pd |> mm2px

            p5 = p2.clone!
                ..position.y -= pd |> mm2px

            p6 = p5.clone!
                ..position.y -= pd |> mm2px
        '''
