(function() {
  angular.module('rbs-angular-auth', ['ngStorage', 'rbs-angular-core']);

  angular.module('rbs-angular-auth-ui-router', ['ui.router', 'rbs-angular-auth']);

  angular.module('rbs-angular-auth-samples', ['rbs-angular-auth-samples']);

}).call(this);

(function() {
  (angular.module('rbs-angular-auth')).factory('TokenManager', [
    '$log', '$localStorage', '$rootScope', 'Configuration', function($log, $localStorage, $rootScope, Configuration) {
      var JWT_CLEAR_EVENT, JWT_EXTRACTOR, JWT_INJECTOR, JWT_STORAGE_KEY, JWT_STORE_EVENT, TokenManager;
      JWT_STORAGE_KEY = Configuration.JWT_STORAGE_KEY;
      JWT_STORE_EVENT = Configuration.JWT_STORE_EVENT;
      JWT_CLEAR_EVENT = Configuration.JWT_CLEAR_EVENT;
      JWT_INJECTOR = Configuration.JWT_INJECTOR;
      JWT_EXTRACTOR = Configuration.JWT_EXTRACTOR;
      TokenManager = (function() {
        function TokenManager() {}

        TokenManager.prototype.storeRaw = function(token) {
          if (this.getRaw() !== token) {
            $log.debug('Store JWT token: ', token);
            $localStorage[JWT_STORAGE_KEY] = token;
            return $rootScope.$broadcast(JWT_STORE_EVENT, this, token);
          }
        };

        TokenManager.prototype.getRaw = function() {
          return $localStorage[JWT_STORAGE_KEY];
        };

        TokenManager.prototype.clear = function() {
          var token;
          token = this.getRaw();
          $log.debug('Cleared JWT token: ', token);
          delete $localStorage[JWT_STORAGE_KEY];
          return $rootScope.$broadcast(JWT_CLEAR_EVENT, this, token);
        };

        TokenManager.prototype.inject = function(request, rawToken) {
          JWT_INJECTOR(request, rawToken);
          return request;
        };

        TokenManager.prototype.extract = function(response) {
          return JWT_EXTRACTOR(response);
        };

        return TokenManager;

      })();
      return new TokenManager();
    }
  ]);

}).call(this);

(function() {
  var And, Operator, Or, RuleParser, alt, conjunction, conjunctionNext, disjunction, disjunctionNext, lazy, lexeme, lparen, member, opAnd, opOr, optWhitespace, regex, rparen, rule, seq, string, subrule,
    slice = [].slice,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  Operator = (function() {
    function Operator() {
      var permissions;
      permissions = 1 <= arguments.length ? slice.call(arguments, 0) : [];
      this.permissions = permissions;
    }

    Operator.evalPermission = function(principal, permissionCheck) {
      return function(permission) {
        if (angular.isString(permission)) {
          return permissionCheck(principal, permission);
        } else if (angular.isFunction(permission != null ? permission["eval"] : void 0)) {
          return permission["eval"](principal, permissionCheck);
        }
      };
    };

    return Operator;

  })();

  And = (function(superClass) {
    extend(And, superClass);

    function And() {
      return And.__super__.constructor.apply(this, arguments);
    }

    And.prototype["eval"] = function(principal, permissionCheck) {
      return _.every(this.permissions, Operator.evalPermission(principal, permissionCheck));
    };

    And.prototype.toJSON = function() {
      return {
        "and": this.permissions
      };
    };

    return And;

  })(Operator);

  Or = (function(superClass) {
    extend(Or, superClass);

    function Or() {
      return Or.__super__.constructor.apply(this, arguments);
    }

    Or.prototype["eval"] = function(principal, permissionCheck) {
      return _.some(this.permissions, Operator.evalPermission(principal, permissionCheck));
    };

    Or.prototype.toJSON = function() {
      return {
        "or": this.permissions
      };
    };

    return Or;

  })(Operator);

  alt = Parsimmon.alt;

  seq = Parsimmon.seq;

  lazy = Parsimmon.lazy;

  regex = Parsimmon.regex;

  string = Parsimmon.string;

  optWhitespace = Parsimmon.optWhitespace;

  lexeme = function(p) {
    return p.skip(optWhitespace);
  };

  lparen = lexeme(string('('));

  rparen = lexeme(string(')'));

  opOr = lexeme(string('|'));

  opAnd = lexeme(string('&'));

  member = lexeme(regex(/[0-9a-z_\-\.]+/i));

  rule = lazy('rule', function() {
    return seq(conjunction, disjunctionNext.many()).map(function(arg) {
      var first, more;
      first = arg[0], more = arg[1];
      return (function(func, args, ctor) {
        ctor.prototype = func.prototype;
        var child = new ctor, result = func.apply(child, args);
        return Object(result) === result ? result : child;
      })(Or, [first].concat(slice.call(more)), function(){});
    });
  });

  subrule = lparen.then(rule).skip(rparen).or(member);

  conjunctionNext = opAnd.then(subrule);

  conjunction = seq(subrule, conjunctionNext.many()).map(function(arg) {
    var first, more;
    first = arg[0], more = arg[1];
    if (more.length) {
      return (function(func, args, ctor) {
        ctor.prototype = func.prototype;
        var child = new ctor, result = func.apply(child, args);
        return Object(result) === result ? result : child;
      })(And, [first].concat(slice.call(more)), function(){});
    } else {
      return first;
    }
  });

  disjunctionNext = opOr.then(conjunction);

  disjunction = seq(subrule, disjunctionNext.many()).map(function(arg) {
    var first, more;
    first = arg[0], more = arg[1];
    if (more.length) {
      return (function(func, args, ctor) {
        ctor.prototype = func.prototype;
        var child = new ctor, result = func.apply(child, args);
        return Object(result) === result ? result : child;
      })(Or, [first].concat(slice.call(more)), function(){});
    } else {
      return first;
    }
  });

  RuleParser = (function() {
    function RuleParser() {}

    RuleParser.parse = _.memoize(function(r) {
      return rule.parse((r != null ? r.trim() : void 0) || '');
    });

    return RuleParser;

  })();

  (angular.module('rbs-angular-auth')).factory('RuleParser', [
    '$log', function($log) {
      return RuleParser;
    }
  ]);

}).call(this);

