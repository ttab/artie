#!/usr/bin/env coffee

log       = require 'bog'
program   = require 'commander'
Artie     = require './lib/artie'
Artifact  = require './lib/artifact'
Releases  = require './lib/releases'
Cfg       = require './lib/cfg'
GitHubApi = require 'github'

collect = (val, coll) ->
    coll.push val
    coll

program.version(require('./package').version)
    .option('-n, --node [version]')
    .option('-o, --os <os>', 'Platform [linux]', 'linux')
    .option('-a, --arch <arch>', 'Processor architecture [x64]', 'x64')
    .option('-p, --production', 'Only download production ready releases')
    .option('-t, --token <oAuth token>', 'OAuth token', process.env.GITHUB_OAUTH_TOKEN)
    .option('-j, --json <true/false>', 'Generate build.json', true)
    .option('-e, --env [variable]', 'Include environment var in build.json', collect, [
        'BUILD_NUMER', 'BUILD_ID', 'BUILD_URL', 'BUILD_TAG', 'GIT_COMMIT', 'GIT_URL', 'GIT_BRANCH'
    ])
    .option('-v, --verbose')

artie = ->
    log.level 'debug' if program.verbose
    github = new GitHubApi version: '3.0.0'
    github.authenticate
        type: 'oauth',
        token: program.token or throw 'OAuth token needed'
    cfg      = new Cfg()
    artifact = new Artifact(program, cfg)
    releases = new Releases(program, github)
    artie    = new Artie(program, cfg, artifact, releases)

run = (fn) -> ->
    fn()
    .then ->
        log.info 'Done.'
    .catch (err) ->
        log.error err
        log.error if err.stack? then err.stack else err.toString()
        process.exit 1
    .done()

program.command('build')
    .description('Package this project as an executable.')
    .action run -> artie().build()

program.command('upload')
    .description('Build this project, then upload it to github.')
    .action run -> artie().upload()

program.command('download <owner> <repo>')
    .description('Fetch the latest packaged executable from github.')
    .action run -> artie().download()

program.parse(process.argv)
