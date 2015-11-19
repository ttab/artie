Cfg = require '../lib/cfg'

describe 'Cfg', ->
    cfg = dir = undefined
    beforeEach ->
        dir = process.cwd()
        cfg = new Cfg()

    afterEach ->
        process.chdir dir

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