(function() {
  (angular.module('rbs-angular-auth')).factory('JWT', [
    '$log', 'ErrorFactory', 'Configuration', function($log, ErrorFactory, Configuration) {
      var JWT;
      JWT = (function() {
        function JWT() {}

        JWT.format = function(header, payload, key) {
          if (!((angular.isObject(header)) && (angular.isObject(payload)) && (key != null))) {
            return void 0;
          }
          return KJUR.jws.JWS.sign(null, angular.toJson(header), angular.toJson(payload), key);
        };

        JWT.parse = function(token, verifyKey) {
          var header, ok, payload, ref, signature;
          if (token == null) {
            return void 0;
          }
          ref = token.split('.'), header = ref[0], payload = ref[1], signature = ref[2];
          ok = verifyKey ? (angular.isNumber(verifyKey) ? verifyKey = '' + verifyKey : void 0, KJUR.jws.JWS.verify(token, verifyKey)) : true;
          if (!ok) {
            ErrorFactory["throw"](Configuration.ERROR_STATUS.NOT_AUTHORIZED, Configuration.ERROR_CODE.INVALID_TOKEN_SIGNATURE, "Invalid JWT token signature");
          }
          return {
            header: angular.fromJson(KJUR.jws.JWS.readSafeJSONString(b64utos(header))),
            payload: angular.fromJson(KJUR.jws.JWS.readSafeJSONString(b64utos(payload)))
          };
        };

        return JWT;

      })();
      return JWT;
    }
  ]);

}).call(this);

(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  (angular.module('rbs-angular-auth')).factory('TokenInterceptor', [
    '$log', '$q', 'TokenManager', 'Configuration', function($log, $q, TokenManager, cfg) {
      var TokenInterceptor;
      TokenInterceptor = (function() {
        function TokenInterceptor() {
          this.request = bind(this.request, this);
          this.response = bind(this.response, this);
        }

        TokenInterceptor.prototype.isEnabled = function(config) {
          if (angular.isString(cfg.HTTP_URL_FILTER)) {
            return S(config.url).startsWith(cfg.HTTP_URL_FILTER);
          } else if (angular.isFunction(cfg.HTTP_URL_FILTER)) {
            return cfg.HTTP_URL_FILTER(config.url);
          } else if (_.isRegExp(cfg.HTTP_URL_FILTER)) {
            return cfg.HTTP_URL_FILTER.test(config.url);
          } else {
            return true;
          }
        };

        TokenInterceptor.prototype.response = function(response) {
          var token;
          if (this.isEnabled(response.config)) {
            token = TokenManager.extract(response);
            if (token != null) {
              TokenManager.storeRaw(token);
            }
          }
          return response;
        };

        TokenInterceptor.prototype.request = function(config) {
          var fromParam, ref, token;
          if (this.isEnabled(config)) {
            fromParam = (ref = config.params) != null ? ref[cfg.JWT_REQUEST_PARAM] : void 0;
            token = fromParam != null ? (delete config.params[cfg.JWT_REQUEST_PARAM], fromParam) : TokenManager.getRaw();
            if (token != null) {
              return TokenManager.inject(config, token) || config;
            } else {
              return config;
            }
          } else {
            return config;
          }
        };

        return TokenInterceptor;

      })();
      return new TokenInterceptor();
    }
  ]);

}).call(this);

