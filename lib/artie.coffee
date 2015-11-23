fs    = require 'fs'
log   = require 'bog'
When  = require 'when'
ncall = require('when/node').call

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
        return undefined if rel.prerelease is true
        return undefined if @opts.production is true and rel.draft is true
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
            (if art.release
                @releases.find owner, repo, (rel) ->
                    if rel.draft is false and
                        rel.prerelease is false and
                        rel.tag_name is art.tag
                    then rel
                .then (rel) =>
                    if rel
                        log.info "Found release", art.tag.yellow
                        rel
                    else
                        log.info "Creating release", art.tag.yellow
                        @releases.createRelease owner, repo, art.tag
            else
                @releases.find owner, repo, (rel) ->
                    if rel.draft is true and
                        rel.prerelease is false and
                        rel.name is art.version and
                        rel.target_commitish is art.branch
                    then rel
                .then (rel) =>
                    if rel
                        log.info "Found draft", art.version.yellow
                        rel
                    else
                        log.info "Creating draft", art.version.yellow
                        @releases.createDraft owner, repo, art.branch, art.version
            ).then (rel) =>
                log.info "Uploading #{art.name.yellow} to #{(owner + '/' + repo + '#' + rel.name).yellow}"
                @releases.upload owner, repo, rel.id, art.name, art.path
            .then (rel) =>
                @releases.findAll owner, repo, (rel) ->
                    return rel.draft is true and
                        rel.name isnt art.version and
                        rel.target_commitish is art.branch
                .then (drafts) =>
                    log.info "Deleting old drafts..."
                    When.all (@releases.deleteRelease owner, repo, draft.id for draft in drafts)
                .then ->
                    rel

    download: (owner, repo) ->
        log.info "Looking for #{if @opts.production then 'production ' else ''}#{@opts.os.yellow}/#{@opts.arch.yellow} artifacts..."
        @releases.find owner, repo, @_findAsset
        .then (asset) =>
            throw new Error 'not found' if not asset
            log.info "Found", asset.name.yellow
            @releases.download asset.url, asset.name
            .then (updated) ->
                if updated
                    log.info "Updating permissions."
                    ncall fs.chmod, asset.name, 0o755
            .then ->
                When.all([
                    ncall fs.realpath, asset.name
                    ncall(fs.realpath, repo).catch ((err) ->)
                ]).spread (fullName, fullRepo) ->
                    if fullName isnt fullRepo
                        log.info "Updating symlink."
                        ncall(fs.unlink, repo).catch ((err) ->)
                        .then -> ncall fs.symlink, asset.name, repo
