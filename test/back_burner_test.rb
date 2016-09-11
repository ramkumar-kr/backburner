require File.expand_path('../test_helper', __FILE__)

$backburner_sum = 0
$backburner_numbers = []

class TestBackburnerJob
  include Backburner::Queue
  queue "test.jobber"

  def self.perform(value, number)
    $backburner_sum += value
    $backburner_numbers << number
  end
end

class TestWorker < Backburner::Worker; end

describe "Backburner module" do
  before { Backburner.default_queues.clear }

  describe "for enqueue method" do
    before do
      Backburner.enqueue TestBackburnerJob, 5, 6
      Backburner.enqueue TestBackburnerJob, 15, 10
      silenced(2) do
        worker = Backburner::Workers::Simple.new('test.jobber')
        worker.prepare
        2.times { worker.work_one_job }
      end
    end

    it "can run jobs using #run method" do
      assert_equal 20, $backburner_sum
      assert_same_elements [6, 10], $backburner_numbers
    end
  end # enqueue

  describe "for work method" do
    it "invokes worker simple start" do
      Backburner::Workers::Simple.expects(:start).with(["foo", "bar"])
      Backburner.work("foo", "bar")
    end

    it "invokes other worker if specified in configuration" do
      Backburner.configure { |config| config.default_worker = TestWorker }
      TestWorker.expects(:start).with(["foo", "bar"])
      Backburner.work("foo", "bar")
    end

    it "invokes other worker if specified in work method as options" do
      TestWorker.expects(:start).with(["foo", "bar"])
      Backburner.work("foo", "bar", :worker => TestWorker)
    end

    it "invokes worker start with no args" do
      Backburner::Workers::Simple.expects(:start).with([])
      Backburner.work
    end
  end # work!

  describe "for configuration" do
    it "remembers the tube_namespace" do
      assert_equal "demo.test", Backburner.configuration.tube_namespace
    end

    it "remembers the namespace_separator" do
      assert_equal ".", Backburner.configuration.namespace_separator
    end

    it "disallows a reserved separator" do
      assert_raises RuntimeError do
        Backburner.configuration.namespace_separator = ':'
      end
    end

    context 'hooks' do
      it 'are added as singleton methods' do
        Backburner.configure{ |config| config.hooks = [{class_name: Backburner::Job, event: 'before_enqueue', code_block: lambda { "Hello, World!" } }] }
        Backburner.configuration.attach_hooks
        assert_includes(Backburner::Job.singleton_methods, :before_enqueue)
      end

      it 'execute the code present in the lambda' do
        Backburner.configure{ |config| config.hooks = [{class_name: Backburner::Job, event: 'before_enqueue', code_block: lambda { "Hello, World!" } }] }
        Backburner.configuration.attach_hooks
        assert_equal("Hello, World!", Backburner::Job.before_enqueue)
      end
    end
  end # configuration

  describe "for default_queues" do
    it "supports assignment" do
      Backburner.default_queues << "foo"
      Backburner.default_queues << "bar"
      assert_same_elements ["foo", "bar"], Backburner.default_queues
    end
  end

  after do
    Backburner.configure { |config| config.default_worker = Backburner::Workers::Simple }
    Backburner::Job.send(:remove_method, :before_enqueue) if Backburner::Job.method_defined?(:before_enqueue)
  end
end # Backburner