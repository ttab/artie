Cfg        = require '../lib/cfg'
proxyquire = require 'proxyquire'
When       = require 'when'

describe 'Cfg', ->
    cfg = dir = undefined
    beforeEach ->
        dir = process.cwd()
        cfg = new Cfg()

    afterEach ->
        process.chdir dir

    describe '.fromGitVersion()', ->
        nodefn = undefined
        beforeEach ->
            nodefn =
                call: stub().returns When()
            nodefn.call.withArgs(match.func, 'git rev-parse --abbrev-ref HEAD').returns When ['master\n']
            Cfg = proxyquire '../lib/cfg', { 'when/node': nodefn }
            cfg = new Cfg()

        it 'throws an error if this is not a git project', ->
            nodefn.call.withArgs(match.func).returns When.reject new Error ['fatal: Not a git repository (or any of the parent directories): .git']
            cfg.fromGitVersion().should.be.rejected

        it 'knows when on a release tag', ->
            nodefn.call.withArgs(match.func, 'git describe --exact-match').returns When ['v2.0.0\n']
            cfg.fromGitVersion().should.eventually.eql
                tag: 'v2.0.0'
                version: 'v2.0.0'
                branch: 'master'
                release: true

        it 'knows when we are on a development commit', ->
            nodefn.call.withArgs(match.func, 'git describe --exact-match').returns When.reject([])
            nodefn.call.withArgs(match.func, 'git describe --always --tag').returns When ['v2.3.0-1-g05fc9e7\n']
            cfg.fromGitVersion().should.eventually.eql
                tag: undefined
                version: 'v2.3.0-1-g05fc9e7'
                branch: 'master'
                release: false

        it 'knows when we are on a commit that has not been tagged', ->
            nodefn.call.withArgs(match.func, 'git describe --exact-match').returns When.reject([])
            nodefn.call.withArgs(match.func, 'git describe --always --tag').returns When ['c73594a\n']
            cfg.fromGitVersion().should.eventually.eql
                tag: undefined
                version: 'c73594a'
                branch: 'master'
                release: false

    describe '.fromPackageJson()', ->

        it 'finds and loads package.json', ->
            cfg.fromPackageJson().then (info) ->
                info.name.should.eql 'artie'

        it 'protests when it cannot find package.json', ->
            process.chdir('..')
            cfg.fromPackageJson().should.eventually.be.rejected

    describe '.fromNvmrc()', ->

        it 'finds and parses .nvmrc', ->
            cfg.fromNvmrc().then (info) ->
                info.should.eql '0.12.7'

        it 'returns undefined if .nvmrc is not found', ->
            process.chdir('..')
            cfg.fromNvmrc().then (info) ->
                expect(info).to.be.undefined
