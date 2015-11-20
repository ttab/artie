When = require 'when'

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
