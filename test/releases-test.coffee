Releases = require '../lib/releases'
When     = require 'when'

describe 'Releases', ->
    releases = opts = client = undefined

    describe '.find()', ->
        beforeEach ->
            client =
                releases:
                    listReleases: stub()
            client.releases.listReleases.onFirstCall().callsArgWith 1, undefined, [ { id: 1 }, { id: 2 } ]
            client.releases.listReleases.onSecondCall().callsArgWith 1, undefined, [ { id: 3 }, { id: 4 } ]
            client.releases.listReleases.onThirdCall().callsArgWith 1, undefined, [ ]
            opts = {}
            releases = new Releases opts, client

        it 'scrolls through pages to find the first match', ->
            releases.find('owner', 'repo', (rel) -> if rel.id > 2 then rel)
            .then (res) ->
                res.id.should.equal 3

        it 'returns undefined if no match was found', ->
            releases.find('owner', 'repo', (rel) -> if rel.id > 8 then rel)
            .then (res) ->
                expect(res).to.be.undefined

        it 'propagates errors back to the caller', ->
            client.releases.listReleases.onSecondCall().callsArgWith 1, { message: 'such fail!' }
            releases.find('owner', 'repo', (rel) -> if rel.id > 4 then rel)
            .should.be.rejectedWith 'such fail!'

    describe '.findAll()', ->
        beforeEach ->
            client =
                releases:
                    listReleases: stub()
            client.releases.listReleases.onFirstCall().callsArgWith 1, undefined, [ { id: 1 }, { id: 2 } ]
            client.releases.listReleases.onSecondCall().callsArgWith 1, undefined, [ { id: 3 }, { id: 4 } ]
            client.releases.listReleases.onThirdCall().callsArgWith 1, undefined, [ ]
            opts = {}
            releases = new Releases opts, client

        it 'scrolls through pages to find all matches', ->
            releases.findAll('owner', 'repo', (rel) -> rel.id > 1)
            .then (res) ->
                res.should.eql [ { id: 2 }, { id: 3 }, { id: 4 } ]

        it 'returns an empty list if no matches were found', ->
            releases.findAll('owner', 'repo', (rel) -> rel.id > 8)
            .then (res) ->
                res.should.eql [ ]
