
# git-deploy

git-deploy is an ultra-lightweight continuous deployment tool packaged as a git plugin.

git-deploy works by creating a bare repository on a remote server, with receive hooks that run a command to deploy your code. By default git-deploy uses `make` but it can be configured to use any build tool, or just a simple shell script.

## Installation

Like all git plugins, to install git-deploy you simply add it to your PATH. 

There are many ways to do this. Here is one way that will only change the path in the current terminal session. You'll probably want something more permanent.

```
$ git clone https://github.com/benrady/git-deploy.git
$ export PATH=$PWD/git-deploy/bin:$PATH
```

## Usage

First, if you don't already have one, you need to create a makefile. This makefile should have a target named `git-deploy` that takes the current working directory and does whatever you need to do to deploy your code.

For example, if you have a static web application in the `public` directory of your repository, you'll want a makefile that looks like this:

If you have a Ruby application that can be run from a /service directory using a tool like [runit](http://smarden.org/runit/) or [daemontools](https://cr.yp.to/daemontools.html), you can create a symlink to the /service directory

If you have a Java application that needs to be compiled first, you'll want something like this:

## Continuous Integration

The hooks that git-deploy installs will reject a push if the build command fails. This means you can add tests or other sanity checks to the build to ensure that everything that is deployed passes a minimum threshold of correctness. If the build fails, the currently running service will not be interrupted.

## Rollback

git-deploy keeps a copy of every version of your application that you've ever deployed. These are kept (named for the SHA of the HEAD commit) in the ~/.git-deploy/[repo name].git/.build directory on the remote server.

You can simple list the subdirectories in this directory to see what versions you've deployed. `ls -alt` is useful here. 

[[ Example output here ]]

To roll back to a specific version, run `make git-deploy` from inside one of those directories. This will re-run the deploy for that version and roll your service back. Any logs or data files that were in that directory will have been preserved, allowing you to roll your application state back along with the code.

## Special Cases and FAQ

### Why won't my application stop running?
Using a service manager like runit or daemontools means you need to understand how your process starts and stops. These tools send a (signal)[] to the run script in your application when they're supposed to stop. If that's not sufficient, you may need to take steps in your makefile to shut down the existing service.
