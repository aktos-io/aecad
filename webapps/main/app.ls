try
    require! 'app/tools'
    duration = (diff) ->
        "#{oneDecimal diff / 1000}s"

    t0 = Date.now!
    loadingMessage "Getting vendor2.css (1/3) (#{duration t0 - appStart})"
    <~ getDep "css/vendor2.css"
    t1 = Date.now!
    loadingMessage "Getting vendor2.js (2/3) (#{duration t1 - appStart})"
    <~ getDep "js/vendor2.js"
    t2 = Date.now!
    loadingMessage "Getting app2.js (3/3) (#{duration t2 - appStart})"
    <~ getDep "js/app2.js"
    t3 = Date.now!
    loadingMessage "Rendering... (#{duration t3 - appStart})"
catch
    loadingError (e.stack or e)
