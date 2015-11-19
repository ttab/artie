nar      = require 'nar'
basename = require('path').basename
When     = require 'when'

module.exports = class Artifact

    constructor: (@opts, @packageInfo) ->
    
    create: ->
        @packageInfo.get().then (info) =>
            binary = true
            os     = @opts.os
            arch   = @opts.arch
            node   = @opts.node
            name   = "#{info.name}-#{info.version}-bin"
            console.log 'Building', name.yellow
            When.promise (resolve, reject) =>
                nar.createExec
                    binary          : binary
                    os              : os
                    arch            : arch
                    node            : node
                    devDependencies : false
                    file            : name
                .on 'error', (err) ->
                    reject err
                .on 'info', (nar) ->
                    console.log 'Info; ' + nar
                .on 'download', ->
                    console.log 'Downloading binary...'
                .on 'generate', ->
                    console.log 'Generating executable...'
                .on 'file', (file) ->
                    if @opts.verbose
                        console.log 'Add [' + file.type.cyan + ']', file.name
                .on 'archive', (file) ->
                    console.log 'Add [' + file.type.cyan + ']', file.name
                .on 'end', (path) ->
                    resolve
                        binary : binary
                        os     : os
                        arch   : arch
                        node   : node
                        name   : basename path
                        path   : path
                
                
