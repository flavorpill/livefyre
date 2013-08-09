// Generated by CoffeeScript 1.6.3
(function() {
  var cookie, defaultDelegate, load, utils, _initialized;

  defaultDelegate = function(options) {
    var authDelegate, k, v, _ref;
    authDelegate = new fyre.conv.RemoteAuthDelegate();
    _ref = options.auth;
    for (k in _ref) {
      v = _ref[k];
      authDelegate[k] = v;
    }
    return authDelegate;
  };

  load = null;

  (function() {
    var fjs, __loadedScripts;
    __loadedScripts = [];
    fjs = null;
    return load = function(source, id, options) {
      var js, k, v;
      if (document.getElementById(id)) {
        return;
      }
      if (__loadedScripts[id]) {
        return;
      }
      __loadedScripts[id] = true;
      if (!fjs) {
        fjs = document.getElementsByTagName('script')[0];
      }
      js = document.createElement("script");
      js.id = id;
      js.async = true;
      js.src = source;
      if (options) {
        for (k in options) {
          v = options[k];
          js[k] = v;
        }
      }
      fjs.parentNode.insertBefore(js, fjs);
      return js;
    };
  })();

  cookie = function(token) {
    var m;
    m = document.cookie.match(new RegExp(token + "=([^;]+)"));
    if (m) {
      return m[1];
    } else {
      return null;
    }
  };

  utils = function(options) {
    var obj;
    return obj = {
      load: load,
      startLogin: function(url, width, height, callback, windowName) {
        var left, popup, top;
        if (width == null) {
          width = 600;
        }
        if (height == null) {
          height = 400;
        }
        if (callback == null) {
          callback = null;
        }
        if (windowName == null) {
          windowName = null;
        }
        left = (screen.width / 2) - (width / 2);
        top = (screen.height / 2) - (height / 2);
        popup = window.open(url, windowName, "menubar=no,toolbar=no,status=no,width=" + width + ",height=" + height + ",toolbar=no,left=" + left + ",top=" + top);
        this.finishCallback = callback;
        return this.startLoginPopup(popup);
      },
      startLoginPopup: function(popup) {
        var _this = this;
        this.tries = 0;
        this.popup = popup;
        return this.timer = setInterval(function() {
          return _this.__checkLogin();
        }, 100);
      },
      __checkLogin: function() {
        var err, token;
        token = cookie(options.cookie_name || "livefyre_utoken");
        if (token && this.timer) {
          clearInterval(this.timer);
          if (this.popup) {
            this.popup.close();
          }
          this.popup = null;
          this.timer = null;
          if (this.finishCallback) {
            this.finishCallback();
          }
          return window.fyre.conv.login(token);
        } else if (this.popup && this.popup.closed) {
          try {
            this.tries += 1;
            if (this.tries > 30) {
              clearInterval(this.timer);
              this.timer = null;
              return this.popup = null;
            }
          } catch (_error) {
            err = _error;
          }
        }
      }
    };
  };

  _initialized = false;

  this.initLivefyre = function(options) {
    var e, element, returnable;
    if (_initialized && !options.force) {
      throw "Livefyre has already been initialized";
    }
    _initialized = true;
    e = document.getElementById(options.element_id || "livefyre_comments");
    if (e) {
      options.config || (options.config = {
        checksum: e.getAttribute("data-checksum"),
        collectionMeta: e.getAttribute("data-collection-meta"),
        articleId: e.getAttribute("data-article-id"),
        siteId: e.getAttribute("data-site-id"),
        postToButtons: JSON.parse(e.getAttribute("data-post-to-buttons")),
        el: e.id
      });
      options.network || (options.network = e.getAttribute("data-network"));
      options.domain || (options.domain = e.getAttribute("data-domain"));
      options.root || (options.root = e.getAttribute("data-root"));
      returnable = utils(options);
      this.FYRE_LOADED_CB = function() {
        var opts;
        if (options.preLoad) {
          options.preLoad(fyre);
        }
        opts = {
          network: options.network,
          authDelegate: options.delegate || defaultDelegate(options)
        };
        console.log(options.config);
        return fyre.conv.load(opts, [options.config], function(widget) {
          var error, token;
          returnable.widget = widget;
          token = cookie(options.cookie_name || "livefyre_utoken");
          if (token) {
            try {
              return fyre.conv.login(token);
            } catch (_error) {
              error = _error;
              if (window.console) {
                return window.console.log("Error logging in:", e);
              }
            }
          }
        });
      };
      if (!options.manualLoad) {
        element = load("http://" + options.root + "/wjs/v3.0/javascripts/livefyre.js", null, {
          "data-lf-domain": options.network
        });
      }
      return returnable;
    } else {
      return null;
    }
  };

}).call(this);