(function() {
  var indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  (angular.module('rbs-angular-auth')).factory('SecurityErrorInterceptor', [
    '$log', '$rootScope', '$q', 'Configuration', 'ErrorFactory', function($log, $rootScope, $q, cfg, ErrorFactory) {
      var SecurityErrorInterceptor;
      SecurityErrorInterceptor = (function() {
        function SecurityErrorInterceptor() {}

        SecurityErrorInterceptor.prototype.responseError = function(rejection) {
          var error, errorMessage, ref, ref1;
          error = (ref = rejection.status, indexOf.call(cfg.HTTP_AUTHORIZATION_ERROR_STATUS || [], ref) >= 0) ? (errorMessage = angular.isString(rejection.data) ? rejection.data : angular.isString((ref1 = rejection.data) != null ? ref1.message : void 0) ? rejection.data.message : 'Server returned authorization error', error = ErrorFactory.create(rejection.status, cfg.ERROR_CODE.NO_HTTP_AUTHORIZATION, errorMessage, rejection), $rootScope.$broadcast(cfg.HTTP_AUTHORIZATION_ERROR_EVENT, error), error) : rejection;
          return $q.reject(error);
        };

        return SecurityErrorInterceptor;

      })();
      return new SecurityErrorInterceptor();
    }
  ]);

}).call(this);

(function() {
  (angular.module('rbs-angular-auth')).service('SecurityCtrl', [
    '$log', '$q', '$rootScope', 'Configuration', 'ErrorFactory', 'JWT', 'RuleParser', 'TokenManager', function($log, $q, $rootScope, cfg, ErrorFactory, JWT, RuleParser, TokenManager) {
      var SecurityCtrl;
      SecurityCtrl = (function() {
        function SecurityCtrl() {
          this.principal = void 0;
          this.payload = void 0;
          $rootScope.$on(cfg.JWT_STORE_EVENT, (function(_this) {
            return function() {
              return _this.initialize();
            };
          })(this));
          $rootScope.$on(cfg.JWT_CLEAR_EVENT, (function(_this) {
            return function() {
              return _this.initialize();
            };
          })(this));
          this.initialize();
        }

        SecurityCtrl.prototype.clearCaches = function() {
          var base, base1, base2;
          if (typeof (base = this.isAuthorized.cache).clear === "function") {
            base.clear();
          }
          if (typeof (base1 = this.$readPrincipal.cache).clear === "function") {
            base1.clear();
          }
          return typeof (base2 = this.$readPayload.cache).clear === "function" ? base2.clear() : void 0;
        };

        SecurityCtrl.prototype.initialize = function() {
          var onFailure, onSuccess;
          this.clearCaches();
          this.payload = this.$readPayload();
          onSuccess = (function(_this) {
            return function(principal) {
              _this.clearCaches();
              return _this.principal = principal;
            };
          })(this);
          onFailure = (function(_this) {
            return function() {
              _this.clearCaches();
              return _this.principal = void 0;
            };
          })(this);
          return this.getPrincipal().then(onSuccess, onFailure);
        };

        SecurityCtrl.prototype.$fetchPrincipal = function(payload) {
          return payload;
        };

        SecurityCtrl.prototype.$$readPayload = function() {
          var error, header, payload, rawToken, token;
          rawToken = TokenManager.getRaw();
          token = (function() {
            var error1;
            try {
              return JWT.parse(rawToken);
            } catch (error1) {
              error = error1;
              $log.error("Can't parse token:", rawToken, error);
              return TokenManager.clear();
            }
          })();
          if (token != null) {
            header = token.header, payload = token.payload;
            return payload;
          }
        };

        SecurityCtrl.prototype.$readPayload = _.memoize(SecurityCtrl.prototype.$$readPayload, function() {
          return 'SecurityCtrl-readPayload';
        });

        SecurityCtrl.prototype.$$readPrincipal = function() {
          var payload;
          payload = this.$readPayload();
          if (payload != null) {
            return $q.when(this.$fetchPrincipal(payload));
          } else {
            return $q.reject();
          }
        };

        SecurityCtrl.prototype.$readPrincipal = _.memoize(SecurityCtrl.prototype.$$readPrincipal, function() {
          return 'SecurityCtrl-readPrincipal';
        });

        SecurityCtrl.prototype.getPrincipal = function() {
          return this.$readPrincipal();
        };

        SecurityCtrl.prototype.isAuthenticated = function() {
          return this.payload != null;
        };

        SecurityCtrl.prototype.$$isAuthorized = function(rule, payload) {
          var parsed;
          if (rule == null) {
            return payload != null;
          } else if ((payload != null) && angular.isFunction(cfg.JWT_PERMISSION_CHECK)) {
            parsed = RuleParser.parse(rule);
            if (parsed.status) {
              return parsed.value["eval"](payload, cfg.JWT_PERMISSION_CHECK) === true;
            } else {
              return ErrorFactory["throw"](cfg.ERROR_STATUS.BAD_REQUEST, cfg.ERROR_CODE.INVALID_AUTHORIZATION_RULE, "Can't parse authorization rule: \"" + rule + "\"");
            }
          } else {
            return false;
          }
        };

        SecurityCtrl.prototype.$isAuthorized = function(rule) {
          return this.$$isAuthorized(rule, this.payload);
        };

        SecurityCtrl.prototype.isAuthorized = _.memoize(SecurityCtrl.prototype.$isAuthorized, function(rule) {
          return rule || 'SecurityCtrl-isAuthorized';
        });

        SecurityCtrl.prototype.logout = function() {
          return TokenManager.clear();
        };

        return SecurityCtrl;

      })();
      return SecurityCtrl;
    }
  ]);

}).call(this);

