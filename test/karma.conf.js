module.exports = function(config) {
  config.set({
    autoWatch: true,
    basePath: '..',
    browsers: [ 'PhantomJS' ],
    frameworks: [ 'browserify', 'mocha' ],
    reporters: [ 'dots' ],
    browserify: {
      watch: true,
      transform: [ 'coffeeify' ],
      extensions: [ '.js', '.coffee' ]
    },
    preprocessors: {
      '**/*.coffee': [ 'browserify' ],
      'src/**/*.js': [ 'browserify' ],
      'test/**/*.js': [ 'browserify' ]
    },
    files: [
      'test/init.coffee',
      { pattern: 'test/**/*Spec.coffee' }
    ],
  });
};
