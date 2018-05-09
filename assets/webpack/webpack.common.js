/* eslint-disable import/no-extraneous-dependencies */

const Webpack = require('webpack');
const ExtractTextPlugin = require('extract-text-webpack-plugin');
const CopyWebpackPlugin = require('copy-webpack-plugin');
const CleanWebpackPlugin = require('clean-webpack-plugin');
const Dotenv = require('dotenv-webpack');
const path = require('path');

const { OUTPUT_PATH, SOURCE_PATH } = require('./paths');
const config = require('../package');

const ExtractCSS = new ExtractTextPlugin({
  filename: 'css/[name].css',
  allChunks: true,
});

const ExtractSCSS = new ExtractTextPlugin({
  filename: 'css/[name].css',
  allChunks: true,
});

module.exports = {
  target: 'web',

  entry: {
    polyfills: './src/js/polyfills.js',
    app: ['./src/js/app.js'],
  },

  output: {
    pathinfo: true,
    filename: 'js/[name].js', // "js/[name].[chunkhash:8].js"
    chunkFilename: 'js/[name].chunk.js', // "js/[name].[chunkhash:8].chunk.js"
    path: OUTPUT_PATH,
  },

  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: /(node_modules|bower_components)/,
        include: SOURCE_PATH,
        loader: 'babel-loader',
        options: {
          // This is a feature of `babel-loader` for webpack (not Babel itself).
          // It enables caching results in ./node_modules/.cache/babel-loader/
          // directory for faster rebuilds.
          cacheDirectory: true,
        },
      },
      {
        test: /\.(css)$/,
        loader: ExtractCSS.extract({
          use: ['css-loader', 'postcss-loader'],
          fallback: 'style-loader',
        }),
      },
      {
        test: /\.(sass|scss)$/,
        loader: ExtractSCSS.extract({
          use: ['css-loader', 'postcss-loader', 'sass-loader'],
          fallback: 'style-loader',
        }),
      },
      {
        test: /\.(png|svg|jpg|gif)$/,
        use: ['url-loader'],
      },
      {
        test: /\.(woff|woff2|eot|ttf|otf)$/,
        use: ['file-loader'],
      },
    ],
  },

  plugins: [
    ExtractCSS,
    ExtractSCSS,
    new CleanWebpackPlugin([OUTPUT_PATH], {
      verbose: true,
      allowExternal: true,
    }),
    new Webpack.ProvidePlugin({
      jQuery: 'jquery',
      $: 'jquery',
      Pikaday: 'pikaday',
    }),
    new Webpack.EnvironmentPlugin({
      APP_NAME: config.name,
      VERSION: config.version,
    }),
    new Dotenv({
      path: '../.env',
      safe: true,
    }),
    new CopyWebpackPlugin([
      {
        context: './static',
        from: '**/*',
        to: '.',
      },
      {
        context: './node_modules/font-awesome/fonts',
        from: '*',
        to: './fonts',
      },
    ]),
  ],

  resolve: {
    alias: {
      // Help Webpack find Leaflet and Leaflet.Draw's icons
      './images/layers.png$': path.resolve(__dirname, '../node_modules/leaflet/dist/images/layers.png'),
      './images/layers-2x.png$': path.resolve(__dirname, '../node_modules/leaflet/dist/images/layers-2x.png'),
      './images/marker-icon.png$': path.resolve(__dirname, '../node_modules/leaflet/dist/images/marker-icon.png'),
      './images/marker-icon-2x.png$': path.resolve(__dirname, '../node_modules/leaflet/dist/images/marker-icon-2x.png'),
      './images/marker-shadow.png$': path.resolve(__dirname, '../node_modules/leaflet/dist/images/marker-shadow.png'),
      './images/spritesheet.png$': path.resolve(__dirname, '../node_modules/leaflet-draw/dist/images/spritesheet.png'),
      './images/spritesheet-2x.png$': path.resolve(__dirname, '../node_modules/leaflet-draw/dist/images/spritesheet-2x.png'),
      './images/spritesheet.svg$': path.resolve(__dirname, '../node_modules/leaflet-draw/dist/images/spritesheet.svg'),
    },
  },
};
