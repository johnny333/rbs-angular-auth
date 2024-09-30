# `TokenManager`

Zarządzanie tokenem JWT.

    (angular.module '<%= package.name %>').factory 'TokenManager', [
      '$log'
      '$localStorage'
      '$rootScope'
      'Configuration'
      ($log, $localStorage, $rootScope, Configuration) ->

        JWT_STORAGE_KEY = Configuration.JWT_STORAGE_KEY
        JWT_STORE_EVENT = Configuration.JWT_STORE_EVENT
        JWT_CLEAR_EVENT = Configuration.JWT_CLEAR_EVENT
        JWT_INJECTOR    = Configuration.JWT_INJECTOR
        JWT_EXTRACTOR   = Configuration.JWT_EXTRACTOR

        class TokenManager

Token zapisywany jest do `localStorage`.

          storeRaw: (token) ->
            if @getRaw() isnt token
              $log.debug 'Store JWT token: ', token
              $localStorage[JWT_STORAGE_KEY] = token
              $rootScope.$broadcast JWT_STORE_EVENT, this, token

Token pobierany jest z `localStorage`.

          getRaw: () ->
            $localStorage[JWT_STORAGE_KEY]

Token jest usuwany `localStorage`.

          clear: () ->
            token = @getRaw()
            $log.debug 'Cleared JWT token: ', token
            delete $localStorage[JWT_STORAGE_KEY]
            $rootScope.$broadcast JWT_CLEAR_EVENT, this, token

Token przekazujemy w nagłówku `Authorization` żądania, z prefiksem "Bearer".

          inject: (request, rawToken) ->
            JWT_INJECTOR request, rawToken
            request

Token wyciągamy z nagłówka `Authorization` odpowiedzi, z prefiksem "Bearer".

          extract: (response) ->
            JWT_EXTRACTOR response

        new TokenManager()
    ]
