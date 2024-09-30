# `TokenInterceptor`

Interceptor `$http`, który:

    (angular.module '<%= package.name %>').factory 'TokenInterceptor', [
      '$log'
      '$q'
      'TokenManager'
      'Configuration'
      ($log, $q, TokenManager, cfg) ->

        class TokenInterceptor

          isEnabled: (config) ->
            if angular.isString cfg.HTTP_URL_FILTER
              S(config.url).startsWith(cfg.HTTP_URL_FILTER)
            else if angular.isFunction cfg.HTTP_URL_FILTER
              cfg.HTTP_URL_FILTER config.url
            else if _.isRegExp cfg.HTTP_URL_FILTER
              cfg.HTTP_URL_FILTER.test config.url
            else true

* odczytuje token `JWT` z żądania (`TokenManager`.`extract`) i zapisuje go  (`TokenManager`.`storeRaw`):

          response: (response) =>
            if @isEnabled response.config
              token = TokenManager.extract(response)
              if token?
                TokenManager.storeRaw(token)
            response

* odczytuje zapisany token `JWT` (`TokenManager`.`getRaw`) i przekazuje go w każdym żądaniu
  (`TokenManager`.`inject`):

          request: (config) =>
            if @isEnabled config
              fromParam = config.params?[cfg.JWT_REQUEST_PARAM]
              token = if fromParam?
                delete config.params[cfg.JWT_REQUEST_PARAM]
                fromParam
              else
                TokenManager.getRaw()
              if token?
                TokenManager.inject(config, token) or config
              else
                config
            else
              config

        new TokenInterceptor()
    ]
