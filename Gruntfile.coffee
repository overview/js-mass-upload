module.exports = (grunt) ->
  grunt.initConfig
    coffee:
      options:
        bare: true

      compile:
        expand: true
        flatten: false
        cwd: 'src/coffee'
        src: [ '**/*.coffee' ]
        dest: 'src/js'
        ext: '.js'

      test:
        expand: true
        flatten: false
        cwd: 'test/coffee'
        src: [ '**/*.coffee' ]
        dest: 'test/js'
        ext: '.js'

    requirejs:
      development:
        options:
          name: 'MassUpload'
          baseUrl: 'src/js/'
          optimize: 'none'
          out: 'dist/mass-upload.js'

      minified:
        options:
          name: 'MassUpload'
          baseUrl: 'src/js/'
          optimize: 'uglify2'
          out: 'dist/mass-upload.min.js'

      almond:
        options:
          name: 'index'
          baseUrl: 'src/js/'
          optimize: 'none'
          almond: true
          wrap: true
          out: 'dist/mass-upload.no-require.js'

      almond_minified:
        options:
          name: 'index'
          baseUrl: 'src/js/'
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
      coffee:
        files: [ 'src/coffee/**/*.coffee' ]
        tasks: [ 'coffee:compile', 'karma:unit:run' ]
        options:
          spawn: false
      'coffee-test':
        files: [ 'test/coffee/**/*.coffee' ]
        tasks: [ 'coffee:test:run', 'karma:unit:run' ]
        options:
          spawn: false

  grunt.loadNpmTasks('grunt-contrib-coffee')
  grunt.loadNpmTasks('grunt-contrib-watch')
  grunt.loadNpmTasks('grunt-requirejs')
  grunt.loadNpmTasks('grunt-karma')

  # Only rewrite changed files on watch
  grunt.event.on 'watch', (action, filepath) ->
    if filepath.indexOf('.coffee') == filepath.length - 7 && filepath.length > 7
      compilePath = grunt.config('coffee.compile.cwd')
      testPath = grunt.config('coffee.test.cwd')
      if filepath.indexOf(compilePath) == 0
        grunt.config('coffee.compile.src', filepath.replace(compilePath, '.'))
      else if filepath.indexOf(testPath) == 0
        grunt.config('coffee.test.src', filepath.replace(testPath, '.'))

  # karma:unit takes a moment to spin up
  grunt.registerTask 'wait-for-karma', 'Wait until Karma server is running', ->
    setTimeout(@async(), 3000)

  grunt.registerTask('default', [ 'coffee:compile', 'requirejs' ])
  grunt.registerTask('test', [ 'coffee', 'karma:continuous' ])
  grunt.registerTask('develop', [ 'coffee', 'karma:unit', 'wait-for-karma', 'karma:unit:run', 'watch' ])
