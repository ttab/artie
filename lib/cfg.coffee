fs     = require 'fs'
findup = require 'findup'
When   = require 'when'

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
        
        
    fromPackageJson: ->
        return @pgk if @pgk
        @pkg = @_read 'package.json', true, (data) -> JSON.parse data
        
    fromNvmrc: ->
        return @nvmrc if @nvmrc
        @nvmrc = @_read '.nvmrc', false, (data) -> data.toString().trim()
