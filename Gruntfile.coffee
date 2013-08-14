module.exports = (grunt) ->
  grunt.initConfig
    coffee:
      options:
        bare: true
        flatten: false

      demo:
        expand: true
        cwd: 'demo/coffee'
        src: [ '**/*.coffee' ]
        dest: 'demo/js'
        ext: '.js'

      src:
        expand: true
        cwd: 'src/coffee'
        src: [ '**/*.coffee' ]
        dest: 'src/js'
        ext: '.js'

      test:
        expand: true
        cwd: 'test/coffee'
        src: [ '**/*.coffee' ]
        dest: 'test/js'
        ext: '.js'

    connect:
      server:
        options:
          port: 9001
          base: '.'

    requirejs:
      options:
        baseUrl: 'src/js/'
        exclude: [ 'backbone', 'underscore', 'jquery' ]
        paths:
          backbone: '../../bower_components/backbone/backbone'
          underscore: '../../bower_components/underscore/underscore'
          jquery: '../../bower_components/jquery/jquery'
        shim:
          backbone:
            deps: [ 'jquery', 'underscore' ]
            exports: 'Backbone'
          jquery:
            exports: '$'
          underscore:
            exports: '_'

      development:
        options:
          name: 'MassUpload'
          optimize: 'none'
          out: 'dist/mass-upload.js'

      minified:
        options:
          name: 'MassUpload'
          optimize: 'uglify2'
          out: 'dist/mass-upload.min.js'

      almond:
        options:
          name: 'index'
          optimize: 'none'
          almond: true
          wrap: true
          out: 'dist/mass-upload.no-require.js'

      almond_minified:
        options:
          name: 'index'
          optimize: 'uglify2'
          almond: true
          wrap: true
          out: 'dist/mass-upload.no-require.min.js'

    karma:
      options:
        configFile: 'test/karma.conf.js'
      unit:
        background: true
      continuous:
        singleRun: true

    watch:
      options:
        spawn: false
      coffee:
        files: [ 'src/coffee/**/*.coffee' ]
        tasks: [ 'coffee:compile', 'karma:unit:run' ]
      'coffee-demo':
        files: [ 'demo/coffee/**/*.coffee' ]
        tasks: [ 'coffee:demo:compile' ]
      'coffee-test':
        files: [ 'test/coffee/**/*.coffee' ]
        tasks: [ 'coffee:test', 'karma:unit:run' ]

  grunt.loadNpmTasks('grunt-contrib-connect')
  grunt.loadNpmTasks('grunt-contrib-coffee')
  grunt.loadNpmTasks('grunt-contrib-watch')
  grunt.loadNpmTasks('grunt-requirejs')
  grunt.loadNpmTasks('grunt-karma')

  # Only rewrite changed files on watch
  grunt.event.on 'watch', (action, filepath) ->
    if filepath.indexOf('.coffee') == filepath.length - 7 && filepath.length > 7
      srcPath = grunt.config('coffee.src.cwd')
      testPath = grunt.config('coffee.test.cwd')
      demoPath = grunt.config('coffee.demo.cwd')
      if filepath.indexOf(srcPath) == 0
        grunt.config('coffee.src.src', filepath.replace(srcPath, '.'))
      else if filepath.indexOf(testPath) == 0
        grunt.config('coffee.test.src', filepath.replace(testPath, '.'))
      else if filepath.indexOf(demoPath) == 0
        grunt.config('coffee.demo.src', filepath.replace(demoPath, '.'))

  # karma:unit takes a moment to spin up
  grunt.registerTask 'wait-for-karma', 'Wait until Karma server is running', ->
    setTimeout(@async(), 3000)

  grunt.registerTask('default', [ 'coffee:src', 'requirejs' ])
  grunt.registerTask('test', [ 'coffee', 'karma:continuous' ])
  grunt.registerTask('develop', [ 'coffee', 'karma:unit', 'wait-for-karma', 'karma:unit:run', 'watch' ])
  grunt.registerTask('server', [ 'coffee', 'requirejs:development', 'connect:server', 'watch' ])
