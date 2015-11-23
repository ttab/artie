fs     = require 'fs'
findup = require 'findup'
When   = require 'when'
ncall  = require('when/node').call
exec   = require('child_process').exec

module.exports = class Cfg

    constructor: ->

    _read: (name, fatal, fn) ->
        When.promise (resolve, reject) ->
            findup process.cwd(), name, (err, dir) ->
                if err
                    if fatal
                        reject name + ' not found'
                    else
                        resolve undefined
                else
                    file = dir + '/' + name
                    fs.readFile file, (err, data) ->
                        if err
                            reject 'could not read:', file
                        else
                            resolve fn data

    fromGitVersion: ->
        return @git if @git
        ncall(exec, 'git rev-parse --abbrev-ref HEAD').then (branch) ->
            branch = branch[0].trim()
            @git = ncall(exec, 'git describe --exact-match')
            .then (version) ->
                version = version[0].trim()
                return { branch, tag: version, version, release: true }
            .catch (err) ->
                ncall(exec, 'git describe --always --tag')
                .then (version) ->
                    version = version[0].trim()
                    return { branch, tag: undefined, version, release: false }
        .catch (err) ->
            throw new Error 'could not extract GIT version'

    fromPackageJson: ->
        return @pgk if @pgk
        @pkg = @_read 'package.json', true, (data) -> JSON.parse data

    fromNvmrc: ->
        return @nvmrc if @nvmrc
        @nvmrc = @_read '.nvmrc', false, (data) -> data.toString().trim()
