var tests = [];
for (var file in window.__karma__.files) {
  if (window.__karma__.files.hasOwnProperty(file)) {
    if (/Spec\.js$/.test(file)) {
      tests.push(file);
    }
  }
}

requirejs.config({
    // Karma serves files from '/base'
  baseUrl: '/base/src/js',

  shim: {
    'backbone': {
      deps: [ 'underscore' ], // it doesn't *really* need jQuery...
      exports: 'Backbone'
    },
    'underscore': {
      exports: '_'
    }
  },
  paths: {
    'backbone': '/base/bower_components/backbone/backbone',
    'underscore': '/base/bower_components/underscore/underscore'
  },

  // ask Require.js to load these files (all our tests)
  deps: tests,

  // start test run, once Require.js is done
  callback: window.__karma__.start
});
