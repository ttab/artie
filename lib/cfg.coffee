fs     = require 'fs'
findup = require 'findup'
When   = require 'when'
nodefn = require 'when/node'
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
        @git = nodefn.call(exec, 'git describe --exact-match')
        .then (stdout) ->
            stdout = stdout[0].trim()
            return { tag: stdout, version: stdout, release: true }
        .catch (err) ->
            nodefn.call(exec, 'git describe --always --tag')
            .then (stdout) ->
                stdout = stdout[0].trim()
                [ full, tag ] = stdout.match /(v\d+\.\d+\.\d+).*/
                return { tag: tag, version: stdout, release: false }
        .catch (err) ->
            throw new Error 'could not extract GIT version'
            
    fromPackageJson: ->
        return @pgk if @pgk
        @pkg = @_read 'package.json', true, (data) -> JSON.parse data
        
    fromNvmrc: ->
        return @nvmrc if @nvmrc
        @nvmrc = @_read '.nvmrc', false, (data) -> data.toString().trim()