(function() {
  (angular.module('rbs-angular-auth-ui-router')).config([
    '$httpProvider', 'ConfigurationProvider', function($httpProvider, ConfigurationProvider) {
      ConfigurationProvider.put('DATA_AUTHORIZATION_KEY', 'authorize');
      ConfigurationProvider.put('ROUTER_AUTHORIZATION_ERROR_EVENT', 'rbs-angular-auth-ui-router-error');
      return ConfigurationProvider.put('ERROR_CODE', {
        NO_ROUTE_AUTHORIZATION: '0a38f636-c123-4cd5-9249-ad9b6c6724a9'
      });
    }
  ]);

  (angular.module('rbs-angular-auth-ui-router')).run([
    '$log', '$rootScope', 'Configuration', 'ErrorFactory', 'SecurityCtrlInstance', function($log, $rootScope, cfg, ErrorFactory, SecurityCtrlInstance) {
      return $rootScope.$on('$stateChangeStart', function(event, toState, toParams, fromState, fromParams) {
        var authorization, error, ref;
        authorization = (ref = toState.data) != null ? ref[cfg.DATA_AUTHORIZATION_KEY] : void 0;
        if (authorization) {
          error = (function() {
            var error1, error2;
            if (authorization === true) {
              try {
                if (!SecurityCtrlInstance.isAuthenticated()) {
                  return ErrorFactory.create(cfg.ERROR_STATUS.NOT_AUTHORIZED, cfg.ERROR_CODE.NO_ROUTE_AUTHORIZATION, ("State \"" + toState.name + "\" is guarded with authorization rule: \"" + authorization + "\", which is not") + " matched");
                }
              } catch (error1) {
                error = error1;
                return error;
              }
            } else if (angular.isString(authorization)) {
              try {
                if (!SecurityCtrlInstance.isAuthorized(authorization)) {
                  return ErrorFactory.create(cfg.ERROR_STATUS.NOT_AUTHORIZED, cfg.ERROR_CODE.NO_ROUTE_AUTHORIZATION, ("State \"" + toState.name + "\" is guarded with authorization rule: \"" + authorization + "\", which is not") + " matched");
                }
              } catch (error2) {
                error = error2;
                return error;
              }
            }
          })();
          if (error != null) {
            $rootScope.$broadcast(cfg.ROUTER_AUTHORIZATION_ERROR_EVENT, toState, toParams, fromState, fromParams, error);
            return event.preventDefault();
          }
        }
      });
    }
  ]);

}).call(this);

