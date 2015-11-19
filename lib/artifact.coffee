
When = require 'when'

module.exports = class Artifact

    constructor: (@opts) ->

    create: ->
        console.log 'packing...'
        When { name: 'mypackage', path: './mypackage' }
