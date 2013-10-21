# A empty testcase
class TestCase
  def initialize test_file
    @testcase = Urushiol::VarnishTestBase.new("#{test_file}")
  end

  def testcase
    @testcase
  end
end