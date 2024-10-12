require "../spec_helper.cr"
require "../../src/lib/crystal-base-template"

describe Crystal::Base::Template do
  describe "#add" do
    it "adds two numbers together" do
      Crystal::Base::Template.add(1, 2).should eq(3)
    end
  end
end
