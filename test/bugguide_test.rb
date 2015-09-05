require 'test_helper'

class BugGuideTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::BugGuide::VERSION
  end
end
