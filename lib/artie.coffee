Q = require 'when'

module.exports = class Artie

    constructor: (@opts, @package, @repositories) ->

    upload: ->
        @package.create()

    download: ->
        Q()
