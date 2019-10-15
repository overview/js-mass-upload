browserify = require('browserify')
coffeeify = require('coffeeify')
derequire = require('gulp-derequire')
gulp = require('gulp')
gutil = require('gulp-util')
karma = require('karma')
rename = require('gulp-rename')
rimraf = require('gulp-rimraf')
source = require('vinyl-source-stream')
uglify = require('gulp-uglify-es').default

gulp.task 'clean', ->
  gulp.src('./js-mass-upload*.js', read: false)
    .pipe(rimraf())

gulp.task 'clean-demo', ->
  gulp.src('./demo/js', read: false)
    .pipe(rimraf())

gulp.task 'run-browserify', ->
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

gulp.task 'run-browserify-demo', ->
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

gulp.task 'run-minify', ->
  gulp.src('js-mass-upload.js')
    .pipe(uglify())
    .pipe(rename(suffix: '.min'))
    .pipe(gulp.dest('.'))

gulp.task 'browserify', gulp.series('clean', 'run-browserify')

gulp.task 'browserify-demo', gulp.series('browserify', 'clean-demo', 'run-browserify-demo')

gulp.task 'minify', gulp.series('browserify', 'run-minify')

gulp.task 'test', (done) ->
  server = new karma.Server({
    singleRun: true
    browsers: [ 'Electron' ]
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
      '**/*.js': 'electron'
  })
  server.start(done)

gulp.task('default', gulp.series('clean', 'run-browserify', 'run-minify'))
