fs = require 'fs'
UglifyJS = require 'uglify-js'
srcPath = '../reqs.js'
websrcPath = '../dist-web/reqs.js'
webminPath = '../dist-web/reqs.min.js'
webmapPath = '../dist-web/reqs.min.map'

libSource = fs.readFileSync(srcPath).toString()
webresult = '(this.Reqs=function(module){' + libSource + 'return module.exports;})(this.module || {})'
webmin = UglifyJS.minify( webresult, fromString: true )

fs.writeFile websrcPath, webresult
fs.writeFile webminPath, webmin.code
fs.writeFile webmapPath, webmin.map