# frozen_string_literal: true

require "test_helper"

class SetupSinkTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::SetupSink::VERSION
  end
end
