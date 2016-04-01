Slack     = require 'slack-node'
log       = require 'bog'

module.exports = do ->
    unless slackWebhookUri = process.env.SLACK_WEBHOOK
        return ->

    channel = process.env.SLACK_CHANNEL ? 'general'

    slack = new Slack()
    slack.setWebhook slackWebhookUri
    (msg) ->
        slack.webhook {
            channel: "##{channel}"
            username: "artie"
            icon_emoji: ":artie:"
            text: msg
        }, (err, resp) ->
            log.debug err if err
