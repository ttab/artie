#!/usr/bin/env coffee

log       = require 'bog'
Artie     = require './lib/artie'
Artifact  = require './lib/artifact'
Releases  = require './lib/releases'
Cfg       = require './lib/cfg'
GitHubApi = require 'github'
When      = require 'when'

# instantiate all components and wire them up
artie = (program) ->
    log.level 'debug' if program.verbose
    github = new GitHubApi version: '3.0.0'
    github.authenticate
        type: 'oauth',
        token: program.token or process.env.GITHUB_OAUTH_TOKEN or throw 'OAuth token needed'
    cfg      = new Cfg()
    artifact = new Artifact(program, cfg)
    releases = new Releases(program, github)
    artie    = new Artie(program, cfg, artifact, releases)

# run a command inside a promise, handling errors and such
run = (fn, opts, args...) ->
    When().then ->
        a = artie(opts)
        a[fn].apply a, args
    .then ->
        log.info 'Done.'
    .catch (err) ->
        log.error err
        log.error if err.stack? then err.stack else err.toString()
        process.exit 1
    .done()

# common arguments for 'build' and 'upload'
buildArgs = (fn) -> (yargs, argv) ->
    argv = yargs
        .usage("Usage: artie #{fn} [args]")
        .option('a', { alias: 'arch', 'processor architecture', default: 'x64' })
        .option('e', { alias: 'env', description: 'include environment var in build.json', default: [ 'BUILD_NUMER', 'BUILD_ID', 'BUILD_URL', 'BUILD_TAG', 'GIT_COMMIT', 'GIT_URL', 'GIT_BRANCH' ]})
        .option('j', { alias: 'json', 'generate build.json', default: true, type: Boolean })
        .option('n', { alias: 'node', description: 'node.js version' })
        .option('o', { alias: 'os', description: 'platform', default: 'linux' })
        .option('t', { alias: 'token', 'github OAuth token' })
        .array('env')
        .help('h')
        .argv
    run fn, argv

# parse argv and run commands
require('yargs')
    .usage('Usage: artie <command> [args]')
    .command 'build', 'Package this project as an executable.', buildArgs('build')
    .command 'upload', 'Build this project, then upload it to github', buildArgs('build')
    .command 'download', 'Fetch the latest packaged executable from github.', (yargs, argv) ->
        argv = yargs
            .usage("Usage: artie download <owner> <repo> [options]")
            .demand(2, 'must provide owner/repo')
            .option('a', { alias: 'arch', 'processor architecture', default: 'x64' })
            .option('o', { alias: 'os', description: 'platform', default: 'linux' })
            .option('p', { alias: 'production', description: 'only download production ready releases' })
            .argv
        run 'download', argv, argv._[1], argv._[2]
    .help('h')
    .version(-> require('./package.json').version)
    .argv
