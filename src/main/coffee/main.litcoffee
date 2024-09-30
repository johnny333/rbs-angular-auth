Główny moduł:

    angular.module '<%= package.name %>', [
      'ngStorage'
      'rbs-angular-core'
    ]

Moduł integracji z `ui-router`:

    angular.module '<%= package.name %>-ui-router', [
      'ui.router'
      '<%= package.name %>'
    ]

Moduł zawierający przykłady wykorzystywane w dokumentacji:

    angular.module '<%= package.name %>-samples', [
      '<%= package.name %>-samples'
    ]
