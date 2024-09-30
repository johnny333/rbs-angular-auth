# rbs-angular-auth

Moduł autoryzacji **Angular.js** oparty o [JWT](http://jwt.io)

## Instalacja

    npm install
    bower install

## Instalacja w projekcie

    npm install coffeescript-mixins parsimmon --save-dev
    bower install git@gitlab.bssolutions.pl:biblioteki/rbs-angular-auth.git#v0.0.1 string bignumber.js lodash jsjws crypto-js-evanvosberg jsrsasign ngstorage --save

## API

### `JWT`

Niskopoziomowa usługa do parsowania/formatowania tokenu `JWT`.

Zobacz dostępne [API](src/main/coffee/service/JWT.litcoffee) oraz [testy](src/test/unit/coffee/service/JWT_specs.litcoffee)

### `TokenManager`

Usługa zarządzająca zapisywaniem/przechowywaniem i odczytem tokenu `JWT`.

Zobacz dostępne [API](src/main/coffee/service/TokenManager.litcoffee) oraz [testy](src/test/unit/coffee/service/TokenManager_specs.litcoffee)

### `RuleParser`

Parser reguł autoryzacyjnych umożliwia definiowanie odpytywanie o uprawnienia w formie reguł logicznych.

Zobacz dostępne [API](src/main/coffee/service/RuleParser.litcoffee) oraz [testy](src/test/unit/coffee/service/RuleParser_specs.litcoffee)

### `SecurityCtrl`

Kontroler bezpieczeństwa. Kontroler jest publikowany w `$rootScope` pod kluczem zdefiniowanym w parametrze konfiguracyjnym `SECURITY_CONTROLLER_AS`.
Kontroler publikuje metody umożliwiające sprawdzanie autoryzacji oraz wylogowanie.

Zobacz dostępne [API](src/main/coffee/controller/SecurityCtrl.litcoffee) oraz [testy](src/test/unit/coffee/controller/SecurityCtrl_specs.litcoffee)

### `SecurityErrorInterceptor`

Interceptor `$http` obsługujący błędy autoryzacji zwracane z API.

Zobacz dostępne [API](src/main/coffee/interceptor/SecurityErrorInterceptor.litcoffee) oraz [testy](src/test/unit/coffee/interceptor/SecurityErrorInterceptor_specs.litcoffee)

### `TokenInterceptor`

Interceptor `$http` obsługujący przekazywanie tokenów do/z API.

Zobacz dostępne [API](src/main/coffee/interceptor/TokenInterceptor.litcoffee) oraz [testy](src/test/unit/coffee/interceptor/TokenInterceptor_specs.litcoffee)
