# `SecurityErrorInterceptor`

Interceptor `$http` przechwytujący błędy HTTP związane z autoryzacją i publikujące je w formie zdarzeń w `$rootScope`.

    (angular.module '<%= package.name %>').factory 'SecurityErrorInterceptor', [
      '$log'
      '$rootScope'
      '$q'
      'Configuration'
      'ErrorFactory'
      ($log, $rootScope, $q, cfg, ErrorFactory) ->

        class SecurityErrorInterceptor

          responseError: (rejection) ->

Kody błędów, które mają być obsługiwane (domyślnie `401`, `403`) można ustawić w `ConfigurationProvider`
pod kluczem `HTTP_AUTHORIZATION_ERROR_STATUS`.

            error = if rejection.status in (cfg.HTTP_AUTHORIZATION_ERROR_STATUS or [])

W przypadku błędu zawiera wyjątek `ApplicationError` z ustawionymi polami:
* `status` - status HTTP błędu
* `code` - wartość ustawiona w `ConfigurationProvider` - `ERROR_CODE`.`NO_HTTP_AUTHORIZATION`
* `message` - oryginalna wiadomość zwrócona z backendu lub domyślny komunikat
* `cause` - oryginalny błąd

              errorMessage = if angular.isString rejection.data
                rejection.data
              else if angular.isString rejection.data?.message
                rejection.data.message
              else 'Server returned authorization error'

              error = ErrorFactory.create rejection.status,
               cfg.ERROR_CODE.NO_HTTP_AUTHORIZATION,
               errorMessage,
               rejection

Nazwa zdarzenia wysyłanego w przypadku błędu konfigurowana jest pod kluczem `HTTP_AUTHORIZATION_ERROR_EVENT`. Domyślnie:
`<%= package.name %>-http-error`

              $rootScope.$broadcast cfg.HTTP_AUTHORIZATION_ERROR_EVENT, error
              error
            else rejection
            $q.reject error

        new SecurityErrorInterceptor()
    ]
