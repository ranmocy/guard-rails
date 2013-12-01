require 'spec_helper'
require 'guard/rails'

describe Guard::Rails do
  let(:guard) { Guard::Rails.new(options) }
  let(:options) { {} }

  describe '#initialize' do
    it "should initialize with options" do
      guard

      guard.runner.options[:port].should == 3000
    end
  end

  describe '#start' do
    let(:ui_expectation) { Guard::UI.expects(:info).with(regexp_matches(/#{Guard::Rails::DEFAULT_OPTIONS[:port]}/)) }

    context 'start on start' do
      it "should show the right message and run startup" do
        guard.expects(:reload).once
        ui_expectation
        guard.start
      end
    end

    context 'no start on start' do
      let(:options) { { :start_on_start => false } }

      it "should show the right message and not run startup" do
        guard.expects(:reload).never
        ui_expectation
        guard.start
      end
    end
  end

  describe '#reload' do
    let(:pid) { '12345' }

    before do
      Guard::RailsRunner.any_instance.stubs(:pid).returns(pid)
    end

    let(:runner_stub) { Guard::RailsRunner.any_instance.stubs(:restart) }

    context 'at start' do
      before do
        Guard::UI.expects(:info).with('Starting Rails...')
        Guard::Notifier.expects(:notify).with(regexp_matches(/Rails starting/), has_entry(:image => :pending))
        runner_stub.returns(true)
      end

      it "should start and show the pid file" do
        Guard::UI.expects(:info).with(regexp_matches(/#{pid}/))
        Guard::Notifier.expects(:notify).with(regexp_matches(/Rails started/), has_entry(:image => :success))

        guard.reload("start")
      end
    end

    context 'after start' do
      before do
        Guard::RailsRunner.any_instance.stubs(:pid).returns(pid)
        Guard::UI.expects(:info).with('Restarting Rails...')
        Guard::Notifier.expects(:notify).with(regexp_matches(/Rails restarting/), has_entry(:image => :pending))
      end

      context 'with pid file' do
        before do
          runner_stub.returns(true)
        end

        it "should restart and show the pid file" do
          Guard::UI.expects(:info).with(regexp_matches(/#{pid}/))
          Guard::Notifier.expects(:notify).with(regexp_matches(/Rails restarted/), has_entry(:image => :success))

          guard.reload
        end
      end

      context 'no pid file' do
        before do
          runner_stub.returns(false)
        end

        it "should restart and show the pid file" do
          Guard::UI.expects(:info).with(regexp_matches(/#{pid}/)).never
          Guard::UI.expects(:info).with(regexp_matches(/Rails NOT restarted/))
          Guard::Notifier.expects(:notify).with(regexp_matches(/Rails NOT restarted/), has_entry(:image => :failed))

          guard.reload
        end
      end
    end
  end

  describe '#stop' do
    it "should stop correctly" do
      Guard::Notifier.expects(:notify).with('Until next time...', anything)
      guard.stop
    end
  end

  describe '#run_on_modifications' do
    it "should reload on modifications" do
      guard.expects(:reload).once
      guard.run_on_modifications([])
    end
  end
end

