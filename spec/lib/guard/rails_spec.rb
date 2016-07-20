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
    let(:expect_ui_update) {
      expect(Guard::UI).to receive(:info).with(/#{Guard::Rails::DEFAULT_OPTIONS[:port]}/)
    }

    context "starts when Guard starts" do
      it "shows the right message and runs startup" do
        expect(guard).to receive(:reload).with("start").once
        expect_ui_update
        guard.start
      end
    end

    context "doesn't start when Guard starts" do
      let(:options) { { start_on_start: false } }

      it "shows the right message and doesn't run startup" do
        expect(guard).to receive(:reload).never
        expect_ui_update
        guard.start
      end
    end
  end

  describe '#reload' do
    let(:pid) { '12345' }

    before do
      allow_any_instance_of(Guard::Rails::Runner).to receive(:pid).and_return(pid)
    end

    context 'at start' do
      before do
        expect(Guard::UI).to receive(:info).with('Starting Rails...')
        expect(Guard::Notifier).to receive(:notify).with(/Rails starting/, hash_including(image: :pending))
        allow_any_instance_of(Guard::Rails::Runner).to receive(:restart).and_return(true)
      end

      it "starts and shows the pid file" do
        expect(Guard::UI).to receive(:info).with(/#{pid}/)
        expect(Guard::Notifier).to receive(:notify).with(/Rails started/, hash_including(image: :success))

        guard.reload("start")
      end
    end

    context "after start" do
      before do
        allow_any_instance_of(Guard::Rails::Runner).to receive(:pid).and_return(pid)
        expect(Guard::UI).to receive(:info).with('Restarting Rails...')
        expect(Guard::Notifier).to receive(:notify).with(/Rails restarting/, hash_including(image: :pending))
      end

      context "with pid file" do
        before do
          allow_any_instance_of(Guard::Rails::Runner).to receive(:restart).and_return(true)
        end

        it "restarts and shows the pid file" do
          expect(Guard::UI).to receive(:info).with(/#{pid}/)
          expect(Guard::Notifier).to receive(:notify).with(/Rails restarted/, hash_including(image: :success))

          guard.reload
        end
      end

      context "without pid file" do
        before do
          allow_any_instance_of(Guard::Rails::Runner).to receive(:restart).and_return(false)
        end

        it "restarts and shows the pid file" do
          expect(Guard::UI).to receive(:info).with(/#{pid}/).never
          expect(Guard::UI).to receive(:info).with(/Rails NOT restarted/)
          expect(Guard::Notifier).to receive(:notify).with(/Rails NOT restarted/, hash_including(image: :failed))

          guard.reload
        end
      end
    end
  end

  describe "#stop" do
    it "stops with correct message" do
      expect(Guard::Notifier).to receive(:notify).with('Until next time...', anything)
      guard.stop
    end
  end

  describe '#run_on_change' do
    it "reloads on change" do
      expect(guard).to receive(:reload).once
      guard.run_on_change([])
    end
  end
end

