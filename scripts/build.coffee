fs = require 'fs'
path = require 'path'
babel = require '@babel/core'

srcMainFile = 'reqs.js'
sourcesPath = './src/'
distPath = './dist/'
distWebPath = "#{distPath}web/"
distNodePath = "#{distPath}node/"

srcMainPath = "#{sourcesPath}#{srcMainFile}"

distNodeMainPath = "#{distNodePath}reqs.js"
distWebMainPath = "#{distWebPath}reqs.js"

distMinPath1 = "#{distWebPath}reqs.min.js"
distMapPath1 = "#{distWebPath}reqs.min.map"

distSrcPath2 = "#{distWebPath}reqs.es5.js"
distMinPath2 = "#{distWebPath}reqs.es5.min.js"
distMapPath2 = "#{distWebPath}reqs.es5.min.map"

libDir = 'lib'

babelMinifi =
    presets: ['minify']
    comments: false
    sourceMaps: true
    sourceType: 'script'

babelES5 =
    presets: [
        [
            '@babel/preset-env'
            useBuiltIns: 'entry'
            targets: '> 0.25%, not dead'
            corejs:
                version: 3
        ]
    ]
    comments: true
    sourceMaps: true
    sourceType: 'script'


babelES5Minifi =
    presets: [
        [
            '@babel/preset-env'
            useBuiltIns: 'entry'
            targets: '> 0.25%, not dead'
            corejs:
                version: 3
        ]
        [
            'minify'
            builtIns: false

        ]
    ]
    comments: false
    sourceMaps: true
    sourceType: 'script'


build = ->
    reqsSources = fs.readFileSync(srcMainPath).toString()

    libsSources = loadDir sourcesPath, libDir, false
    protocolsSources = loadDir sourcesPath, 'protocols'
    codersSources = loadDir sourcesPath, 'coders'

    includesL0 = getIncudes libsSources, '.'
    includesL1 = getIncudes libsSources, '..'

    distSrcNode = "#{includesL0}\n\n#{reqsSources}"
    webSourcesArr = [
        libsSources.join '\n'
        reqsSources
        # protocolsSources.join '\n'
        # codersSources.join '\n'
    ]
    distSrcWeb = moduleWrap 'Reqs', webSourcesArr.join '\n\n'
    # distSrcWeb = moduleWrap 'Reqs', "#{libsSources.join('\n')}\n\n#{reqsSources}\n\n#{protocolsSources.join('\n')}\n\n#{codersSources.join('\n')}"


    fs.writeFileSync distNodeMainPath, distSrcNode
    fs.writeFileSync distWebMainPath, distSrcWeb

    babelSaveTo  distSrcWeb, distMinPath1, distMapPath1, babelMinifi       # Default code minification
    babelSaveTo  distSrcWeb, distSrcPath2, null,         babelES5          # ES5 code confertation
    babelSaveTo  distSrcWeb, distMinPath2, distMapPath2, babelES5Minifi    # ES5 code minification

    saveModulesForNode sourcesPath, includesL1, 'protocols', 'Protocol'
    saveModulesForNode sourcesPath, includesL1, 'coders', 'Coder'
    saveLibsForNode sourcesPath, libDir,

fileWriteCb = (fileName) ->
    (err) ->
        if err
            console.error 'Error while saving file: ', fileName
            console.error err
        else
            console.info 'File saved:', fileName

babelSaveTo = (source, jsFile, mapFile, options) ->
    babel.transform(
        source
        options
        (err, result) ->
            if err
                return console.error err

            fs.writeFile jsFile, result.code, fileWriteCb jsFile
            if mapFile?
                delete result.map.sourcesContent
                result.map.sources = [ path.basename jsFile ]
                fs.writeFile mapFile, JSON.stringify(result.map), fileWriteCb mapFile
            result
    )

loadDir = (modulePath, moduleName, isWrap = true) ->
    dirPath = path.join modulePath, moduleName
    files = fs.readdirSync dirPath, withFileTypes: true
    sources = []
    for file in files
        if file.isFile() and file.name.endsWith '.js'
            moduleSrc = fs.readFileSync("#{dirPath}/#{file.name}").toString()
            if isWrap
                sources.push "Reqs.addModule((function(module){#{moduleSrc};return module.exports})({}))"
            else
                str = new String moduleSrc
                str.fileName = file.name
                str.name =  path.parse(file.name).name
                # str.name = file.name.split('.')[0]
                sources.push str
    sources

getIncudes = (libs, level) ->
    includes = ''
    for lib in libs
        includes += "var #{lib.name} = require('#{level}/#{libDir}/#{lib.name}')\n"
    includes

saveModulesForNode = (modulePath, includes, moduleName, constructorName) ->
    sources = loadDir modulePath, moduleName, false
    # constructorPath = "../#{libDir}/#{constructorName}"
    for src in sources
        filePath = "#{distNodePath}#{moduleName}/#{src.fileName}"
        # fileSources = "var #{constructorName} = require('#{constructorPath}')\n\n#{src}"
        fileSources = "#{includes}\n\n#{src}"
        fs.writeFile filePath, fileSources, fileWriteCb filePath
    return

saveLibsForNode = (modulePath, moduleName) ->
    sources = loadDir modulePath, moduleName, false
    for src in sources
        filePath = "#{distNodePath}#{libDir}/#{src.fileName}"
        # filePath = "#{distNodePath}#{libDir}/#{src.fileName}"
        inc = ''
        if src.name isnt 'Tools'
            inc = "Tools = require('./Tools')\n\n"
        fileSources = "#{inc}#{src}\n\nmodule.exports = #{src.name}\n"
        fs.writeFile filePath, fileSources, fileWriteCb filePath
    return

moduleWrap = (moduleName, data) ->
    "this.#{moduleName}=(function(module){#{data};return module.exports})(this.module||{})"

build()