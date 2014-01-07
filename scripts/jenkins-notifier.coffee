# Notifies about Jenkins build errors via Jenkins Notification Plugin
#
# Dependencies:
#   "url": ""
#   "querystring": ""
#
# Configuration:
#   Just put this url <HUBOT_URL>:<PORT>/hubot/jenkins-notify?room=<room> to your Jenkins
#   Notification config. See here: https://wiki.jenkins-ci.org/display/JENKINS/Notification+Plugin
#
# Commands:
#   None
#
# URLS:
#   POST /hubot/jenkins-notify?room=<room>[&type=<type>][&notstrat=<notificationSTrategy>]
#
# Notification Strategy is [Ff][Ss] which stands for "Failure" and "Success"
# Capitalized letter means: notify always
# small letter means: notify only if buildstatus has changed
# "Fs" is the default
# 
# Authors:
#   spajus
#   k9ert (notification strategy feature)
#   nercury (multiple builds, topic change)

url = require('url')
querystring = require('querystring')
statusCache = {}
lastTopic = ""

parseUser = (query) ->
	user = {}
	user.room = query.room if query.room
	user.type = query.type if query.type
	return user

chatBuildDescription = (data) ->
	console_link = "#{data.build.full_url}console"
	return "#{data.name} ##{data.build.number} (#{encodeURI(data.build.full_url)})\n (#{encodeURI(console_link)})"
	
topicBuildDescription = (data) ->
	return "#{data.name} ##{data.build.number}"

sendBlameMessage = (robot, user, full_build_url) ->
	req = robot.http("#{full_build_url}/api/json")
	req.get() (err, res, body) ->
	    response = ""
	    if err
	      console.log "Jenkins says: #{err}"
	    else
	      try
	        content = JSON.parse(body)
	        if content.changeSet.items.length > 0
	          response += "Last committers: \n"
	          for culprit in content.culprits
	              response += "- #{culprit.fullName}\n"
	          for item in content.changeSet.items
	            response += "\n#{item.comment}"
	      catch error
	        console.log error
	    robot.send user, "#{response}"

addStatusToCache = (data) ->
	if not statusCache[data.name]?
		statusCache[data.name] = {}
		
	statusCache[data.name].data = data
	
	if data.build.phase == 'FINISHED'
		statusCache[data.name].latestStatus = data.build.status

# prevent topic change spam if many updates during short interval
delayedUpdatesPending = 0
defaultDelayWindow = 5000

delayedUpdateTopicForAllBuilds = (robot, room) ->
	
	delayedUpdatesPending -= 1
	
	if delayedUpdatesPending == 0

		topic = ""
		
		keys = (k for k of statusCache).sort (a, b) -> a > b ? 1 : -1
		
		for dataName in keys
			dataInfo = statusCache[dataName]
		
			if topic != ""
				topic += " | "
				
			topicPrefix = ""
			if dataInfo.latestStatus?
			
				if dataInfo.latestStatus == 'SUCCESS'
					statusName = 'STABLE'
				else if dataInfo.latestStatus == 'FAILURE'
					statusName = 'FAILING'
				else
					statusName = dataInfo.latestStatus
				    
				topicPrefix += statusName
				if dataInfo.data.build.phase == 'STARTED'
					topicPrefix += " (BUILDING)"
			else
				topicPrefix += "BUILDING"
			topic += topicPrefix + ": " + (topicBuildDescription dataInfo.data)
		
		if topic != lastTopic
		  #console.log topic
		  robot.adapter.topic room, topic
		  lastTopic = topic
	  
updateTopicForAllBuilds = (robot, room) ->
	callback = -> delayedUpdateTopicForAllBuilds robot, room
	delayedUpdatesPending += 1
	setTimeout callback, defaultDelayWindow

module.exports = (robot) ->

  robot.router.post "/hubot/jenkins-notify", (req, res) ->

    @failing ||= []
    @unstable ||= []
    query = querystring.parse(url.parse(req.url).query)

    res.end('')

    user = parseUser query

    try
      data = req.body
      
      #console.log data
      
      #for key of req.body
      #  data = JSON.parse key

      addStatusToCache data
      updateTopicForAllBuilds robot, query.room

      if data.build.phase == 'FINISHED'
        if data.build.status == 'FAILURE' or data.build.status == 'UNSTABLE'
          if data.build.status == 'FAILURE'
            if data.name in @failing
              build = "STILL"
            else
              build = "STARTED"
              
            if data.name in @unstable
              index = @unstable.indexOf data.name
              @unstable.splice index, 1 if index isnt -1
            
            robot.send user, "#{build} FAILING: #{chatBuildDescription(data)}"
          
            @failing.push data.name unless data.name in @failing
          else
            if data.name in @unstable
              build = "STILL UNSTABLE"
            else
              build = "UNSTABLE"
              
            if data.name in @failing
              index = @failing.indexOf data.name
              @failing.splice index, 1 if index isnt -1
              
            robot.send user, "#{build}: #{chatBuildDescription(data)}"
          
            @unstable.push data.name unless data.name in @unstable
          
          sendBlameMessage robot, user, data.build.full_url
          
        if data.build.status == 'SUCCESS'
          if data.name in @failing
            index = @failing.indexOf data.name
            @failing.splice index, 1 if index isnt -1
            robot.send user, "BUILD RESTORED: #{topicBuildDescription(data)}"
          if data.name in @unstable
            index = @unstable.indexOf data.name
            @unstable.splice index, 1 if index isnt -1
            robot.send user, "BUILD IS STABLE: #{topicBuildDescription(data)}"

    catch error
      console.log "jenkins-notify error: #{error}. Data: #{req.body}"
      console.log error.stack

