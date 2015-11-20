Artie = require '../lib/artie'

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
