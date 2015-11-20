log  = require 'bog'
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

    _parseAsset: (name) ->
        try
            [ full, os, arch ] = name.match /-(\w+)-(\w+).nar$/
            { os, arch }
        catch err
            undefined

    _findAsset: (rel) =>
        assets = rel.assets.filter (asset) =>
            if parsed = @_parseAsset asset.name
                return parsed.os == @opts.os and parsed.arch == @opts.arch
        assets[0]

    upload: ->
        When.all([
            @cfg.fromPackageJson()
            @artifact.create()
        ]).spread (pkg, art) =>
            { owner, repo } = @_parseRepository pkg
            @releases.find owner, repo, (rel) -> rel.tag_name is art.tag
            .then (rel) =>
                log.info "Uploading #{art.name.yellow} to #{(owner + '/' + repo + '#' + art.tag).yellow}"
                @releases.upload owner, repo, rel.id, art.name, art.path

    download: (owner, repo) ->
        log.info "Looking for #{@opts.os.yellow}/#{@opts.arch.yellow} artifacts..."
        @releases.find owner, repo, @_findAsset
        .then (asset) =>
            throw new Error 'not found' if not asset
            log.info "Found", asset.name.yellow
            @releases.download asset.url, asset.name
            .then (updated) ->
                console.log 'updated:', updated
