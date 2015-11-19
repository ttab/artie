EventEmitter = require('events').EventEmitter
proxyquire   = require 'proxyquire'
When         = require 'when'

describe 'Artifact', ->

    describe '.create()', ->
        Artifact = artifact = opts = cfg = nar = emitter = undefined
        beforeEach ->
            emitter = new EventEmitter()
            nar =
                createExec: stub().returns emitter
            Artifact = proxyquire '../lib/artifact', { 'nar': nar }
            opts = { os: 'myos', arch: 'myarch' }
            cfg =
                fromPackageJson: stub().returns When { }
                fromNvmrc: stub().returns When '0.12.7'
            artifact = new Artifact opts, cfg
            setTimeout (-> emitter.emit 'end'), 10

        it 'should call nar.createExec()', ->
            artifact.create().then ->
                nar.createExec.should.have.been.calledWith match
                    binary: true
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
