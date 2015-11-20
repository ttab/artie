When = require 'when'

module.exports = class Artie

    constructor: (@opts, @cfg, @artifact, @releases) ->

    _parseRepository: (pkg) ->
        throw new Error "missing 'repository' in package.json" unless pkg.repository
        throw new Error "repository type must be 'git'" if pkg.repository.type and pkg.repository.type isnt 'git'
        url = pkg.repository.url or pkg.repository
        try
            [ full, host, owner, repo ] = url.match /^(github:|https:\/\/github.com\/)?([\w-]*)\/([\w-]*)$/
            { owner, repo }
        catch err
            throw new Error "could not parse GitHub url:", url

    upload: ->
        When.all([
            @cfg.fromPackageJson()
            @artifact.create()
        ]).spread (pkg, art) ->
            return art

    download: ->
        Q()
