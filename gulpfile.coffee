browserify = require('browserify')
coffeeify = require('coffeeify')
derequire = require('gulp-derequire')
gulp = require('gulp')
gutil = require('gulp-util')
karma = require('karma').server
rename = require('gulp-rename')
rimraf = require('gulp-rimraf')
source = require('vinyl-source-stream')
uglify = require('gulp-uglify')

gulp.task 'clean', ->
  gulp.src('./js-mass-upload*.js', read: false)
    .pipe(rimraf())

gulp.task 'clean-demo', ->
  gulp.src('./demo/js', read: false)
    .pipe(rimraf())

gulp.task 'browserify', [ 'clean' ], ->
  b = browserify('./src/MassUpload.coffee', {
    extensions: [ '.js', '.coffee' ]
    standalone: 'MassUpload'
  })
  b.transform(coffeeify)

  b.bundle()
    .on('error', (e) -> gutil.log('Browserify error', e))
    .pipe(source('js-mass-upload.js'))
    .pipe(derequire())
    .pipe(gulp.dest('.'))

gulp.task 'browserify-demo', [ 'browserify', 'clean-demo' ], ->
  b = browserify('./app.coffee', {
    extensions: [ '.js', '.coffee' ]
    basedir: './demo/coffee'
  })
  b.transform(coffeeify)

  b.bundle()
    .on('error', (e) -> gutil.log('Browserify error', e))
    .pipe(source('app.js'))
    .pipe(derequire())
    .pipe(gulp.dest('./demo/js'))

gulp.task 'minify', [ 'browserify' ], ->
  gulp.src('js-mass-upload.js')
    .pipe(uglify())
    .pipe(rename(suffix: '.min'))
    .pipe(gulp.dest('.'))

gulp.task 'test-browser', (done) ->
  karma.start({
    singleRun: true
    browsers: [ 'PhantomJS' ]
    frameworks: [ 'browserify', 'mocha' ]
    reporters: [ 'dots' ]
    browserify:
      debug: true
      extensions: [ '.js', '.coffee' ]
      transform: [ coffeeify ]
    files: [
      'test/init.coffee'
      { pattern: 'test/**/*Spec.coffee' }
    ]
    preprocessors:
      '**/*.coffee': 'browserify'
  }, done)

gulp.task('test', [ 'test-browser' ])

gulp.task('default', [ 'minify', 'browserify-demo' ])
