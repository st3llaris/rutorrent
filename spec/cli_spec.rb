RSpec.describe Rutorrent::CLI do
  context ".start" do
    it "should exist" do
      expect(Rutorrent::CLI.respond_to?(:start)).to be true
    end
  end
end
