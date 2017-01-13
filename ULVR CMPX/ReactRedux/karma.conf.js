// eslint-disable-next-line no-unused-vars
var webpack = require('webpack')

module.exports = function (config) {
  config.set({
    browsers: ['Chrome'], // run in Chrome
    singleRun: true, // just run once by default
    frameworks: ['mocha', 'chai'], // use the mocha test framework
    files: [
      'tests.webpack.js' // just load this file
    ],
    preprocessors: {
      'tests.webpack.js': ['webpack', 'sourcemap'] // preprocess with webpack and our sourcemap loader
    },
    reporters: ['verbose'], // report results in this format
    webpack: { // kind of a copy of your webpack config
      devtool: 'inline-source-map', // just do inline source maps instead of the default
      module: {
        loaders: [
          {
            test: /\.js$/,
            loaders: ['babel'],
            exclude: /node_modules/,
            include: __dirname
          },
          {
            test: /\.json$/, loader: 'json'
          }
        ]
      }
    },
    webpackServer: {
      noInfo: true // please don't spam the console when running in karma!
    }
  })
}
