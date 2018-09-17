const path = require('path');
const webpack = require('webpack');
const { BundleAnalyzerPlugin } = require('webpack-bundle-analyzer');
const CleanWebpackPlugin = require('clean-webpack-plugin');
const CopyWebpackPlugin = require('copy-webpack-plugin');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const OptimizeCssAssetsPlugin = require('optimize-css-assets-webpack-plugin');
const UglifyJsPlugin = require('uglifyjs-webpack-plugin');
const VueLoaderPlugin = require('vue-loader/lib/plugin');

const staticAssetOutputPath = path.resolve(__dirname, '../../priv/static');

function getS3AssetURL(argv) {
  return `https://s3.amazonaws.com/plenario2-assets`;
}

module.exports = (_, argv) => {
  const config = {
    target: 'web',
    entry:  {
      polyfill: './src/js/polyfill.js',
      main:     './src/js/main.js',
      explorer: './src/js/explorer.js',
    },
    output: {
      filename:      'js/[name].bundle.js',
      chunkFilename: '[name].chunk.js',
      path:          staticAssetOutputPath,
    },
    plugins: [
      // Define constants which will be available (actually directly replaced, so make sure to JSON
      // Stringify the values) to our JS modules including libraries.
      new webpack.DefinePlugin({
        'env.s3AssetUrl': JSON.stringify(getS3AssetURL(argv)),
      }),
      // Ignore all of the Moment.js locale files, which more than double the build size of our
      // application. Individual locales that are manually imported in the JS override this.
      new webpack.IgnorePlugin(/^\.\/locale$/, /moment$/),
      // Expose globals for our "broken" libraries that assume their deps will all just be shoved
      // onto the window object like it's 2007
      new webpack.ProvidePlugin({
        jQuery:  'jquery',
        $:       'jquery',
        Pikaday: 'pikaday',
      }),
      // Clean out the Webpack build directory before watching files. This ensures renamed or
      // eliminated output files don't stick around to potentially cause subtle bugs or mask asset
      // processing regressions.
      new CleanWebpackPlugin([staticAssetOutputPath], {
        verbose:       false,
        allowExternal: true,
      }),
      // This very commonly duplicates output that would be produced by other loaders (url-loader,
      // etc.), but it ensures that all static assets make it into the output build while still
      // allowing URL-loader to inline it in places where that would be beneficial.
      new CopyWebpackPlugin([
        {
          context: './static',
          from:    '**/*',
          ignore:  ['images/responsive/*'],
          to:      '.',
        },
      ]),
      // Once we've bundled all the CSS into our JS bundle using Webpack, pull it back out again
      // into a separate file. Yes, that seems like a roundabout way of doing it, but that's just
      // how Webpack works.
      new MiniCssExtractPlugin({
        filename: 'css/[name].css',
      }),
      // Enables the automagic Vue single-file-component handling (it duplicates all applicable
      // existing rules to apply to the constituent <template>, <style>, and <script> tags within
      // .vue files)
      new VueLoaderPlugin(),
    ],
    module: {
      rules: [
        // First run all JS files through ESLint to catch code-style issues, then transpile it with
        // Babel so we can use the latest and greatest features of js and have it still work in all
        // of our supported browsers.
        {
          test:    /\.js$/,
          exclude: /(node_modules|phoenix_html)/,
          use:     [
            { loader: 'babel-loader', options: { cacheDirectory: true } },
            'eslint-loader',
          ],
        },
        // First compile our SCSS into CSS, then pass it through PostCSS to apply autoprefixing and
        // minfication based on our supported browsers (as defined in .browserslistrc), then pass
        // through css-loader to resolve URLs and inline imports before bundling it up and then
        // immediately extracting it back out into a separate file.
        {
          test: /\.s[ac]ss$/,
          use:  [
            MiniCssExtractPlugin.loader,
            'css-loader',
            'postcss-loader',
            {
              loader:  'sass-loader',
              options: {
                data: `$s3AssetUrl: "${getS3AssetURL(argv)}";`,
              },
            },
          ],
        },
        // Bundle CSS from node_modules dependencies straight into JS so we don't have to manually
        // reference it elsewhere and it's only loaded when needed.
        {
          test:    /\.css$/,
          include: /node_modules/,
          use:     [
            'style-loader',
            'css-loader',
            'postcss-loader',
          ],
        },
        // Inline (base64-encode) image and font assets if below a certain size. Larger assets are
        // simply copied to the output folder and the URLs unchanged.
        // NOTE: this only affects assets referenced directly or indirectly (e.g. via a stylesheet)
        // from a JavaScript entry point. Webpack can't do anything about URLs in our Phoenix
        // templates.
        {
          test: /\.(png|svg|jpe?g|gif|woff|woff2|eot|ttf|otf)$/,
          use:  [
            { loader: 'url-loader', options: { limit: 8192 } },
          ],
        },
        // vue-loader does some magic to allow the above rules for styles and JavaScript to apply to
        // the constituent parts of our single-file Vue components.
        {
          test: /\.vue$/,
          use:  ['vue-loader'],
        },
      ],
    },
    optimization: {
      minimizer: [
        new UglifyJsPlugin({
          cache:    true,
          parallel: true,
        }),
        new OptimizeCssAssetsPlugin({}),
      ],
    },
    resolve: {
      alias: {
        vue$: 'vue/dist/vue.esm.js',
      },
    },
  };

  // If enabled on the command line (via --env.analyzer), start a server which displays how the
  // various dependencies contribute to the final bundle size
  if (argv.env && argv.env.analyzer) {
    config.plugins.push(new BundleAnalyzerPlugin({ openAnalyzer: false }));
  }

  return config;
};
