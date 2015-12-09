log      = require 'bog'
fs       = require 'fs'
moment   = require 'moment'
https    = require 'https'
When     = require 'when'
ncall    = require('when/node').call
tmp      = require 'tmp'
urlParse = require('url').parse

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
        scroll 1

    findAll: (owner, repo, criteria) ->
        matches = []
        scroll = (page) =>
            ncall(@client.releases.listReleases, { owner, repo, page })
            .then (res) ->
                return matches if res.length is 0
                matches.push r for r in res.filter criteria
                scroll page + 1
        scroll 1

    createRelease: (owner, repo, tag_name) ->
        ncall @client.releases.createRelease, { owner, repo, tag_name, name: tag_name }

    createDraft: (owner, repo, version) ->
        ncall @client.releases.createRelease, { owner, repo, tag_name: version, draft: true, name: version, body: "This is an automatically created draft which holds development artifacts." }

    deleteRelease: (owner, repo, id) ->
        log.debug "Deleting release #{owner}/#{repo}/#{id}"
        ncall @client.releases.deleteRelease, { owner, repo, id }

    upload: (owner, repo, id, name, filePath) ->
        ncall @client.releases.uploadAsset, { owner, repo, id, name, filePath }

    download: (url, name) ->
        When.all([
            ncall(fs.stat, name).catch(->)
            ncall tmp.file
        ]).spread (stats, [tmpPath, tmpFd]) =>
            # helper fn
            request = (url, headers) ->
                delete headers[key] for key, val of headers when not val
                When.promise (resolve, reject) =>
                    params = urlParse url
                    params.headers = headers
                    https.get params, (res) ->
                        resolve res
                    .on 'error', (err) -> reject err

            When.promise (resolve, reject) =>
                modified = if stats then moment(stats.mtime).utc().format('ddd, DD MMM YYYY HH:mm:ss ') + 'GMT'
                request url,
                    'Authorization': "token #{@opts.token}"
                    'Accept': "application/octet-stream"
                    'User-Agent': 'artie'
                .then (res) ->
                    request res.headers.location, { 'If-Modified-Since': modified }
                    .then (res) ->
                        if res.statusCode is 304
                            log.info 'Nothing to do here; local artifact newer than remote.'
                            resolve false
                        else
                            log.info 'Downloading...'
                            When.promise (resolve, reject) ->
                                res.pipe(fs.createWriteStream(undefined, { fd: tmpFd }))
                                .on 'error', (err) -> reject new Error err
                                .on 'finish', -> resolve()
                            .then -> ncall fs.rename, tmpPath, name
                            .then -> resolve true
