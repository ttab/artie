fs      = require 'fs'
log     = require 'bog'
patches = require './patches'
path    = require 'path'
When    = require 'when'
ncall   = require('when/node').call

module.exports = class Artie

    constructor: (@opts, @cfg, @artifact, @releases, @patches={}) ->

    _parseRepository: (pkg) ->
        throw new Error "missing 'repository' in package.json" unless pkg.repository
        throw new Error "repository type must be 'git'" if pkg.repository.type and pkg.repository.type isnt 'git'
        url = pkg.repository.url or pkg.repository
        try
            [ full, blah, host, owner, repo ] = url.match /^(github:|git@github.com:|(git\+)?https:\/\/github.com\/)?([\w-]*)\/([\w-]*?)(.git)?$/
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

    _applyPatches: ->
        applyPatch = (module, vals) ->
            file = path.join('.', 'node_modules', module, 'package.json')
            fs.access file, fs.R_OK | fs.W_OK, (err) ->
                return When() if err # file not found; which is okay
                ncall fs.readFile, file
                .then (data) ->
                    pkg = JSON.parse(data)
                    modified = modified
                    for key, val of vals
                        do (key, val) ->
                            unless pkg[key]?
                                pkg[key] = val
                                modified = true
                    if modified
                        log.info "Patching #{file}"
                        ncall fs.writeFile, file, JSON.stringify(pkg, null, 2)
        When.all(applyPatch module, vals for module, vals of patches)

    build: ->
        When.all([
            @cfg.fromPackageJson()
            @cfg.fromGitVersion()
        ]).spread (pkg, git) =>
            (if @opts.json
                env = {}
                env[key] = process.env[key] for key in @opts.env
                ncall fs.writeFile, 'build.json', JSON.stringify git: git, env: env
            else
                When()
            ).then =>
                @_applyPatches()
            .then =>
                @artifact.create()

    upload: ->
        When.all([
            @cfg.fromPackageJson()
            @cfg.fromGitVersion()
        ]).spread (pkg, git) =>
            { owner, repo } = @_parseRepository pkg
            @build().then (art) =>
                (if art.release
                    @releases.find owner, repo, (rel) ->
                        if rel.draft is false and
                            rel.prerelease is false and
                            rel.tag_name is art.tag
                        then rel
                    .then (rel) =>
                        if rel
                            log.info "Found release", art.tag
                            rel
                        else
                            log.info "Creating release", art.tag
                            @releases.createRelease owner, repo, art.tag
                else
                    @releases.find owner, repo, (rel) ->
                        if rel.draft is true and
                            rel.prerelease is false and
                            rel.name is art.version
                        then rel
                    .then (rel) =>
                        if rel
                            log.info "Found draft", art.version
                            rel
                        else
                            log.info "Creating draft", art.version
                            @releases.createDraft owner, repo, art.version
                ).then (rel) =>
                    log.info "Uploading #{art.name} to #{(owner + '/' + repo + '#' + rel.name)}"
                    @releases.upload owner, repo, rel.id, art.name, art.path
                .then (rel) =>
                    @releases.findAll owner, repo, (rel) ->
                        return rel.draft is true and
                            rel.body.match(/^This is an automatically created draft/) and
                            rel.name isnt art.version
                    .then (drafts) =>
                        log.info "Deleting old drafts..."
                        When.all (@releases.deleteRelease owner, repo, draft.id for draft in drafts)
                    .then ->
                        rel

    download: (owner, repo) ->
        log.info "Looking for #{if @opts.production then 'production ' else ''}#{@opts.os}/#{@opts.arch} artifacts..."
        @releases.find owner, repo, @_findAsset
        .then (asset) =>
            throw new Error 'not found' if not asset
            log.info "Found", asset.name
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
