When       = require 'when'
proxyquire = require 'proxyquire'

describe 'Artie', ->

    artie = undefined
    beforeEach ->
        Artie = require '../lib/artie'
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

        it 'returns the owner and repo name for a repo.git', ->
            artie._parseRepository
                repository:
                    type: 'git'
                    url: 'https://github.com/ttab/my-project'
            .should.eql
                owner: 'ttab'
                repo: 'my-project'

        it 'returns the owner and repo name for a git+https repo.git', ->
            artie._parseRepository
                repository:
                    type: 'git'
                    url: 'git+https://github.com/ttab/my-project'
            .should.eql
                owner: 'ttab'
                repo: 'my-project'

        it 'returns the owner and repo name for a git@repo.git', ->
            artie._parseRepository
                repository:
                    type: 'git'
                    url: 'git@github.com:ttab/my-project.git'
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

    describe '.build()', ->
        opts = cfg = fs = artifact = releases = undefined
        beforeEach ->
            fs =
                writeFile: spy (file, data, cb) -> cb undefined
            Artie = proxyquire '../lib/artie', { 'fs', fs }
            opts =
                json: true
                env: []
            cfg =
                fromPackageJson: stub().returns When
                    repository: 'github:myowner/myrepo'
                fromGitVersion: stub().returns When
                    version: 'myversion'
            artifact =
                create: stub()
            releases =
                find: stub().returns When undefined
                findAll: stub().returns When [ ]
                upload: stub().returns When {}
                createRelease: stub().returns When { id: 2 }
                createDraft: stub().returns When { id: 3 }
                deleteRelease: stub().returns When {}
            artie = new Artie opts, cfg, artifact, releases

        it 'writes to build.json', ->
            artie.build().then ->
                fs.writeFile.should.have.been.calledWith 'build.json', JSON.stringify
                    git:
                        version: 'myversion'
                    env: {}

        it 'creates the artifact', ->
            artie.build().then ->
                artifact.create.should.have.been.calledOnce

    describe '.upload()', ->
        opts = cfg = fs = artifact = releases = undefined
        beforeEach ->
            fs =
                writeFile: spy (file, data, cb) -> cb undefined
            Artie = proxyquire '../lib/artie', { 'fs', fs }
            opts =
                json: true
                env: []
            cfg =
                fromPackageJson: stub().returns When
                    repository: 'github:myowner/myrepo'
                fromGitVersion: stub().returns When
                    version: 'myversion'
            artifact =
                create: stub()
            releases =
                find: stub().returns When undefined
                findAll: stub().returns When [ ]
                upload: stub().returns When {}
                createRelease: stub().returns When { id: 2 }
                createDraft: stub().returns When { id: 3 }
                deleteRelease: stub().returns When {}
                deleteAssets: stub().returns When {}
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

            it 'deletes the release and tries again if there was an error', ->
                releases.find.withArgs('myowner', 'myrepo', match.func).returns When
                    id: 1, draft: false, prerelease: false, tag_name: 'v2.0.0'
                releases.upload.onFirstCall().returns When.reject { error: 'panda attack!', code: 502 }
                artie.upload().then ->
                    releases.deleteAssets.should.have.been.calledWith 'myowner', 'myrepo', 1
                    releases.upload.should.have.been.calledTwice

            it 'gives up on trying to upload if we fail repeatedly', ->
                @timeout 10000
                releases.find.withArgs('myowner', 'myrepo', match.func).returns When
                    id: 1, draft: false, prerelease: false, tag_name: 'v2.0.0'
                releases.upload.returns When.reject { error: 'panda attack!', code: 502 }
                artie.upload().should.eventually.be.rejected

            it 'does not try again if the error was that the release already exists', (done) ->
                releases.find.withArgs('myowner', 'myrepo', match.func).returns When
                    id: 1, draft: false, prerelease: false, tag_name: 'v2.0.0'
                releases.upload.onFirstCall().returns When.reject { error: 'Asset already exists', code: 'already_exists' }
                artie.upload().catch (err) ->
                    releases.deleteAssets.should.not.have.been.called
                    releases.upload.should.have.been.calledOnce
                    done()

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

                    expect(fn({ id: 1, draft: true, prerelease: false, tag_name: 'v2.3.0-1-g05fc9e7', name: 'v2.3.0-1-g05fc9e7', target_commitish: 'master' }))
                    .to.eql id: 1, draft: true, prerelease: false, tag_name: 'v2.3.0-1-g05fc9e7', name: 'v2.3.0-1-g05fc9e7', target_commitish: 'master'

                    expect(fn({ id: 1, draft: true, prerelease: false, tag_name: 'v2.3.0-1-g05fc9e7', name: 'development', target_commitish: 'master' }))
                    .to.be.undefined

                    expect(fn({ id: 1, draft: false, prerelease: true, tag_name: 'v2.3.0-1-g05fc9e7', name: 'v2.3.0-1-g05fc9e7', target_commitish: 'master' }))
                    .to.be.undefined

                    expect(fn({ id: 1, draft: false, prerelease: false, tag_name:'v2.3.0-1-g05fc9e7', name: 'v2.3.0-1-g05fc9e7', target_commitish: 'master' }))
                    .to.be.undefined

            it 'creates a new draft release if necessary', ->
                releases.find.withArgs('myowner', 'myrepo', match.func).returns When undefined
                artie.upload().then ->
                    releases.createDraft.should.have.been.calledWith 'myowner', 'myrepo', 'v2.3.0-1-g05fc9e7'
                    releases.upload.should.have.been.calledWith 'myowner', 'myrepo', 3

            it 'uploads the artifact', ->
                releases.find.withArgs('myowner', 'myrepo', match.func).returns When
                    id: 1, draft: true, prerelease: false, tag_name: null, target_commitish: 'master'
                artie.upload().then ->
                    releases.upload.should.have.been.calledWith 'myowner', 'myrepo', 1,
                        'myrepo-v2.3.0-1-g05fc9e7-bin-linux-x64.nar', '/dir/myrepo-v2.3.0-1-g05fc9e7-bin-linux-x64.nar'

            it 'deletes previous draft releases for this branch', ->
                releases.find.withArgs('myowner', 'myrepo', match.func).returns When
                    id: 1, draft: true, prerelease: false, tag_name: null, target_commitish: 'master'
                releases.findAll.returns When [ { id: 1 }, { id: 2 } ]
                artie.upload().then ->
                    fn = releases.findAll.firstCall.args[2]
                    expect(fn { draft: true, name: 'v2.3.0-1-g05fc9e7', body: 'This is an automatically created draft'}).to.not.be.ok
                    expect(fn { draft: true, name: 'v2.0.6-5-g7ebe6bc', body: 'This is an automatically created draft'}).to.be.ok
                    expect(fn { draft: false, name: 'v2.0.6-5-g7ebe6bc', body:'This is an automatically created draft'}).to.not.be.ok
                    expect(fn { draft: true, name: 'v2.0.6-5-g7ebe6bc', body: 'Dont delete be bro!'}).to.not.be.ok

                    releases.deleteRelease.should.have.been.calledWith 'myowner', 'myrepo', 1
                    releases.deleteRelease.should.have.been.calledWith 'myowner', 'myrepo', 2

            it 'does not fail the build if unable to delete previous drafts', ->
                releases.find.withArgs('myowner', 'myrepo', match.func).returns When
                    id: 1, draft: true, prerelease: false, tag_name: null, target_commitish: 'master'
                releases.findAll.returns When [ { id: 1 }, { id: 2 } ]
                releases.deleteRelease.returns When.reject { message: "Not allowed", code: 405 }
                artie.upload().should.eventually.be.fulfilled

    describe '.download()', ->
        Artie = artie = fs = opts = cfg = artifact = releases = undefined
        beforeEach ->
            fs =
                realpath: (path, cb) -> cb undefined, path
                symlink: (src, dest, cb) -> cb undefined, undefined
                unlink: (path, cb) -> cb undefined
            Artie = proxyquire '../lib/artie', { 'fs', fs }
            opts = { os: 'linux', arch: 'x64', production: false }
            cfg = {}
            artifact = {}
            releases =
                find: stub().returns When { name: 'v2.0.6-5-g7ebe6bc', draft: true }
                download: stub().returns When false
            artie = new Artie opts, cfg, artifact, releases

        it 'looks for the latest non-pre release', ->
            artie.download().then ->
                fn = releases.find.firstCall.args[2]
                expect(fn { draft: true, prerelease: false, assets: [{ name: 'myrepo-v2.0.6-5-g7ebe6bc-bin-linux-x64.nar' }]}).to.not.be.undefined
                expect(fn { draft: false, prerelease: false, assets: [{ name: 'myrepo-v2.0.6-5-g7ebe6bc-bin-linux-x64.nar' }]}).to.not.be.undefined
                expect(fn { draft: true, prerelease: false, assets: [{ name: 'myrepo-v2.0.6-5-g7ebe6bc-bin-darwin-x64.nar' }]}).to.be.undefined
                expect(fn { draft: true, prerelease: true, assets: [{ name: 'myrepo-v2.0.6-5-g7ebe6bc-bin-linux-x64.nar' }]}).to.be.undefined

        it 'only looks for production releases if run with -p', ->
            opts.production = true
            artie.download().then ->
                fn = releases.find.firstCall.args[2]
                expect(fn { draft: true, prerelease: false, assets: [{ name: 'myrepo-v2.0.6-5-g7ebe6bc-bin-linux-x64.nar' }]}).to.be.undefined
                expect(fn { draft: false, prerelease: false, assets: [{ name: 'myrepo-v2.0.6-5-g7ebe6bc-bin-linux-x64.nar' }]}).to.not.be.undefined
                expect(fn { draft: false, prerelease: false, assets: [{ name: 'myrepo-v2.0.6-5-g7ebe6bc-bin-darwin-x64.nar' }]}).to.be.undefined
                expect(fn { draft: false, prerelease: true, assets: [{ name: 'myrepo-v2.0.6-5-g7ebe6bc-bin-linux-x64.nar' }]}).to.be.undefined
