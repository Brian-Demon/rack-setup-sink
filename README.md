# SetupSink

In this exercise, we're going to create a data sink server that accepts data about first-time setup of an application and sends that data to a [Redis Server](https://davidmles.medium.com/what-is-redis-a-gentle-introduction-using-ruby-ba4c4055b84b).  The purpose is to provide an interface to the Redis data store rather than have users interface directly with Redis.

To begin, run `bin/setup` to setup the environment and the data storage api.  This will pull down a Redis docker image and configure the server environment.  From there, you can use `bin/server` to start up both the Redis server and the Sink app, or `bin/test` to run tests.


# Exercise

The objective is to implement a `POST /metrics` endpoint that accepts a JSON payload containing the following keys: 

- `success` - Boolean.  Whether the setup was successful or not
- `duration` - Integer. Duration in seconds it took to setup
- `start_time` - Integer.  Time in seconds epoch
- `project` - String. The name of the project that's being setup

Given this request, it should store the information so that a `GET /metrics/:project` API call returns the following:

- Success rate of all setups for the specified project
- Average duration of all setups for the specified project
- Number of setups