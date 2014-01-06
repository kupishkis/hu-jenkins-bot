# Description:
#   Pugme is the most important thing in your life
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   hubot pug me - Receive a pug
#   hubot pug bomb N - get N pugs

module.exports = (robot) ->

  robot.respond /pug me/i, (msg) ->
    msg.http("http://pugme.herokuapp.com/random")
      .get() (err, res, body) ->
        msg.send JSON.parse(body).pug

  robot.respond /pug bomb( (\d+))?/i, (msg) ->
    count = msg.match[2] || 5
    doPug = true
    if count < 5
      doPug = Math.random() > 0.3
    else if count < 10
      doPug = Math.random() > 0.5
    else if count < 20
      doPug = Math.random() > 0.7
    else if count < 30
      doPug = Math.random() > 0.97
    else
      msg.send "A BOMB."
      doPug = false
      return
    
    if doPug
      msg.http("http://pugme.herokuapp.com/bomb?count=" + count)
        .get() (err, res, body) ->
          msg.send pug for pug in JSON.parse(body).pugs
    else
      msg.send "La Bot does not want to do pug bomb right now."

  robot.respond /how many pugs are there/i, (msg) ->
    msg.http("http://pugme.herokuapp.com/count")
      .get() (err, res, body) ->
        msg.send "There are #{JSON.parse(body).pug_count} pugs."

