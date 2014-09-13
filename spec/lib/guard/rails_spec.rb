require 'spec_helper'
require 'guard/rails'

describe Guard::Rails do
  let(:guard) { Guard::Rails.new(options) }
  let(:options) { {} }

  describe "#initialize" do
    it "initializes with options" do
      guard

      expect(guard.runner.options[:port]).to eq 3000
    end
  end

  describe "#start" do
    let(:ui_expectation) { Guard::UI.expects(:info).with(regexp_matches(/#{Guard::Rails::DEFAULT_OPTIONS[:port]}/)) }

    context "starts when Guard starts" do
      it "shows the right message and runs startup" do
        guard.expects(:reload).once
        ui_expectation
        guard.start
      end
    end

    context "doesn't start when Guard starts" do
      let(:options) { { :start_on_start => false } }

      it "shows the right message and doesn't run startup" do
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

      it "starts and shows the pid file" do
        Guard::UI.expects(:info).with(regexp_matches(/#{pid}/))
        Guard::Notifier.expects(:notify).with(regexp_matches(/Rails started/), has_entry(:image => :success))

        guard.reload("start")
      end
    end

    context "after start" do
      before do
        Guard::RailsRunner.any_instance.stubs(:pid).returns(pid)
        Guard::UI.expects(:info).with('Restarting Rails...')
        Guard::Notifier.expects(:notify).with(regexp_matches(/Rails restarting/), has_entry(:image => :pending))
      end

      context "with pid file" do
        before do
          runner_stub.returns(true)
        end

        it "restarts and shows the pid file" do
          Guard::UI.expects(:info).with(regexp_matches(/#{pid}/))
          Guard::Notifier.expects(:notify).with(regexp_matches(/Rails restarted/), has_entry(:image => :success))

          guard.reload
        end
      end

      context "without pid file" do
        before do
          runner_stub.returns(false)
        end

        it "restarts and shows the pid file" do
          Guard::UI.expects(:info).with(regexp_matches(/#{pid}/)).never
          Guard::UI.expects(:info).with(regexp_matches(/Rails NOT restarted/))
          Guard::Notifier.expects(:notify).with(regexp_matches(/Rails NOT restarted/), has_entry(:image => :failed))

          guard.reload
        end
      end
    end
  end

  describe "#stop" do
    it "stops with correct message" do
      Guard::Notifier.expects(:notify).with('Until next time...', anything)
      guard.stop
    end
  end

  describe '#run_on_change' do
    it "reloads on change" do
      guard.expects(:reload).once
      guard.run_on_change([])
    end
  end
end

