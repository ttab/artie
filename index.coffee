#!/usr/bin/env coffee

program   = require 'commander'
pkg       = require './package'
Artie     = require './lib/artie'
Releases  = require './lib/releases'
GitHubApi = require 'github'

program.version(pkg.version)
    .option('-n, --node-version [version]')
    .option('-o, --os <os>', 'Platform [linux]', 'linux')
    .option('-a, --arch <arch>', 'Processor architecture [x64]', 'x64')
    .option('-r, --only-releases', 'Only fetch releases')
    .option('-t, --token <oAuth token>', 'OAuth token')

artie = ->
    github = new GitHubApi version: '3.0.0'
    github.authenticate
        type: 'oauth',
        token: program.token or process.env.GITHUB_OAUTH_TOKEN or throw 'OAuth token needed'
    releases = new Releases(github)
    artie    = new Artie(program, releases)

program.command('upload')
    .description('Package this project as an executable and upload it to github.')
    .action () ->
        artie().upload()
        .then ->
            console.log 'done'
        .catch (err) ->
            console.error 'Error', err
        .done()

program.command('download <owner> <repo>')
    .description('Fetch the latest packaged executable from github')
    .action (owner, repo) ->
        artie().download(owner, repo)
        .then ->
            console.log 'done'
        .catch (err) ->
            console.error 'Error', err
        .done()

program.parse(process.argv)
