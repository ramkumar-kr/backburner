require File.expand_path('../test_helper', __FILE__)

module NestedDemo
  class TestJobA; include Backburner::Queue; end
  class TestJobB; include Backburner::Queue; end
end

describe "Backburner::Queue module" do
  describe "contains known_job_classes" do
    it "has all defined job queues" do
      assert_contains Backburner.configuration.known_job_classes, NestedDemo::TestJobA
      assert_contains Backburner.configuration.known_job_classes, NestedDemo::TestJobB
    end
  end

  describe "for queue method accessor" do
    it "should return the queue name" do
      assert_equal "nested-demo/test-job-a", NestedDemo::TestJobA.queue
    end
  end # queue_name

  describe "for queue assignment method" do
    it "should allow queue name to be assigned" do
      NestedDemo::TestJobB.queue("nested/job")
      assert_equal "nested/job", NestedDemo::TestJobB.queue
    end
  end # queue
end # Backburner::Queue