EventEmitter = require('events').EventEmitter
proxyquire   = require 'proxyquire'
When         = require 'when'

describe 'Artifact', ->

    describe '.create()', ->
        Artifact = artifact = path = opts = cfg = nar = emitter = undefined
        beforeEach ->
            emitter = new EventEmitter()
            nar =
                createExec: stub().returns emitter
            Artifact = proxyquire '../lib/artifact', { 'nar': nar }
            opts = { os: 'myos', arch: 'myarch' }
            cfg =
                fromGitVersion: stub().returns When { tag: 'v1.0.0', version: 'v1.0.0', release: true, branch: 'master' }
                fromPackageJson: stub().returns When { name: 'myproject', version: '1.0.0' }
                fromNvmrc: stub().returns When '0.12.7'
            artifact = new Artifact opts, cfg
            path = '/my/dir/myproject-v1.0.0-bin-myos-myarch.nar'
            setTimeout (-> emitter.emit 'end', path), 10

        it 'should call nar.createExec()', ->
            artifact.create().then ->
                nar.createExec.should.have.been.calledWith match
                    binary: true
                    file: 'myproject-v1.0.0-bin'
                    os: 'myos'
                    arch: 'myarch'

        it 'should use explicit node versions if possible', ->
            opts.node = '5.0.0'
            artifact.create().then ->
                nar.createExec.should.have.been.calledWith match
                    node: '5.0.0'

        it 'should respect .nvmrc if no explicit node version is given', ->
            artifact.create().then ->
                nar.createExec.should.have.been.calledWith match
                    node: '0.12.7'

        it 'should use the system default node version if all else fails', ->
            cfg.fromNvmrc.returns When undefined
            artifact.create().then ->
                nar.createExec.should.have.been.calledWith match
                    node: undefined

        it 'returns an object describing a release artifact', ->
            artifact.create().then (res) ->
                res.should.have.property 'binary', true
                res.should.have.property 'os', 'myos'
                res.should.have.property 'arch', 'myarch'
                res.should.have.property 'name', 'myproject-v1.0.0-bin-myos-myarch.nar'
                res.should.have.property 'path', '/my/dir/myproject-v1.0.0-bin-myos-myarch.nar'
                res.should.have.property 'tag', 'v1.0.0'
                res.should.have.property 'version', 'v1.0.0'
                res.should.have.property 'release', true
                res.should.have.property 'branch', 'master'

        it 'returns an object describing a development artifact', ->
            path = '/my/dir/myproject-v2.3.0-1-g05fc9e7-bin-myos-myarch.nar'
            cfg.fromGitVersion.returns When { tag: undefined, version: 'v2.3.0-1-g05fc9e7', release: false, branch: 'master' }
            artifact.create().then (res) ->
                res.should.have.property 'binary', true
                res.should.have.property 'os', 'myos'
                res.should.have.property 'arch', 'myarch'
                res.should.have.property 'name', 'myproject-v2.3.0-1-g05fc9e7-bin-myos-myarch.nar'
                res.should.have.property 'path', '/my/dir/myproject-v2.3.0-1-g05fc9e7-bin-myos-myarch.nar'
                res.should.have.property 'tag', undefined
                res.should.have.property 'version', 'v2.3.0-1-g05fc9e7'
                res.should.have.property 'release', false
                res.should.have.property 'branch', 'master'
