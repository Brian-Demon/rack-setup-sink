# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "bundler/setup"
require "setup_sink"
require "rack/test"
require "json"

require "minitest/autorun"
