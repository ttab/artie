When   = require 'when'

module.exports = class Artifact

    constructor: (@opts, @packageInfo) ->
    
    create: ->
        @packageInfo.get().then (info) ->
            console.log 'info', info
            console.log 'packing...'
            { name: 'mypackage', path: './mypackage' }
