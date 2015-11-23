Artie = require '../lib/artie'
When  = require 'when'

describe 'Artie', ->

    artie = undefined
    beforeEach ->
        artie = new Artie

    describe '.parseAsset()', ->

        it 'returns the os and arch for a tag release', ->
            artie._parseAsset 'search-service-v2.0.6-bin-darwin-x64.nar'
            .should.eql
                os: 'darwin'
                arch: 'x64'

    describe '.parseRepository()', ->

        it 'rejects projects without a repository in package.json', ->
            expect(-> artie._parseRepository {}
            ).to.throw "missing 'repository' in package.json"

        it 'rejects non-GIT repos', ->
            expect(-> artie._parseRepository
                repository:
                    type: 'svn'
            ).to.throw "repository type must be 'git'"

        it 'rejects non-github repos', ->
            expect(-> artie._parseRepository
                repository:
                    type: 'git'
                    url: 'http://randomhost.com/myrepo'
            ).to.throw "could not parse GitHub url"

        it 'returns the owner and repo name for a repo object', ->
            artie._parseRepository
                repository:
                    type: 'git'
                    url: 'https://github.com/ttab/my-project'
            .should.eql
                owner: 'ttab'
                repo: 'my-project'

        it 'returns the owner and repo name for a short url', ->
            artie._parseRepository
                repository: 'github:ttab/my-project'
            .should.eql
                owner: 'ttab'
                repo: 'my-project'

        it 'returns the owner and repo name for a short short url', ->
            artie._parseRepository
                repository: 'ttab/my-project'
            .should.eql
                owner: 'ttab'
                repo: 'my-project'

    describe '.upload()', ->
        opts = cfg = artifact = releases = undefined
        beforeEach ->
            opts = {}
            cfg =
                fromPackageJson: stub().returns When
                    repository: 'github:myowner/myrepo'
            artifact =
                create: stub()
            releases =
                find: stub()
                upload: stub().returns When {}
            artie = new Artie opts, cfg, artifact, releases

        describe 'for production releases', ->
            beforeEach ->
                artifact.create.returns When
                    tag: 'v2.0.0'
                    version: 'v2.0.0'
                    os: 'linux'
                    arch: 'x64'
                    name: 'myrepo-v2.0.0-bin-linux-x64.nar'
                    path: '/dir/myrepo-v2.0.0-bin-linux-x64.nar'
                    release: true
                releases.find.withArgs('myowner', 'myrepo', match.func).returns When { id: 1, draft: false, prerelease: false, tag_name: 'v2.0.0' }

            it 'it finds the corresponding tagged release', ->
                artie.upload().then ->
                    fn = releases.find.firstCall.args[2]
                    expect(fn({ id: 1, draft: true, prerelease: false, tag_name: 'v2.0.0' })).to.be.undefined
                    expect(fn({ id: 1, draft: false, prerelease: true, tag_name: 'v2.0.0' })).to.be.undefined
                    expect(fn({ id: 1, draft: false, prerelease: false, tag_name: 'v2.0.0' })).to.eql { id: 1, draft: false, prerelease: false, tag_name: 'v2.0.0' }

            it 'it finds the corresponding tagged release and uploads the artifact', ->
                artie.upload().then ->
                    releases.upload.should.have.been.calledWith 'myowner', 'myrepo', 1, 'myrepo-v2.0.0-bin-linux-x64.nar', '/dir/myrepo-v2.0.0-bin-linux-x64.nar'

        describe 'for development releases', ->

            it 'it looks for a draft release for this branch'

            it 'creates a new draft release if necessary'

            it 'deletes the previous artifact for this os/arch if one already exists'

            it 'uploads the artifact'
