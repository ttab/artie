When = require 'when'

module.exports = class Artie

    constructor: (@opts, @cfg, @artifact, @releases) ->

    _parseRepository: (pkg) ->
        throw new Error "missing 'repository' in package.json" unless pkg.repository
        throw new Error "repository type must be 'git'" unless pkg.repository.type is 'git'
        try
            [ full, owner, repo ] = pkg.repository.url.match /^https:\/\/github.com\/(.*?)\/(.*)/
            { owner, repo }
        catch err
            throw new Error "could not parse GitHub url"

    upload: ->
        When.all([
            @cfg.fromPackageJson()
            @artifact.create()
        ]).spread (pkg, art) ->
            return art

    download: ->
        Q()
