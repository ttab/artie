fs     = require 'fs'
findup = require 'findup'
When   = require 'when'

module.exports = class Cfg

    constructor: ->

    fromPackageJson: ->
        return @pgk if @pgk
        @pkg = When.promise (resolve, reject) ->
            findup process.cwd(), 'package.json', (err, dir) ->
                if err
                    reject 'package.json not found'
                else
                    file = dir + '/package.json'
                    fs.readFile file, (err, data) ->
                        if err
                            reject 'could not read:', file
                        else
                            resolve JSON.parse data
