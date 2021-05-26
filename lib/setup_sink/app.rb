require "redis"
require "json"

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
      if match = env["PATH_INFO"].match(/^\/metrics\/(?<project>.*)/)
        metrics = return_metrics(match[:project])
        if metrics
          response = JSON.generate(metrics)
          return [200, {"Content-Type"=>"application/json"}, [response]]
        else
          return [404, {"Content-Type"=>"application/json"}, [JSON.generate({ error: "No such project \"#{match[:project]}\" found" })]]
        end
      else
        [200, {}, ["Path Info: #{env["PATH_INFO"]}"]]
      end
    end

    def post(env)
      path = env['PATH_INFO']
      case path
      when "/metrics"
        if store_metrics(JSON.parse(env['rack.input'].read))
          return [201, {}, [JSON.generate( { message: "Metrics stored correctly" })]]
        else
          return [404, {}, [JSON.generate( { error: "Metrics not stored correctly" })]]
        end
      when "/delete"
        if delete_project(split_path[2])
          return [201, {}, ["#{split_path[2]} deleted"]]
        else
          return [404, {}, ["No such project \"#{split_path[2]}\" found"]]
        end
      when "/_delete_all"
        if delete_all
          return [201, {}, ["database deleted"]]
        else
          return [409, {}, ["Database not deleted correctly"]]
        end
      when "/all"
        projects = get_all
        if projects.length > 0
          return [201, {}, ["All Projects: #{projects}"]]
        else
          return [404, {}, ["No projects in database"]]
        end
      else
        
      end
      [201, {}, ["Path Info: #{env["PATH_INFO"]}"]]
    end

    def store_metrics(req)
      project = req["project"]
      if !@redis.exists?(project)
        hash = {
          start_time: req["start_time"],
          number_of_setups: 1,
          successes: req["success"] == "true" ? 1 : 0,
          success_rate: req["success"] == "true" ? 1 : 0,
          average_duration: req["duration"]
        }
      else
        hash = get_metrics(project)
        number_of_setups = hash["number_of_setups"].to_i
        successes = hash["successes"].to_i
        success_rate = hash["success_rate"].to_f
        average_duration = hash["average_duration"].to_f

        hash["number_of_setups"] = number_of_setups + 1
        if req["success"] == "true"
          hash["successes"] = successes + 1
        end
        hash["success_rate"] = ((hash["successes"].to_f) / (number_of_setups + 1)).to_f
        hash["average_duration"] = (average_duration + req["duration"].to_f) / 2
      end
      field_count = @redis.hset(project, hash)
      field_count == hash.keys.length
    end

    def get_metrics(project)
      if @redis.exists?(project)
        @redis.hgetall(project)
      end
    end

    def return_metrics(project)
      if @redis.exists?(project)
        project = @redis.hgetall(project)
        return {
          success_rate: (project["success_rate"].to_f*100.0).round(2),
          average_duration: project["average_duration"].to_f.round(2),
          number_of_setups: project["number_of_setups"].to_i
        }
      end
    end

    def delete_project(project)
      if @redis.exists?(project)
        @redis.del(project)
        true
      else
        false
      end
    end

    def get_all
      @redis.scan_each.to_a
    end

    def delete_all
      @redis.scan_each do |key|
        @redis.del(key)
      end
      if @redis.scan_each.to_a.length == 0
        true
      else
        false
      end
    end
  end
end