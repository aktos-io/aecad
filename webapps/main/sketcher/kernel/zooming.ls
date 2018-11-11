changeZoom = (oldZoom, delta) ->
      factor = 1.05
      if delta < 0
        return oldZoom / factor
      if delta > 0
        return oldZoom * factor
      oldZoom

changeZoomPointer = (oldZoom, delta, c, p) ->
  newZoom = changeZoom oldZoom, delta
  beta = oldZoom / newZoom
  pc = p.subtract c
  a = p.subtract(pc.multiply(beta)).subtract c
  [newZoom, a]

export paperZoom = (scope, jQEvent) ->
    mousePosition = new scope.Point jQEvent.offsetX, jQEvent.offsetY
    viewPosition = scope.view.viewToProject(mousePosition)
    [newZoom, offset] = changeZoomPointer scope.view.zoom, jQEvent.deltaY, scope.view.center, viewPosition
    scope.view.zoom = newZoom
    scope.view.center = scope.view.center.add offset
    jQEvent.preventDefault()
