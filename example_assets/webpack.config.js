const path = require('path');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const UglifyJsPlugin = require('uglifyjs-webpack-plugin');
const OptimizeCSSAssetsPlugin = require('optimize-css-assets-webpack-plugin');
const CopyWebpackPlugin = require('copy-webpack-plugin');
const ManifestPlugin = require('webpack-manifest-plugin');
const fs = require('fs');

function getTemplateEntryFiles(viewsPath, parentPrefix = '') {
  return fs.readdirSync(viewsPath).reduce((acc, viewFile) => {
    const viewPath = path.join(viewsPath, viewFile);
    if (fs.lstatSync(viewPath).isDirectory()) {
      const viewName = path.basename(viewFile, '.js');
      return fs.readdirSync(viewPath).reduce((acc, templateFile) => {
        const templatePath = path.join(viewPath, templateFile);
	if (fs.lstatSync(templatePath).isDirectory()) {
	  newObject = getTemplateEntryFiles(viewPath, viewName + '-');
	  Object.entries(newObject).forEach(([key, value]) => {
            newViewName = key.replace('/', '-');
	    acc[newViewName] = value;
	  });
	}
	if (path.extname(templateFile) == '.js') {
          const templateName = path.basename(templateFile, '.js');
          acc[`${parentPrefix + viewName}-${templateName}`] = './' + path.join(viewPath, templateFile);
	}
        return acc;
      }, acc);
    }
    else {
      return acc;
    }
  }, {});
}

const viewEntryPoints = getTemplateEntryFiles('views');

module.exports = (env, options) => ({
  optimization: {
    minimizer: [
      new UglifyJsPlugin({ cache: true, parallel: true, sourceMap: false }),
      new OptimizeCSSAssetsPlugin({})
    ],
    splitChunks: {
      chunks: 'all'
    }
  },
  entry: Object.assign({default: './views/default.js'}, viewEntryPoints),
  output: {
    filename: options.mode === 'production' ? '[id]-[contenthash].js' : '[id].js',
    chunkFilename: options.mode === 'production' ? '[id]-[contenthash].js' : '[id].js',
    path: path.resolve(__dirname, '../priv/static')
  },
  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: /node_modules/,
        use: {
          loader: 'babel-loader'
        }
      },
      {
        test: /\.(scss|css)$/,
        use: [MiniCssExtractPlugin.loader, 'css-loader', 'sass-loader']
      },
      {
        test: /\.(png|jpg|gif)(\?v=\d+\.\d+\.\d+)?$/,
        loader: 'file-loader',
        options: {
          name: 'img/[name].[ext]'
        }
      },
      {
        test: /\.(eot|com|json|ttf|woff|woff2)(\?v=\d+\.\d+\.\d+)?$/,
        loader: 'file-loader',
        options: {
          name: 'fonts/[name].[ext]'
        }
      },
      {
        test: /\.svg(\?v=\d+\.\d+\.\d+)?$/,
        loader: 'file-loader',
        options: {
          name: 'svg/[name].[ext]'
        }
      }
    ]
  },
  plugins: [
    new MiniCssExtractPlugin({
      filename: options.mode === 'production' ? '[id]-[contenthash].css' : '[id].css',
      chunkFilename: options.mode === 'production' ? '[id]-[contenthash].css' : '[id].css',
    }),
    new CopyWebpackPlugin([{ from: 'static/', to: './' }]),
    new ManifestPlugin({ fileName: '../manifest.json' })
  ]
});
