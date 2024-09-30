# Konfiguracja modułu

    AUTHORIZATION_HEADER = 'Authorization'
    BEARER_REGEX = /Bearer ([0-9A-Za-z\.\-_]+)/
    BEARER_TEMPLATE = """Bearer {{token}}"""

## Funkcja wstrzykująca token do żądania na podstawie szablonu

Fabryka funkcji przyjmuje argumenty:
1. `header` - nazwa nagłówka w jakim przekazywany jest token - domyślnie `Authorization`
1. `template` - szablon formatujący nagłówek - może być w formacie:
  * `function`(`string`): `string` - funkcja formatująca treść nagłówka której argumentem jest token
  * `string` - szablon `handlebars` - token podstawiony jest pod nazwą zmiennej `token` - domyślnie: `Bearer {{token}}`

Zwracana jest funkcja, którą można następnie użyć do konfiguracji parametru `JWT_INJECTOR`.

    TemplateTokenInjector = (header = AUTHORIZATION_HEADER, template = BEARER_TEMPLATE) ->
      (request, rawToken) ->
        request.headers[header] = if angular.isString template
          S(template).template({ token: rawToken, rawToken: rawToken }).s
        else if angular.isFunction template
          template rawToken
        else rawToken

    (angular.module '<%= package.name %>').constant 'TemplateTokenInjector', TemplateTokenInjector

## Funkcja wyciągająca token z odpowiedzi za pomocą wyrażenia regularnego

Fabryka funkcji przyjmuje argumenty:
1. `header` - nazwa nagłówka w jakim przekazywany jest token - domyślnie `Authorization`
1. `template` - szablon nagłówka - może być w formie:
  * `regex` - wyrażenie regularne które wyciąga token z nagłówka w 1. grupie
  * `function`(): `string` - funkcja wyciągająca token z nagłówka

Zwracana jest funkcja, którą można następnie użyć do konfiguracji parametru `JWT_EXTRACTOR`

    TemplateTokenExtractor = (headerName = AUTHORIZATION_HEADER, template = BEARER_REGEX) ->
      (response) ->
        header = response.headers headerName
        if header?
          if _.isRegExp template
            match = template.exec header
            if angular.isArray match
              [whole, rawToken] = match
              rawToken
          else if angular.isFunction template
            template header
          else header

    (angular.module '<%= package.name %>').constant 'TemplateTokenExtractor', TemplateTokenExtractor

    (angular.module '<%= package.name %>').config [
      '$httpProvider'
      'ConfigurationProvider'
      'TemplateTokenExtractor'
      'TemplateTokenInjector'
      ($httpProvider, ConfigurationProvider, TemplateTokenExtractor, TemplateTokenInjector) ->

## Klucz pod jakim przechowywany jest w `$localStorage` token `JWT`:

        ConfigurationProvider.put 'JWT_STORAGE_KEY', 'JWT'

## Klucz pod jakim przechowywany jest w `$rootScope` kontroler `SecurityCtrl`:

        ConfigurationProvider.put 'SECURITY_CONTROLLER_AS', 'security'

## Nazwa zdarzenia publikowanego, gdy ustawiony zostanie nowy token `JWT`:

        ConfigurationProvider.put 'JWT_STORE_EVENT', '<%= package.name %>-JWT-store'

## Nazwa zdarzenia publikowanego, gdy usunięty zostanie token `JWT`:

        ConfigurationProvider.put 'JWT_CLEAR_EVENT', '<%= package.name %>-JWT-clear'

## Filtr URL dla których aktywowany jest `TokenInterceptor` - regex lub funkcja:

        ConfigurationProvider.put 'HTTP_URL_FILTER', -> true

## Statusy błędów, które są publikowane `$rootScope`:

        ConfigurationProvider.put 'HTTP_AUTHORIZATION_ERROR_STATUS', [401, 403]

## Nazwa zdarzenia publikowanego, gdy wystąpi błąd autoryzacji w `$http`:

        ConfigurationProvider.put 'HTTP_AUTHORIZATION_ERROR_EVENT', '<%= package.name %>-http-error'

## Funkcja sprawdzająca obecność uprawnienia `permission` w obiekcie `payload`

Funkcja przyjmuje argumenty:

* payload - payload tokenu `JWT`
* permission - uprawnienie

i zwraca `boolean`

        ConfigurationProvider.put 'JWT_PERMISSION_CHECK', _.constant false

## Funkcja wstrzykująca token `JWT` do żądania:

        ConfigurationProvider.put 'JWT_INJECTOR', TemplateTokenInjector()

## Funkcja wyciągająca token `JWT` z odpowiedzi:

        ConfigurationProvider.put 'JWT_EXTRACTOR', TemplateTokenExtractor()

## Statusy błędów:

        ConfigurationProvider.put 'ERROR_STATUS',
          BAD_REQUEST: 400
          NOT_AUTHORIZED: 401
          FORBIDDEN: 403

## Kody błędów:

        ConfigurationProvider.put 'ERROR_CODE',
          INVALID_TOKEN_SIGNATURE: '3b2600fb-8d22-497c-a49b-3dab0b501f04'
          INVALID_AUTHORIZATION_RULE: '6af67e3a-23bc-4e5d-a46b-839e1ad7425f'
          NO_HTTP_AUTHORIZATION: 'c472ad9e-d303-4880-aa92-f788c2b0030e'

## Parametr żądania pod którym można przekazać token `JWT`:

        ConfigurationProvider.put 'JWT_REQUEST_PARAM', 'access_token'

## `SecurityErrorInterceptor` publikuje zdarzenia związane z błędami autoryzacji w `$rootScope`:

        $httpProvider.interceptors.push 'SecurityErrorInterceptor'

## `TokenInterceptor` dopisuje token JWT do żądania oraz odczytuje go z odpowiedzi:

        $httpProvider.interceptors.push 'TokenInterceptor'

    ]

Po uruchomieniu modułu publikujemy `SecurityCtrl` w `$rootScope`

    (angular.module '<%= package.name %>').factory 'SecurityCtrlInstance', [
      '$log'
      'SecurityCtrl'
      ($log, SecurityCtrl) -> new SecurityCtrl()
    ]

    (angular.module '<%= package.name %>').run [
      '$log'
      '$rootScope'
      'Configuration'
      'SecurityCtrlInstance'
      ($log, $rootScope, cfg, SecurityCtrlInstance) ->

        $rootScope[cfg.SECURITY_CONTROLLER_AS] = SecurityCtrlInstance
    ]
