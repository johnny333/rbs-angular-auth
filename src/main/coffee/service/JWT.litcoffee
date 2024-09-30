# `JWT`

Formater i parser tokenu JWT.

    (angular.module '<%= package.name %>').factory 'JWT', [
      '$log'
      'ErrorFactory'
      'Configuration'
      ($log, ErrorFactory, Configuration) ->

        class JWT

Formatowanie tokenu składającego się z nagłówka `header` i ciała `payload` z opcjonalnym podpisem kluczem `key`.

          @format: (header, payload, key) ->
            return undefined unless (angular.isObject header) and (angular.isObject payload) and key?
            KJUR.jws.JWS.sign null, angular.toJson(header), angular.toJson(payload), key

Parsowanie tokenu z opcjonalną weryfikacją podpisu kluczem `verifyKey`.

          @parse: (token, verifyKey) ->
            return undefined unless token?
            [header, payload, signature] = token.split '.'
            ok = if verifyKey
              if angular.isNumber verifyKey
                verifyKey = '' + verifyKey
              KJUR.jws.JWS.verify(token, verifyKey)
            else true
            unless ok
              ErrorFactory.throw Configuration.ERROR_STATUS.NOT_AUTHORIZED,
               Configuration.ERROR_CODE.INVALID_TOKEN_SIGNATURE,
               "Invalid JWT token signature"
            {
              header: angular.fromJson KJUR.jws.JWS.readSafeJSONString(b64utos(header))
              payload: angular.fromJson KJUR.jws.JWS.readSafeJSONString(b64utos(payload))
            }

        JWT
    ]
