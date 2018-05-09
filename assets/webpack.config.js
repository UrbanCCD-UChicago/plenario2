const path = require('path');
const webpack = require('webpack');

module.exports = function (env) {
  const production = process.env.NODE_ENV === 'production';

  return {
    devtool: production ? 'source-maps' : 'eval',
    entry: './js/app.js',
    output: {
      path: path.resolve(__dirname, '../priv/static/js'),
      filename: 'app.js',
      publicPath: '/',
    },
    module: {
      rules: [
        {
          test: /\.js$/,
          exclude: /node_modules/,
          use: {
            loader: 'babel-loader',
          },
        },
        {
          test: require.resolve('jquery'),
          use: [{
            loader: 'expose-loader',
            options: 'jQuery'
          }, {
            loader: 'expose-loader',
            options: '$'
          }]
        },
        {
          test: require.resolve('pikaday'),
          use: [{
            loader: 'expose-loader',
            options: 'Pikaday'
          }]
        },
        {
          test: /\.css$/,
          use: [
            "style-loader",
            {
              loader: "css-loader",
              options: {
                includePaths: [`${__dirname}/node_modules`],
                sourceMap: true
              }
            }
          ]
        },
        {
          test: /\.scss$/,
          use: extractSass.extract({
            use: [
              {
                loader: "css-loader",
                options: {
                  includePaths: [`${__dirname}/node_modules`],
                  sourceMap: true
                }
              },
              "resolve-url-loader",
              {
                loader: "sass-loader",
                options: {
                  includePaths: [`${__dirname}/node_modules`],
                  sourceMap: true
                }
              }
            ],
            fallback: "style-loader"
          })
        }
      ],
    },
    // plugins: [
    //   new webpack.ProvidePlugin({
    //     $: 'jquery',
    //     jQuery: 'jquery'
    //   })
    // ],
    resolve: {
      modules: ['node_modules', path.resolve(__dirname, 'js')],
      extensions: ['.js'],
    },
  };
};
