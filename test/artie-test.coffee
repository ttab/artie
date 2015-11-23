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
                find: stub().returns When undefined
                upload: stub().returns When {}
                createRelease: stub().returns When { id: 2 }
                createDraft: stub().returns When { id: 3 }
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
                    branch: 'master'

            it 'it finds the corresponding tagged release', ->
                releases.find.withArgs('myowner', 'myrepo', match.func).returns When
                    id: 1, draft: false, prerelease: false, tag_name: 'v2.0.0'
                artie.upload().then ->
                    fn = releases.find.firstCall.args[2]
                    expect(fn({ id: 1, draft: true, prerelease: false, tag_name: 'v2.0.0' })).to.be.undefined
                    expect(fn({ id: 1, draft: false, prerelease: true, tag_name: 'v2.0.0' })).to.be.undefined
                    expect(fn({ id: 1, draft: false, prerelease: false, tag_name: 'v2.0.0' })).to.eql
                        id: 1, draft: false, prerelease: false, tag_name: 'v2.0.0'

            it 'creates a new release if necessary', ->
                artie.upload().then ->
                    releases.createRelease.should.have.been.calledWith 'myowner', 'myrepo', 'v2.0.0'
                    releases.upload.should.have.been.calledWith 'myowner', 'myrepo', 2

            it 'uploads the artifact', ->
                releases.find.withArgs('myowner', 'myrepo', match.func).returns When
                    id: 1, draft: false, prerelease: false, tag_name: 'v2.0.0'
                artie.upload().then ->
                    releases.upload.should.have.been.calledWith 'myowner', 'myrepo', 1,
                        'myrepo-v2.0.0-bin-linux-x64.nar', '/dir/myrepo-v2.0.0-bin-linux-x64.nar'

        describe 'for development releases', ->
            beforeEach ->
                artifact.create.returns When
                    tag: undefined
                    version: 'v2.3.0-1-g05fc9e7'
                    os: 'linux'
                    arch: 'x64'
                    name: 'myrepo-v2.3.0-1-g05fc9e7-bin-linux-x64.nar'
                    path: '/dir/myrepo-v2.3.0-1-g05fc9e7-bin-linux-x64.nar'
                    release: false
                    branch: 'master'

            it 'it looks for a draft release for this branch', ->
                releases.find.withArgs('myowner', 'myrepo', match.func).returns When
                    id: 1, draft: true, prerelease: false, tag_name: null, target_commitish: 'master'
                artie.upload().then ->
                    fn = releases.find.firstCall.args[2]

                    expect(fn({ id: 1, draft: true, prerelease: false, tag_name: 'v2.0.0-abcdef', name: 'master', target_commitish: 'master' }))
                    .to.eql id: 1, draft: true, prerelease: false, tag_name: 'v2.0.0-abcdef', name: 'master', target_commitish: 'master'

                    expect(fn({ id: 1, draft: true, prerelease: false, tag_name: 'v2.0.0-abcdef', name: 'test test', target_commitish: 'master' }))
                    .to.be.undefined

                    expect(fn({ id: 1, draft: true, prerelease: false, tag_name: 'v2.0.0-abcdef', name: 'development', target_commitish: 'development' }))
                    .to.be.undefined

                    expect(fn({ id: 1, draft: false, prerelease: true, tag_name: 'v2.0.0-abcdef', name: 'master', target_commitish: 'master' }))
                    .to.be.undefined

                    expect(fn({ id: 1, draft: false, prerelease: false, tag_name:'v2.0.0-abcdef', name: 'master', target_commitish: 'master' }))
                    .to.be.undefined

            it 'creates a new draft release if necessary', ->
                releases.find.withArgs('myowner', 'myrepo', match.func).returns When undefined
                artie.upload().then ->
                    releases.createDraft.should.have.been.calledWith 'myowner', 'myrepo', 'master'
                    releases.upload.should.have.been.calledWith 'myowner', 'myrepo', 3

            it 'deletes the previous artifact for this os/arch if one already exists'
                # releases.find.withArgs('myowner', 'myrepo', match.func).returns When
                #     id: 1, draft: true, prerelease: false, tag_name: null, target_commitish: 'master'

            it 'uploads the artifact', ->
                releases.find.withArgs('myowner', 'myrepo', match.func).returns When
                    id: 1, draft: true, prerelease: false, tag_name: null, target_commitish: 'master'
                artie.upload().then ->
                    releases.upload.should.have.been.calledWith 'myowner', 'myrepo', 1,
                        'myrepo-v2.3.0-1-g05fc9e7-bin-linux-x64.nar', '/dir/myrepo-v2.3.0-1-g05fc9e7-bin-linux-x64.nar'
