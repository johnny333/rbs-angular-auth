# `RuleParser`

Parser reguł autoryzacyjnych. Reguły mogą zawierać nazwy ról oraz znaki `(`, `)`, `|`, `&`.

    class Operator

      constructor: (@permissions...) ->

      @evalPermission: (principal, permissionCheck) ->
        (permission) ->
          if angular.isString permission
            permissionCheck(principal, permission)
          else if angular.isFunction permission?.eval
            permission.eval principal, permissionCheck

    class And extends Operator

      eval: (principal, permissionCheck) ->
        _.every @permissions, Operator.evalPermission(principal, permissionCheck)

      toJSON: () ->
        "and": @permissions

    class Or extends Operator

      eval: (principal, permissionCheck) ->
        _.some @permissions, Operator.evalPermission(principal, permissionCheck)

      toJSON: () ->
        "or": @permissions

    alt = Parsimmon.alt
    seq = Parsimmon.seq
    lazy = Parsimmon.lazy
    regex = Parsimmon.regex
    string = Parsimmon.string
    optWhitespace = Parsimmon.optWhitespace

    lexeme = (p) -> p.skip optWhitespace

    lparen = lexeme string '('
    rparen = lexeme string ')'
    opOr = lexeme string '|'
    opAnd = lexeme string '&'
    member = lexeme regex /[0-9a-z_\-\.]+/i

    rule = lazy 'rule', ->
      seq(conjunction, disjunctionNext.many()).map ([first, more]) -> new Or(first, more...)
    subrule = lparen.then(rule).skip(rparen).or(member)
    conjunctionNext = opAnd.then(subrule)
    conjunction = seq(subrule, conjunctionNext.many()).map ([first, more]) ->
      if more.length
        new And(first, more...)
      else
        first
    disjunctionNext = opOr.then(conjunction) # plus
    disjunction = seq(subrule, disjunctionNext.many()).map ([first, more]) ->
      if more.length
        new Or(first, more...)
      else
        first

    class RuleParser

      @parse: _.memoize (r) -> rule.parse r?.trim() or ''

    (angular.module '<%= package.name %>').factory 'RuleParser', [
      '$log'
      ($log) -> RuleParser
    ]
