module.exports = function(config) {
  config.set({
    autoWatch: true,
    basePath: '..',
    browsers: [ 'Electron' ],
    frameworks: [ 'browserify', 'mocha' ],
    reporters: [ 'dots' ],
    browserify: {
      watch: true,
      transform: [ 'coffeeify' ],
      extensions: [ '.js', '.coffee' ]
    },
    preprocessors: {
      '**/*.coffee': [ 'browserify' ],
      'src/**/*.js': [ 'browserify', 'electron' ],
      'test/**/*.js': [ 'browserify', 'electron' ]
    },

    files: [
      'test/init.coffee',
      { pattern: 'test/**/*Spec.coffee' }
    ],
  });
};
