defaultDelegate = (options) ->
  authDelegate = new fyre.conv.RemoteAuthDelegate()
  authDelegate[k] = v for k, v of options.auth
  authDelegate

load = null
(->
  __loadedScripts = []
  fjs = null
  load = (source, id, options) ->
    return if (document.getElementById(id))
    return if __loadedScripts[id]
    __loadedScripts[id] = true
    fjs = document.getElementsByTagName('script')[0] unless fjs
    js = document.createElement("script")
    js.id = id
    js.async = true
    js.src = source
    js[k] = v for k, v of options if options

    fjs.parentNode.insertBefore(js, fjs)
    js
)()

cookie = (token) ->
  m = document.cookie.match(new RegExp(token + "=([^;]+)"))
  if m then m[1] else null

utils = (options) ->
  obj =
    load: load
    # At some point, callback should move to the last param
    # keeping this order for backwards compat for now.
    startLogin: (url, width = 600, height = 400, callback = null, windowName = null) ->
      left = (screen.width / 2) - (width / 2)
      top = (screen.height / 2) - (height / 2)
      popup = window.open url, windowName, "menubar=no,toolbar=no,status=no,width=#{width},height=#{height},toolbar=no,left=#{left},top=#{top}"
      @finishCallback = callback
      @startLoginPopup(popup)

    startLoginPopup: (popup) ->
      @tries = 0
      @popup = popup
      @timer = setInterval(=>
        @__checkLogin()
      , 100)

    __checkLogin: ->
      token = cookie(options.cookie_name || "livefyre_utoken")

      if token and @timer
        clearInterval(@timer)
        @popup.close() if @popup
        @popup = null
        @timer = null
        @finishCallback() if @finishCallback
        window.fyre.conv.login(token)
      else if @popup and @popup.closed
        try
          @tries += 1
          if @tries > 30 # 3 seconds
             clearInterval(@timer)
             @timer = null
             @popup = null
        catch err

_global_options = null

fill_element_config = (element, config) ->
  e = document.getElementById(element)
  if e
    config ||=
      checksum: e.getAttribute("data-checksum")
      collectionMeta: e.getAttribute("data-collection-meta")
      articleId: e.getAttribute("data-article-id")
      siteId: e.getAttribute("data-site-id")
      postToButtons: JSON.parse(e.getAttribute("data-post-to-buttons"))
      el: e.id

    config['app'] = e.getAttribute("data-app") if e.getAttribute("data-app")

    _global_options ||=
      network: e.getAttribute("data-network")
      domain: e.getAttribute("data-domain")
      root: e.getAttribute("data-root")

    config
  else
    console.log "Element #{element} was not found"
    null

_initialized = false
@initLivefyre = (options) ->
  if _initialized and !options.force
    throw "Livefyre has already been initialized"
  _initialized = true

  options.elements ||=
    if options.element_id
      [options.element_id]
    else
      ["livefyre_comments"]

  configs =
    if options.config
      [options.config]
    else
      (null for element in options.elements)

  options.element_configs = (fill_element_config element, configs[i] for element, i in options.elements)
  options.element_configs = options.element_configs.filter (element_config) -> element_config isnt null

  return null if options.element_configs.length is 0

  returnable = utils(options)

  options.network = options.network || _global_options.network
  options.root = options.root || _global_options.root
  options.domain = options.domain || _global_options.domain

  @FYRE_LOADED_CB = ->
      options.preLoad(fyre) if options.preLoad
      opts =
        network: options.network
        authDelegate: options.delegate || defaultDelegate(options)

      console.log element for element in options.element_configs
      fyre.conv.load opts, options.element_configs, (widget) ->
        returnable.widget = widget
        token = cookie(options.cookie_name || "livefyre_utoken")
        if token
          try
            fyre.conv.login(token)
          catch error
            window.console.log "Error logging in:", e if window.console

  unless options.manualLoad
    element = load "http://#{options.root}/wjs/v3.0/javascripts/livefyre.js", null, {"data-lf-domain": options.network}
