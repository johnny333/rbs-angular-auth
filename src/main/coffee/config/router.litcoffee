# Konfiguracja modułu `ui-router`

    (angular.module '<%= package.name %>-ui-router').config [
      '$httpProvider'
      'ConfigurationProvider'
      ($httpProvider, ConfigurationProvider) ->

## Klucz pod jakim przechowywana jest konfiguracja autoryzacji w danych stanu `ui-router`:

        ConfigurationProvider.put 'DATA_AUTHORIZATION_KEY', 'authorize'

## Nazwa zdarzenia publikowanego, gdy wystąpi błąd autoryzacji przy zmianie stanu:

        ConfigurationProvider.put 'ROUTER_AUTHORIZATION_ERROR_EVENT', '<%= package.name %>-ui-router-error'

## Kody błędów:

        ConfigurationProvider.put 'ERROR_CODE',
          NO_ROUTE_AUTHORIZATION: '0a38f636-c123-4cd5-9249-ad9b6c6724a9'

    ]

    (angular.module '<%= package.name %>-ui-router').run [
      '$log'
      '$rootScope'
      'Configuration'
      'ErrorFactory'
      'SecurityCtrlInstance'
      ($log, $rootScope, cfg, ErrorFactory, SecurityCtrlInstance) ->

        $rootScope.$on '$stateChangeStart', (event, toState, toParams, fromState, fromParams) ->

          authorization = toState.data?[cfg.DATA_AUTHORIZATION_KEY]

          if authorization

            error = if authorization is true
              try
                unless SecurityCtrlInstance.isAuthenticated()
                  ErrorFactory.create cfg.ERROR_STATUS.NOT_AUTHORIZED,
                   cfg.ERROR_CODE.NO_ROUTE_AUTHORIZATION,
                   "State \"#{toState.name}\" is guarded with authorization rule: \"#{authorization}\", which is not" +
                    " matched"
              catch error
                error
            else if angular.isString authorization
              try
                unless SecurityCtrlInstance.isAuthorized(authorization)
                  ErrorFactory.create cfg.ERROR_STATUS.NOT_AUTHORIZED,
                   cfg.ERROR_CODE.NO_ROUTE_AUTHORIZATION,
                   "State \"#{toState.name}\" is guarded with authorization rule: \"#{authorization}\", which is not" +
                    " matched"
              catch error
                error

            if error?
              $rootScope.$broadcast cfg.ROUTER_AUTHORIZATION_ERROR_EVENT, toState, toParams, fromState, fromParams, error
              event.preventDefault()

    ]