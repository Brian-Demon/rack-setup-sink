# frozen_string_literal: true

require "test_helper"

class SetupSinkTest < Minitest::Test
  include Rack::Test::Methods
  def test_that_it_has_a_version_number
    refute_nil ::SetupSink::VERSION
  end

  def teardown
    delete_all
  end

  def redis_client
    @redis ||= Redis.new(host: "localhost", port: 6379) 
  end

  def delete_all
    redis_client.scan_each do |key|
      redis_client.del(key)
    end
    if redis_client.scan_each.to_a.length == 0
      true
    else
      false
    end
  end

  def app
    Rack::Builder.new do |builder|
      builder.use Rack::Session::Pool
      builder.run SetupSink::App.new(host: "localhost", port: 6379)
    end.to_app
  end

  def test_gets_ok_response_from_server
    get "/foo"

    assert last_response.ok?
  end

  def test_post_returns_ok
    data = {
      "success":"false",
      "duration":"1.8",
      "start_time":"678348792",
      "project":"test"
    }
    post "/metrics/test", JSON.generate(data)

    assert_equal 201, last_response.status
  end

  def test_post_stores_data_in_redis_correctly
    data = {
      "success":"false",
      "duration":"1.8",
      "start_time":"678348792",
      "project":"test"
    }
    json_data = JSON.generate(data)
    post "/metrics", json_data

    assert_equal 201, last_response.status
    assert redis_client.exists?("test")
  end

  def test_post_incements_metrics
    data = {
      "success":"false",
      "duration":"1.8",
      "start_time":"678348792",
      "project":"test"
    }
    post "/metrics", JSON.generate(data)

    get "/metrics/test"

    assert_equal 200, last_response.status

    parsed_data = JSON.parse(last_response.body)

    assert_equal 0, parsed_data["success_rate"]
    assert_equal 1.8, parsed_data["average_duration"]
    assert_equal 1, parsed_data["number_of_setups"]
  end
end