(function() {
  var AUTHORIZATION_HEADER, BEARER_REGEX, BEARER_TEMPLATE, TemplateTokenExtractor, TemplateTokenInjector;

  AUTHORIZATION_HEADER = 'Authorization';

  BEARER_REGEX = /Bearer ([0-9A-Za-z\.\-_]+)/;

  BEARER_TEMPLATE = "Bearer {{token}}";

  TemplateTokenInjector = function(header, template) {
    if (header == null) {
      header = AUTHORIZATION_HEADER;
    }
    if (template == null) {
      template = BEARER_TEMPLATE;
    }
    return function(request, rawToken) {
      return request.headers[header] = angular.isString(template) ? S(template).template({
        token: rawToken,
        rawToken: rawToken
      }).s : angular.isFunction(template) ? template(rawToken) : rawToken;
    };
  };

  (angular.module('rbs-angular-auth')).constant('TemplateTokenInjector', TemplateTokenInjector);

  TemplateTokenExtractor = function(headerName, template) {
    if (headerName == null) {
      headerName = AUTHORIZATION_HEADER;
    }
    if (template == null) {
      template = BEARER_REGEX;
    }
    return function(response) {
      var header, match, rawToken, whole;
      header = response.headers(headerName);
      if (header != null) {
        if (_.isRegExp(template)) {
          match = template.exec(header);
          if (angular.isArray(match)) {
            whole = match[0], rawToken = match[1];
            return rawToken;
          }
        } else if (angular.isFunction(template)) {
          return template(header);
        } else {
          return header;
        }
      }
    };
  };

  (angular.module('rbs-angular-auth')).constant('TemplateTokenExtractor', TemplateTokenExtractor);

  (angular.module('rbs-angular-auth')).config([
    '$httpProvider', 'ConfigurationProvider', 'TemplateTokenExtractor', 'TemplateTokenInjector', function($httpProvider, ConfigurationProvider, TemplateTokenExtractor, TemplateTokenInjector) {
      ConfigurationProvider.put('JWT_STORAGE_KEY', 'JWT');
      ConfigurationProvider.put('SECURITY_CONTROLLER_AS', 'security');
      ConfigurationProvider.put('JWT_STORE_EVENT', 'rbs-angular-auth-JWT-store');
      ConfigurationProvider.put('JWT_CLEAR_EVENT', 'rbs-angular-auth-JWT-clear');
      ConfigurationProvider.put('HTTP_URL_FILTER', function() {
        return true;
      });
      ConfigurationProvider.put('HTTP_AUTHORIZATION_ERROR_STATUS', [401, 403]);
      ConfigurationProvider.put('HTTP_AUTHORIZATION_ERROR_EVENT', 'rbs-angular-auth-http-error');
      ConfigurationProvider.put('JWT_PERMISSION_CHECK', _.constant(false));
      ConfigurationProvider.put('JWT_INJECTOR', TemplateTokenInjector());
      ConfigurationProvider.put('JWT_EXTRACTOR', TemplateTokenExtractor());
      ConfigurationProvider.put('ERROR_STATUS', {
        BAD_REQUEST: 400,
        NOT_AUTHORIZED: 401,
        FORBIDDEN: 403
      });
      ConfigurationProvider.put('ERROR_CODE', {
        INVALID_TOKEN_SIGNATURE: '3b2600fb-8d22-497c-a49b-3dab0b501f04',
        INVALID_AUTHORIZATION_RULE: '6af67e3a-23bc-4e5d-a46b-839e1ad7425f',
        NO_HTTP_AUTHORIZATION: 'c472ad9e-d303-4880-aa92-f788c2b0030e'
      });
      ConfigurationProvider.put('JWT_REQUEST_PARAM', 'access_token');
      $httpProvider.interceptors.push('SecurityErrorInterceptor');
      return $httpProvider.interceptors.push('TokenInterceptor');
    }
  ]);

  (angular.module('rbs-angular-auth')).factory('SecurityCtrlInstance', [
    '$log', 'SecurityCtrl', function($log, SecurityCtrl) {
      return new SecurityCtrl();
    }
  ]);

  (angular.module('rbs-angular-auth')).run([
    '$log', '$rootScope', 'Configuration', 'SecurityCtrlInstance', function($log, $rootScope, cfg, SecurityCtrlInstance) {
      return $rootScope[cfg.SECURITY_CONTROLLER_AS] = SecurityCtrlInstance;
    }
  ]);

}).call(this);

//# sourceMappingURL=rbs-angular-auth.js.map
