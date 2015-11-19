#!/usr/bin/env coffee

colors      = require 'colors'
program     = require 'commander'
Artie       = require './lib/artie'
Artifact    = require './lib/artifact'
Releases    = require './lib/releases'
PackageInfo = require './lib/package-info'
GitHubApi   = require 'github'

program.version(require('./package').version)
    .option('-n, --node [version]')
    .option('-o, --os <os>', 'Platform [linux]', 'linux')
    .option('-a, --arch <arch>', 'Processor architecture [x64]', 'x64')
    .option('-r, --only-releases', 'Only fetch production ready releases')
    .option('-t, --token <oAuth token>', 'OAuth token')
    .option('-v, --verbose')

artie = ->
    github = new GitHubApi version: '3.0.0'
    github.authenticate
        type: 'oauth',
        token: program.token or process.env.GITHUB_OAUTH_TOKEN or throw 'OAuth token needed'
    packageInfo = new PackageInfo()
    artifact    = new Artifact(program, packageInfo)
    releases    = new Releases(program, github)
    artie       = new Artie(program, artifact, releases)

program.command('upload')
    .description('Package this project as an executable and upload it to github.')
    .action () ->
        artie().upload()
        .then (res) ->
            console.log res
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
