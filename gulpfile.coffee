pkg              = require './package.json'
_                = require 'lodash'
del              = require 'del'
gulp             = require 'gulp'
inject           = require 'gulp-inject'
karma            = require 'karma'
sequence         = require 'gulp-sequence'

gulpScripts      = require './gulp/scripts'
gulpLibs         = require './gulp/libs'
gulpRelease      = require './gulp/release'
gulpGit          = require './gulp/git'

BOWER_DIR        = 'bower_components'
NPM_DIR          = 'node_modules'
SRC_DIR          = 'src'
SRC_MAIN_DIR     = "#{SRC_DIR}/main"
SRC_TEST_DIR     = "#{SRC_DIR}/test"
SRC_UNIT_DIR     = "#{SRC_TEST_DIR}/unit"
TARGET_DIR       = 'target'
TARGET_MAIN_DIR  = "#{TARGET_DIR}/main"
TARGET_TEST_DIR  = "#{TARGET_DIR}/test"
TARGET_UNIT_DIR  = "#{TARGET_TEST_DIR}/unit"
DIST_DIR         = 'dist'

BUMPED           = [
  'package.json'
  'bower.json'
]

JS_LIBS          = [
  "#{BOWER_DIR}/lodash/dist/lodash.js"
  "#{BOWER_DIR}/string/dist/string.js"
  "#{BOWER_DIR}/bignumber.js/bignumber.js"
  "#{NPM_DIR}/coffeescript-mixins/lib/mixins.js"
  "#{NPM_DIR}/parsimmon/build/parsimmon.browser.js"
  "#{BOWER_DIR}/angular/angular.js"
  "#{BOWER_DIR}/angular-ui-router/release/angular-ui-router.js"
  "#{BOWER_DIR}/jsrsasign/jsrsasign-latest-all-min.js"
  "#{BOWER_DIR}/jsjws/ext/json-sans-eval-min.js"
  "#{BOWER_DIR}/jsjws/jws-3.2.min.js"
  "#{BOWER_DIR}/ngstorage/ngStorage.js"
  "#{BOWER_DIR}/rbs-angular-core/dist/js/rbs-angular-core.js"
]

JS_TEST_LIBS     = [
  "#{BOWER_DIR}/angular-mocks/angular-mocks.js"
  "#{BOWER_DIR}/jasmine-promise-matchers/dist/jasmine-promise-matchers.js"
  "#{BOWER_DIR}/jasmine-object-matchers/dist/jasmine-object-matchers.js"
]

jsonInject = (filepath, file, i, length) ->
  '"' + filepath + '"' + if i + 1 < length then ',' else ''

scripts = gulpScripts
  name: 'scripts'
  pkg: pkg
  src: [
    "#{SRC_MAIN_DIR}/coffee/**/*.{coffee,litcoffee}"
    "#{SRC_MAIN_DIR}/js/**/*.js"
  ]
  dest: "#{TARGET_MAIN_DIR}/js"
  concat: "#{pkg.name}.js"
  sourcemaps: true
  minify: true

libs = gulpLibs
  name: 'js-libs'
  pkg: pkg
  src: JS_LIBS
  dest: "#{TARGET_MAIN_DIR}/js"
  concat: "#{pkg.name}-lib.js"

unitTests = gulpScripts
  name: 'test-unit'
  pkg: pkg
  src: [
    "#{SRC_UNIT_DIR}/coffee/**/*.{coffee,litcoffee}"
    "#{SRC_UNIT_DIR}/js/**/*.js"
  ]
  dest: "#{TARGET_UNIT_DIR}/js"

copyDist = gulpRelease.copy
  src: "#{TARGET_MAIN_DIR}/**"
  dest: DIST_DIR

bump = gulpRelease.bump
  src: BUMPED
  dest: './'

gitAdd = gulpGit.add
  src: "**"

gitCommit = gulpGit.commit
  src: "**"

gitTag = gulpGit.tag
  src: "package.json"

gitPush = gulpGit.push
  src: "package.json"

karmaConfInject = ->
  karmaScripts = _.flatten [
    "#{TARGET_MAIN_DIR}/js/#{pkg.name}-lib.js"
    JS_TEST_LIBS
    "#{TARGET_MAIN_DIR}/js/#{pkg.name}.js"
    "#{TARGET_UNIT_DIR}/js/**/*.js"
  ]
  testScripts = gulp.src karmaScripts
  gulp.src('karma.conf.js')
    .pipe(inject(testScripts, relative: true, starttag: 'files: [', endtag: ']', transform: jsonInject))
    .pipe(gulp.dest('./'));

###
  Clean project
###
gulp.task 'clean', ->
  del [
    "#{TARGET_DIR}/**"
    "#{DIST_DIR}/**"
  ]

###
  Run unit tests
###
gulp.task 'karma-run', (done) ->
  new karma.Server({configFile: "#{__dirname}/karma.conf.js", singleRun: true}, done).start()

###
  Run and watch unit tests
###
gulp.task 'karma-watch', (done) ->
  new karma.Server(configFile: "#{__dirname}/karma.conf.js", singleRun: false).start()
  done()

###
  Inject dependencies into `karma.conf`
###
gulp.task 'inject-karma.conf', karmaConfInject

###
  Compile `#{pkg.name}` Angular.js module with module code in `js/#{pkg.name}.js`
###
gulp.task 'compile-scripts', -> scripts.task()
gulp.task 'refresh-compile-scripts', -> scripts.task(true)

###
  Compile module libraries `js/#{pkg.name}-lib.js`
###
gulp.task 'compile-libs', -> libs.task()
gulp.task 'refresh-compile-libs', -> libs.task(true)

###
  Compile module unit tests in `unit/js`
###
gulp.task 'compile-test', -> unitTests.task()
gulp.task 'refresh-compile-test', -> unitTests.task(true)

###
  Compile module code
###
gulp.task 'compile', ['compile-scripts', 'compile-libs']
gulp.task 'refresh-compile', ['refresh-compile-scripts', 'refresh-compile-libs']

###
  Inject test configuration files
###
gulp.task 'test-inject', ['inject-karma.conf']

gulp.task 'build', sequence(['compile', 'compile-test'], 'test-inject', 'test')

gulp.task 'test', ['karma-run']

gulp.task 'copy-dist', -> copyDist()

gulp.task 'create-dist', ['copy-dist']

gulp.task 'bump', -> bump()

gulp.task 'git-add', -> gitAdd()

gulp.task 'git-commit', -> gitCommit()

gulp.task 'git-tag', -> gitTag()

gulp.task 'git-push', -> gitPush()

gulp.task 'git', sequence 'git-add', 'git-commit', 'git-tag', 'git-push'

gulp.task 'dist', sequence 'clean', 'build', 'create-dist'

gulp.task 'release', sequence 'bump', 'dist', 'git'

gulp.task 'default', sequence('clean', 'build', ['karma-watch', 'watch'])

gulp.task 'refresh', (done) -> sequence(['refresh-compile', 'refresh-compile-test'], 'test-inject')(done)

gulp.task 'watch', () ->
  scripts.watch ['refresh']
  libs.watch ['refresh']
  unitTests.watch ['refresh']
