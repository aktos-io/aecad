require! paper
paper.install window
require! 'aea': {create-download}

Ractive.components['sketcher'] = Ractive.extend do
    template: RACTIVE_PREPARSE('index.pug')
    onrender: ->
        canvas = @find '#draw'
        paper.setup canvas
        path = new paper.Path();
        path.strokeColor = 'black';
        start = new paper.Point(100, 100);
        path.moveTo(start);
        path.lineTo(start.add([ 200, -50 ]));
        paper.view.draw();

        line-tool = new paper.Tool!
            ..onMouseDrag = (event) ~>
                path.add(event.point);

        @on do
            exportSVG: (ctx) ~>
                svg = paper.project.exportSVG {+asString}
                create-download "myexport.svg", svg
