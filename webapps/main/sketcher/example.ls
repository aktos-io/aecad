export script = '''
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
    H = 16.02mm
    d1 = {w: 8.38mm, h: 10.66mm}
    d2 = {w: 3.05mm, h: 1.016mm}
    pd = 1.702mm

    _x = H - d1.w - d2.w

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
