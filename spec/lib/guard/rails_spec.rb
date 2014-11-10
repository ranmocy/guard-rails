require 'spec_helper'

describe Guard::Rails do
  let(:guard) { Guard::Rails.new(options) }
  let(:options) { {} }

  describe "#initialize" do
    it "initializes with default options" do
      guard

      expect(guard.runner.options[:host]).to eq "localhost"
      expect(guard.runner.options[:port]).to eq 3000
    end
  end

  describe "#start" do
    let(:ui_expectation) { mock(Guard::UI).info.with(/#{Guard::Rails::DEFAULT_OPTIONS[:port]}/) }

    context "starts when Guard starts" do
      it "shows the right message and runs startup" do
        mock(guard).reload.with("start").once
        ui_expectation
        guard.start
      end
    end

    context "doesn't start when Guard starts" do
      let(:options) { { start_on_start: false } }

      it "shows the right message and doesn't run startup" do
        mock(guard).reload.never
        ui_expectation
        guard.start
      end
    end
  end

  describe '#reload' do
    let(:pid) { '12345' }

    before do
      any_instance_of(Guard::Rails::Runner, pid: pid)
    end

    context 'at start' do
      before do
        mock(Guard::UI).info.with('Starting Rails...')
        mock(Guard::Notifier).notify.with(/Rails starting/, hash_including(image: :pending))
        any_instance_of(Guard::Rails::Runner, restart: true)
      end

      it "starts and shows the pid file" do
        mock(Guard::UI).info.with(/#{pid}/)
        mock(Guard::Notifier).notify.with(/Rails started/, hash_including(image: :success))

        guard.reload("start")
      end
    end

    context "after start" do
      before do
        any_instance_of(Guard::Rails::Runner, pid: pid)
        mock(Guard::UI).info.with('Restarting Rails...')
        mock(Guard::Notifier).notify.with(/Rails restarting/, hash_including(image: :pending))
      end

      context "with pid file" do
        before do
          any_instance_of(Guard::Rails::Runner, restart: true)
        end

        it "restarts and shows the pid file" do
          mock(Guard::UI).info.with(/#{pid}/)
          mock(Guard::Notifier).notify.with(/Rails restarted/, hash_including(image: :success))

          guard.reload
        end
      end

      context "without pid file" do
        before do
          any_instance_of(Guard::Rails::Runner, restart: false)
        end

        it "restarts and shows the pid file" do
          mock(Guard::UI).info.with(/#{pid}/).never
          mock(Guard::UI).info.with(/Rails NOT restarted/)
          mock(Guard::Notifier).notify.with(/Rails NOT restarted/, hash_including(image: :failed))

          guard.reload
        end
      end
    end
  end

  describe "#stop" do
    it "stops with correct message" do
      mock(Guard::Notifier).notify.with('Until next time...', anything)
      guard.stop
    end
  end

  describe '#run_on_change' do
    it "reloads on change" do
      mock(guard).reload.once
      guard.run_on_change([])
    end
  end
end

