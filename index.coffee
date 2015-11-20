#!/usr/bin/env coffee

log       = require 'bog'
colors    = require 'colors'
program   = require 'commander'
Artie     = require './lib/artie'
Artifact  = require './lib/artifact'
Releases  = require './lib/releases'
Cfg       = require './lib/cfg'
GitHubApi = require 'github'

program.version(require('./package').version)
    .option('-n, --node [version]')
    .option('-o, --os <os>', 'Platform [linux]', 'linux')
    .option('-a, --arch <arch>', 'Processor architecture [x64]', 'x64')
    .option('-r, --only-releases', 'Only fetch production ready releases')
    .option('-t, --token <oAuth token>', 'OAuth token', process.env.GITHUB_OAUTH_TOKEN)
    .option('-v, --verbose')

artie = ->
    github = new GitHubApi version: '3.0.0'
    github.authenticate
        type: 'oauth',
        token: program.token or throw 'OAuth token needed'
    cfg      = new Cfg()
    artifact = new Artifact(program, cfg)
    releases = new Releases(program, github)
    artie    = new Artie(program, cfg, artifact, releases)

program.command('upload')
    .description('Package this project as an executable and upload it to github.')
    .action () ->
        artie().upload()
        .then ->
            log.info 'Done.'
        .catch (err) ->
            log.error err.stack.red
            process.exit 1
        .done()

program.command('download <owner> <repo>')
    .description('Fetch the latest packaged executable from github')
    .action (owner, repo) ->
        artie().download(owner, repo)
        .then ->
            log.info 'Done.'
        .catch (err) ->
            log.error err.stack.red
            process.exit 1
        .done()

program.parse(process.argv)
