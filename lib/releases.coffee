log     = require 'bog'
fs      = require 'fs'
moment  = require 'moment'
request = require 'request'
When    = require 'when'

module.exports = class Releases

    constructor: (@opts, @client) ->

    find: (owner, repo, criteria) ->
        When.promise (resolve, reject) =>
            scroll = (page) =>
                @client.releases.listReleases { owner, repo, page }, (err, res) =>
                    if err
                        reject new Error err.message
                    else
                        if res.length is 0
                            resolve undefined
                        else
                            matches = res.map(criteria).filter (m) -> m
                            if matches.length > 0
                                resolve matches[0]
                            else
                                scroll page + 1
            scroll 0

    upload: (owner, repo, id, name, filePath) ->
        When.promise (resolve, reject) =>
            @client.releases.uploadAsset { owner, repo, id, name, filePath }, (err, res) =>
                if err
                    reject new Error err.message
                else
                    resolve()

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
