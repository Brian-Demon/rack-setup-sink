require "redis"

module SetupSink
  class App
    def initialize(host:, port:)
      @redis = Redis.new(host: host, port: port)
    end

    def call(env)
      case env["REQUEST_METHOD"]
      when "GET"
        get(env)
      when "POST"
        post(env)
      else
        [422, {}, ["Invalid Request"]]
      end
    end

    def get(env)
      [200, {}, ["OK"]]
    end

    def post(env)
      [201, {}, ["Created"]]
    end
  end
end