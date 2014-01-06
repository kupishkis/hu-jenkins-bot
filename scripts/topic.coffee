# Description:
#   Command to change the channel topic.
#
# Commands:
#   hubot topic - Set a new topic

module.exports = (robot) ->
  robot.respond /SET.TOPIC.(.+)$/i, (msg) ->
    msg.topic msg.match[1]