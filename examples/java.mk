git-deploy: # Called by the git-deploy plugin during a push
	mvn clean install
	ln -s -f -T ${PWD} ~/service/my_app
