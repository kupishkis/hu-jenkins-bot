# Hubot

This is a modified version of GitHub's Campfire bot, hubot. He's pretty cool.

This version is designed to be run localy. It is prepared to hang in your configured hipchat room and notify you about jenkins build statuses.

### Running Hubot Locally

Install dependencies

    % npm install

Copy bin/hubot-local.loc to bin/hubot-local and edit the configuration inside.

You can test your hubot by running the following.

    % bin/hubot-local

You'll see some start up output and hubot will try to connect to the specified hipchat account.

### Jenkins

There are several modified scripts in /scripts directory.

The `jenkins.coffee` script is slightly modified to remove %20 from chat messages.

The `jenkins-notifier.coffee` is basically rewritten from scratch. It listens to jenkins notifications (configured over jenkins notifications plugin) and sends information about build status to hipchat, changes the room topic with current build status. In case a build is failing or is unstable, it also sends detailed blame message with the name list :)
