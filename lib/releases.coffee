log     = require 'bog'
fs      = require 'fs'
moment  = require 'moment'
request = require 'request'
When    = require 'when'
ncall   = require('when/node').call

module.exports = class Releases

    constructor: (@opts, @client) ->

    find: (owner, repo, criteria) ->
        scroll = (page) =>
            ncall @client.releases.listReleases, { owner, repo, page }
            .then (res) ->
                return undefined if res.length is 0
                matches = res.map(criteria).filter (m) -> m
                if matches.length > 0
                    return matches[0]
                else
                    scroll page + 1
        scroll 0

    findAll: (owner, repo, criteria) ->
        matches = []
        scroll = (page) =>
            ncall(@client.releases.listReleases, { owner, repo, page })
            .then (res) ->
                return matches if res.length is 0
                matches.push r for r in res.filter criteria
                scroll page + 1
        scroll 0

    createRelease: (owner, repo, tag_name) ->
        ncall @client.releases.createRelease, { owner, repo, tag_name }

    createDraft: (owner, repo, branch, version) ->
        ncall @client.releases.createRelease, { owner, repo, tag_name: branch, draft: true, name: version, body: "This is an automatically created draft which holds release artifacts for the #{branch} branch." }

    deleteRelease: (owner, repo, id) ->
        ncall @client.releases.deleteRelease, { owner, repo, id }

    upload: (owner, repo, id, name, filePath) ->
        ncall @client.releases.uploadAsset, { owner, repo, id, name, filePath }

    download: (url, name) ->
        When.promise (resolve, reject) =>
            fs.stat name, (err, stats) =>
                modified = if stats then moment(stats.mtime).utc().format('ddd, DD MMM YYYY HH:mm:ss ') + 'GMT'
                request.get
                    url: url
                    headers:
                        'Authorization': "token #{@opts.token}"
                        'Accept': "application/octet-stream"
                        'User-Agent': 'artie'
                        'If-Modified-Since': modified
                .on 'error', (err) -> reject new Error err
                .on 'response', (res) ->
                    if res.statusCode is 304
                        log.info 'Local artifact newer than remote.'
                        resolve false
                    else
                        log.info 'Downloading...'
                        res.pipe(fs.createWriteStream(name))
                        .on 'error', (err) -> reject new Error err
                        .on 'finish', -> resolve true
