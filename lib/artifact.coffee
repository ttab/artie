nar      = require 'nar'
basename = require('path').basename
When     = require 'when'
log      = require 'bog'

module.exports = class Artifact

    constructor: (@opts, @cfg) ->

    create: ->
        When.all([
            @cfg.fromGitVersion()
            @cfg.fromPackageJson()
            @cfg.fromNvmrc()
        ]).spread (git, pkg, nvmrc) =>
            binary = true
            os     = @opts.os
            arch   = @opts.arch
            node   = @opts.node or nvmrc
            name   = "#{pkg.name}-#{git.version}-bin"
            log.info 'Building', name
            When.promise (resolve, reject) =>
                nar.createExec
                    binary          : binary
                    os              : os
                    arch            : arch
                    node            : node
                    file            : name
                .on 'error', (err) ->
                    reject err
                .on 'info', (nar) ->
                    log.info 'Info; ' + nar
                .on 'download', ->
                    log.info 'Downloading binary...'
                .on 'generate', ->
                    log.info 'Generating executable...'
                .on 'entry', (file) ->
                    log.debug 'Add [' + file.type + ']', file.name
                .on 'archive', (file) ->
                    log.info 'Add [' + file.type + ']', file.name
                .on 'end', (path) ->
                    resolve
                        binary  : binary
                        os      : os
                        arch    : arch
                        name    : basename path
                        path    : path
                        tag     : git.tag
                        version : git.version
                        release : git.release
                        branch  : git.branch
                        pkg     : pkg.name
