# `SecurityCtrl`

Kontroler bezpieczeństwa

    (angular.module '<%= package.name %>').service 'SecurityCtrl', [
      '$log'
      '$q'
      '$rootScope'
      'Configuration'
      'ErrorFactory'
      'JWT'
      'RuleParser'
      'TokenManager'
      ($log, $q, $rootScope, cfg, ErrorFactory, JWT, RuleParser, TokenManager) ->

        class SecurityCtrl

          constructor: () ->

To pole zawsze zawierać będzie auktualny obiekt `principal`:

            @principal = undefined

Pole zawiera zdekodowany `payload` tokena `JWT`:

            @payload = undefined

Ponieważ metody `isAuthorized` oraz `isAuthenticated` korzystają z funkcji `_`.`memoize` - czyścimy cache metod w
momencie zmiany stanu tokena w `TokenManager`.

            $rootScope.$on cfg.JWT_STORE_EVENT, => @initialize()
            $rootScope.$on cfg.JWT_CLEAR_EVENT, => @initialize()
            @initialize()

          clearCaches: ->
            @isAuthorized.cache.clear?()
            @$readPrincipal.cache.clear?()
            @$readPayload.cache.clear?()

Przy uruchomieniu aplikacji odczytujemy stan:

          initialize: ->

            @clearCaches()

            @payload = @$readPayload()

            onSuccess = (principal) =>
              @clearCaches()
              @principal = principal

            onFailure = =>
              @clearCaches()
              @principal = undefined

            @getPrincipal().then onSuccess, onFailure

Konwersja pobiera `principal` na podstawie `payload` tokena `JWT` (przeznaczone do rozszerzenia):

          $fetchPrincipal: (payload) -> payload

Odczytanie payloadu `JWT` (synchroniczne):

          $$readPayload: () ->
            rawToken = TokenManager.getRaw()
            token = try
              JWT.parse rawToken
            catch error
              $log.error "Can't parse token:", rawToken, error
              TokenManager.clear()
            if token?
              {header, payload} = token
              payload

          $readPayload: _.memoize SecurityCtrl::$$readPayload, -> 'SecurityCtrl-readPayload'

Odczytanie aktualnego `principal` (asynchroniczne):

          $$readPrincipal: () ->
            payload = @$readPayload()
            if payload?
              $q.when @$fetchPrincipal payload
            else
              $q.reject()

metoda korzysta z funkcji `_`.`memoize`

          $readPrincipal: _.memoize SecurityCtrl::$$readPrincipal, -> 'SecurityCtrl-readPrincipal'

Pobranie `principal`:

          getPrincipal: () -> @$readPrincipal()

Test czy aktualnie jest zalogowany `principal`:

          isAuthenticated: () ->
            @payload?

Sprawdzenie czy `principal` posiada uprawnienia okreśone regułą `rule`. Metoda korzysta z parametru konfiguracyjnego
`JWT_PERMISSION_CHECK`:

          $$isAuthorized: (rule, payload) ->
            unless rule?
              payload?
            else if payload? and angular.isFunction cfg.JWT_PERMISSION_CHECK
              parsed = RuleParser.parse(rule)
              if parsed.status
                parsed.value.eval(payload, cfg.JWT_PERMISSION_CHECK) == true
              else
                ErrorFactory.throw cfg.ERROR_STATUS.BAD_REQUEST,
                 cfg.ERROR_CODE.INVALID_AUTHORIZATION_RULE,
                 "Can't parse authorization rule: \"#{rule}\""
            else false

          $isAuthorized: (rule) ->
            @$$isAuthorized rule, @payload

metoda korzysta z funkcji `_`.`memoize`

          isAuthorized: _.memoize SecurityCtrl::$isAuthorized, (rule) -> rule or 'SecurityCtrl-isAuthorized'

Wylogowanie:

          logout: () ->
            TokenManager.clear()

        SecurityCtrl

    ]
