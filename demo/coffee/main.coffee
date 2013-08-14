requirejs.config
  baseUrl: '/demo/js'
  paths:
    backbone: '../../bower_components/backbone/backbone'
    underscore: '../../bower_components/underscore/underscore'
    jquery: '../../bower_components/jquery/jquery'
    'mass-upload': '../../src/js/mass-upload'
  map:
    '*':
      MassUpload: '../../src/js/MassUpload'
  shim:
    backbone:
      deps: [ 'jquery', 'underscore' ]
      exports: 'Backbone'
    jquery:
      exports: '$'
    underscore:
      exports: '_'

require [ 'app' ], ->
