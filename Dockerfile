FROM jgreat/vote-demo-base
MAINTAINER Team STAR-LORD

#add repo
ADD . /app

#Change the working directory to the app root
WORKDIR /app

#add entrypoint and start up scripts
ADD .docker /usr/local/bin

#entrypoint script to set env vars when linking containers for dev
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

#Default command to run on start up
CMD ["/usr/local/bin/start-app.sh"]
