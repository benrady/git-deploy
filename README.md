
# git-deploy

git-deploy is an ultra-lightweight continuous deployment tool packaged as a git plugin. It works by creating a bare repository on a remote server, with receive hooks that run a command to deploy your code. This creates a single point of integration and deployment that can be used by small and medium-sized teams that don't have the capacity or interest to set up more complex systems.

## Usage

To deploy all changes committed to a local git repository, run this command from inside the repository:

```
$ git deploy <servername>
```

<servername> must be a server that you have ssh access to. As with ssh, you may need to specify a username.

## Dependencies
 * Git  (Obviously)
 * Make (Used to run deployment tasks)

## Installation

Like all git plugins, to install git-deploy you add it to your PATH. You can [download the plugin here](https://raw.githubusercontent.com/benrady/git-deploy/master/bin/git-deploy).

## Setup

If you don't already have one, you need to create a [Makefile](http://mrbook.org/blog/tutorials/make/) in the root of your repository. This Makefile should have a target named `git-deploy` that does whatever you need to do to deploy your code. This will be run on the remote server after your repo is checked out by git-deploy.

For example, if you have a static website in the `public` directory of your repository, you'll want a Makefile that looks like this:

```Makefile
git-deploy:
        ln -f -s -T ${PWD}/public /var/www/html/my_app
```

If you have a Ruby/Python/Perl/etc application that can be run directly from a /service directory using a tool like [runit](http://smarden.org/runit/) or [daemontools](https://cr.yp.to/daemontools.html), you can create a symlink to the /service directory in this target:

```Makefile
git-deploy:
        ln -s -f -T ${PWD} /service/my_app
```

If you have a Java application that needs to be compiled, and uses a start/stop script to run as a daemon, you'll want something like this:

```Makefile
git-deploy:
        mvn package
        ~/my_app/scripts/stop
        ln -s -f -T ${PWD}/target ~/my_app
        ~/my_app/scripts/start
```


Of course, if you have a C/C++ application, you probably already have a Makefile. You'll just need to ensure your build dependencies are also on the server that you're deploying to.

```Makefile
git-deploy: release
        ln -s -f -T ${PWD}/build/release/my_service /usr/bin/my_service
```

## Continuous Integration

Taking advantage of the default behavior of git, a deploy will be rejected if not in sync with a previously deployed version of the application. This means if you haven't integrated with something that's already been deployed, you can't accidentally undo it by deploying another change.

Additionally, the hooks that git-deploy installs will reject a push if the build command fails. This means you can add tests or other sanity checks to the build to ensure that everything that is deployed passes a minimum threshold of correctness. If the build fails, the currently running service will not be interrupted.

## Isolation and Rollback

git-deploy keeps a copy of every version of your application that you've ever deployed. These are kept (named for the SHA of the HEAD commit) in the `~/.git-deploy/[repo name].git/.build` directory on the remote server. You can simply list the subdirectories in this directory to see what versions you've deployed. `ls -alt` is useful here.

By symlinking these directories to other parts of the filesystem (a runit [/service directory](http://smarden.org/runit/faq.html#tell), for example), and running the services out of those directories, you can control what files and data are shared between different versions of the app, and which are kept isolated from other versions.

This means, to roll back to a specific version, you can run `make git-deploy` from inside one of those directories. This will re-run the deploy for that version and roll your service back. Any logs or data files that were in that directory will have been preserved, allowing you to roll your application state back along with the code. Any files stored outside of that directory will remain unchanged.

## Configuration

You can configure the plugin by creating a `.git_deploy_conf` file in the root of your repository. This file is sourced when the plugin runs. There are two variables, `GIT_DEPLOY_SUCCESS` and `GIT_DEPLOY_SERVER` that can be set to control behavior. Both are optional.

 * `GIT_DEPLOY_SUCCESS` - A command (or bash function, as show below) to run locally after successfully deploying.
 * `GIT_DEPLOY_SERVER` - A default server to use, if one is not specified on the command line.

```bash
function on_success() {
  echo "Deploy Success! Pushing to central repository..."
  git push origin master
}

GIT_DEPLOY_SUCCESS=on_success
GIT_DEPLOY_SERVER=test.server.com
```

## Special Cases and FAQ

### Why won't my application stop running?
Using a service manager like runit or daemontools means you need to understand how your process starts and stops. These tools send a [signal](http://man7.org/linux/man-pages/man7/signal.7.html) to the run script in your application when they're supposed to stop. Be sure that you're using `exec` in your run script to _replace_ the bash process with python/ruby/java/binary so that it actually receives the signal.

If that's not sufficient, you may need to take steps in your makefile to shut down the existing service. You'll probably want to do this _after_ building and/or running tests though, because `make` will exit if there's an error and prevent a working service from being replaced by a failing one. For example:

```Makefile
git-deploy:
        mvn package
        pkill -f hard_to_kill.jar
        ln -s -f -T ${PWD} ~/service/hard_to_kill
```

### I deployed once but it didn't work. Now things are messed up.

The safest way to "reset" things is to delete:
 1. The bare repository on the remote server (located at ~/.git-deploy/[repo name].git/).
 2. The git-deploy remote that was added to your local git configuration. You'll see it when you run `git remote -v`.
