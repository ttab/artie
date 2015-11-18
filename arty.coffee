#!/usr/bin/env coffee

program = require('commander')
pkg     = require('./package')

program.version(pkg.version)
    .option('-n, --node-version [version]')
    .option('-o, --os [linux/darwin/sunos]', 'Platform [linux]')
    .option('-a, --arch [x86/x64/armv7l]', 'Processor architecture [x86]', '', 'x86')
    .option('-r, --only-releases', 'Only fetch releases')

program.command('deploy <owner> <repo>')
    .description('Package this project as an executable and upload it to github.')
    .action (owner, repo) ->
        console.log 'arch', program.arch

program.command('fetch <owner> <repo>')
    .description('')

program.parse(process.argv)
