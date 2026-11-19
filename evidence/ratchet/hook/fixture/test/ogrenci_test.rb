require 'minitest/autorun'
require_relative '../lib/ogrenci'

class HookProbeTest < Minitest::Test
  def test_value
    assert_equal 1, Probe::VALUE
  end
end
