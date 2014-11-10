require 'spec_helper'
require 'fakefs/spec_helpers'

describe Guard::Rails::Runner do
  let(:runner) { Guard::Rails::Runner.new(options) }

  let(:default_options) { Guard::Rails::DEFAULT_OPTIONS }
  let(:options) { default_options }

  let(:default_environment) { default_options[:environment] }
  let(:default_host) { default_options[:host] }
  let(:default_port) { default_options[:port] }

  describe '#pid' do
    include FakeFS::SpecHelpers

    context 'when pid file exists' do
      let(:pid) { 12345 }

      before do
        FileUtils.mkdir_p File.split(runner.pid_file).first
        File.open(runner.pid_file, 'w') { |fh| fh.print pid }
      end

      it "reads the pid" do
        expect(runner.pid).to eq(pid)
      end
    end

    context 'when pid file does not exist' do
      it "returns nil" do
        expect(runner.pid).to be nil
      end
    end

    context 'when custom rails root given' do
      let(:options) { default_options.merge(root: 'spec/dummy') }
      let(:pid) { 12345 }

      before do
        FileUtils.mkdir_p File.split(runner.pid_file).first
        File.open(runner.pid_file, 'w') { |fh| fh.print pid }
      end

      it "points to the right pid file" do
        expect(runner.pid_file).to match %r{spec/dummy/tmp/pids/#{default_environment}.pid}
      end
    end

  end

  describe '#build_command' do
    context "with options[:CLI]" do
      let(:custom_cli) { 'custom_CLI_command' }
      let(:options) { default_options.merge(CLI: custom_cli) }
      it "has customized CLI" do
        expect(runner.build_command).to match(%r{#{custom_cli} --pid })
      end

      let(:custom_pid_file) { "tmp/pids/rails_dev.pid" }
      let(:options) { default_options.merge(CLI: custom_cli, pid_file: custom_pid_file) }
      it "uses customized pid_file" do
        pid_file_path = File.expand_path custom_pid_file
        expect(runner.build_command).to match(%r{#{custom_cli} --pid \"#{pid_file_path}\"})
      end
    end

    context "without options[:daemon]" do
      it "doesn't have daemon switch" do
        expect(runner.build_command).not_to match(%r{ -d})
      end
    end

    context "with options[:daemon]" do
      let(:options) { default_options.merge(daemon: true) }
      it "has a daemon switch" do
        expect(runner.build_command).to match(%r{ -d})
      end
    end

    context "without options[:env]" do
      it "has environment switch to default" do
        expect(runner.build_command).to match(%r{ -e #{default_environment}})
      end
    end

    context "with options[:environment] as test" do
      let(:options) { default_options.merge(environment: 'test') }
      it "has environment switch to test" do
        expect(runner.build_command).to match(%r{ -e test})
      end
    end

    context 'with options[:debugger]' do
      let(:options) { default_options.merge(debugger: true) }

      it "has a debugger switch" do
        expect(runner.build_command).to match(%r{ -u})
      end
    end

    context 'with options[:server] as thin' do
      let(:options) { default_options.merge(server: 'thin') }

      it "has the server name thin" do
        expect(runner.build_command).to match(%r{thin})
      end
    end

    context "without options[:pid_file]" do
      it "uses default pid_file" do
        pid_file_path = File.expand_path "tmp/pids/#{default_environment}.pid"
        expect(runner.build_command).to match(%r{ --pid \"#{pid_file_path}\"})
      end
    end

    context "with options[:pid_file]" do
      let(:custom_pid_file) { "tmp/pids/rails_dev.pid" }
      let(:options) { default_options.merge(pid_file: custom_pid_file) }

      it "uses customized pid_file" do
        pid_file_path = File.expand_path custom_pid_file
        expect(runner.build_command).to match(%r{ --pid \"#{pid_file_path}\"})
      end
    end

    context 'with options[:host]' do
      let(:host) { "1.2.3.4" }
      let(:options) { default_options.merge(host: host) }

      it 'use customized host' do
        expect(runner.build_command).to match(/ -b #{host}/)
      end
    end

    context 'without options[:host]' do
      it 'use deafult host' do
        expect(runner.build_command).to match(/ -b #{default_host}/)
      end
    end

    context 'with options[:port]' do
      let(:port) { 3456 }
      let(:options) { default_options.merge(port: port) }

      it 'use customized port' do
        expect(runner.build_command).to match(/ -p #{port}/)
      end
    end

    context 'without options[:port]' do
      it 'use default port' do
        expect(runner.build_command).to match(/ -p #{default_port}/)
      end
    end

    context "with options[:zeus]" do
      let(:options) { default_options.merge(zeus: true) }
      it "has zeus" do
        expect(runner.build_command).to match(%r{zeus server })
      end

      context "with options[:zeus_plan]" do
        let(:options) { default_options.merge(zeus: true, zeus_plan: 'test_server') }
        it "uses customized zeus plan" do
          expect(runner.build_command).to match(%r{zeus test_server})
        end

        context "with options[:server]" do
          let(:options) { default_options.merge(zeus: true, zeus_plan: 'test_server', server: 'thin') }
          it "uses customized server" do
            expect(runner.build_command).to match(%r{zeus test_server .* thin})
          end
        end
      end
    end

    context "without options[:zeus]" do
      it "doesn't have zeus" do
        expect(runner.build_command).to_not match(%r{zeus server })
      end

      let(:options) { default_options.merge(zeus_plan: 'test_server') }
      it "doesnt' have test_server" do
        expect(runner.build_command).to_not match(%r{test_server})
      end
    end

    context 'with options[:root]' do
      let(:options) { default_options.merge(root: 'spec/dummy') }

      it "has `cd` command with customized rails root" do
        expect(runner.build_command).to match(%r{cd .*/spec/dummy\" &&})
      end
    end
  end

  describe '#environment' do
    it "sets RAILS_ENV to default" do
      expect(runner.environment["RAILS_ENV"]).to eq default_environment
    end

    context "with options[:environment] as test" do
      let(:options) { default_options.merge(environment: 'test') }

      it "sets RAILS_ENV to test" do
        expect(runner.environment["RAILS_ENV"]).to eq "test"
      end

      context "with options[:zeus]" do
        let(:options) { default_options.merge(zeus: true) }

        it "sets RAILS_ENV to nil" do
          expect(runner.environment["RAILS_ENV"]).to be nil
        end
      end
    end
  end

  describe '#run_rails_command' do
    before do
      @bundler_env = ENV['BUNDLE_GEMFILE']
      stub(runner).build_command.returns("printenv BUNDLE_GEMFILE > /dev/null")
    end
    after do
      ENV['BUNDLE_GEMFILE'] = @bundler_env
    end

    shared_examples "inside of bundler" do
      it 'runs rails inside of bundler' do
        expect(runner.send(:run_rails_command!)).to be true
      end
    end

    shared_examples "outside of bundler" do
      it 'runs rails outside of bundler' do
        expect(runner.send(:run_rails_command!)).to be false
      end
    end

    context 'when guard-rails is inside of bundler' do
      before do
        ENV['BUNDLE_GEMFILE'] = 'Gemfile'
      end

      context 'with default env' do
        it_behaves_like "inside of bundler"
      end

      context 'with zeus' do
        let(:options) { default_options.merge(zeus: true) }
        it_behaves_like "outside of bundler"
      end

      context 'with CLI' do
        let(:custom_cli) { 'custom_CLI_command' }
        let(:options) { default_options.merge(CLI: custom_cli) }
        it_behaves_like "outside of bundler"
      end
    end

    context 'when guard-rails is outside of bundler' do
      before do
        ENV['BUNDLE_GEMFILE'] = nil
        BundlerClass = Bundler
        Object.send(:remove_const, :Bundler)
      end
      after do
        Bundler = BundlerClass
        Object.send(:remove_const, :BundlerClass)
      end

      context 'with default env' do
        it_behaves_like "outside of bundler"
      end

      context 'with zeus' do
        let(:options) { default_options.merge(zeus: true) }
        it_behaves_like "outside of bundler"
      end

      context 'with CLI' do
        let(:custom_cli) { 'custom_CLI_command' }
        let(:options) { default_options.merge(CLI: custom_cli) }
        it_behaves_like "outside of bundler"
      end
    end
  end

  describe '#start' do
    let(:kill_expectation) { mock(runner).kill_unmanaged_pid! }
    let(:pid_stub) { stub(runner).has_pid? }

    before do
      mock(runner).run_rails_command!.once
    end

    context 'without options[:force_run]' do
      before do
        pid_stub.returns(true)
        kill_expectation.never
        mock(runner).wait_for_pid_action.never
      end

      it "starts as normal" do
        expect(runner.start).to be true
      end
    end

    context 'with options[:force_run]' do
      let(:options) { default_options.merge(force_run: true) }

      before do
        pid_stub.returns(true)
        kill_expectation.once
        mock(runner).wait_for_pid_action.never
      end

      it "starts as normal" do
        expect(runner.start).to be true
      end
    end

    context "doesn't write the pid" do
      before do
        pid_stub.returns(false)
        kill_expectation.never
        mock(runner).wait_for_pid_action.times(Guard::Rails::Runner::MAX_WAIT_COUNT)
      end

      it "doesn't start" do
        expect(runner.start).to be false
      end
    end
  end

  describe '#stop' do
    include FakeFS::SpecHelpers

    it 'stops' do
      expect(runner.stop)
    end

    context 'when pid exists' do
      let(:pid) { 12345 }

      before do
        FileUtils.mkdir_p File.split(runner.pid_file).first
        File.open(runner.pid_file, 'w') { |f| f.print pid }
      end

      it 'removes the pid file' do
        runner.stop
        expect(File.exists?(runner.pid_file)).to be false
      end

      it 'kills the process with INT' do
        mock(runner).kill_process.with("INT", pid).returns { true }
        stub(runner).sleep
        mock(runner).kill_process.with("KILL", pid).once
        runner.stop
      end

      it 'kills the process with KILL when INT not work' do
        mock(runner).kill_process.with("INT", pid).returns { false }
        mock(runner).kill_process.with("KILL", pid).once
        runner.stop
      end
    end

    context "when pid file doesn't exist" do
      it 'does nothing' do
        runner.stop
        mock(runner).kill_process.never
      end
    end

    context "when pid file is empty" do
      before do
        FileUtils.mkdir_p File.split(runner.pid_file).first
        File.open(runner.pid_file, 'w') { |f| f.print "" }
      end

      it 'does nothing' do
        mock(runner).kill_process.never
        runner.stop
      end

      it 'removes the pid file' do
        runner.stop
        expect(File.exists?(runner.pid_file)).to be false
      end

    end
  end

  describe '#restart' do
    it 'calls stop and start' do
      mock(runner).stop.once
      mock(runner).start.once
      runner.restart
    end
  end

  describe '#kill_unmanaged_pid!' do
    let(:pid) { 12345 }

    it 'kill processes if any' do
      mock(runner).unmanaged_pid.returns { pid }
      mock(runner).kill_process.with("KILL", pid).once
      runner.send(:kill_unmanaged_pid!)
    end

    it 'does nothing if none' do
      mock(runner).unmanaged_pid.returns { nil }
      mock(runner).kill_process.with("KILL", pid).never
      runner.send(:kill_unmanaged_pid!)
    end
  end

  describe '#unmanaged_pid' do
    let(:pid) { 12345 }

    it 'returns pid if any' do
      mock(runner, :'`').with(anything).returns {
        "ruby #{pid} ranmocy 12u IPv4 0x9c30720e04d31a0f 0t0 TCP *:#{default_port} (LISTEN)"
      }
      expect(runner.send(:unmanaged_pid)).to eq pid
    end

    it 'returns nil if none' do
      mock(runner, :'`').with(anything).returns { "\n" }
      expect(runner.send(:unmanaged_pid)).to be nil
    end
  end

  describe '#kill_process' do
    let(:signal) { 'INT' }
    let(:fake_signal) { 'INT0' }
    let(:pid) { 12345 }

    it 'returns true if killed' do
      mock(Process).kill(signal, pid) { 0 }
      expect(runner.send(:kill_process, signal, pid)).to be true
    end

    it 'returns false if signal is wrong' do
      expect(runner.send(:kill_process, fake_signal, pid)).to be false
    end

    it 'returns false if no permission to kill' do
      mock(Process).kill(signal, pid) { raise Errno::EPERM }
      mock(Guard::UI).info("[Guard::Rails::Error] Don't have permission to KILL!")
      expect(runner.send(:kill_process, signal, pid)).to be false
    end
  end

  describe '#sleep_time' do
    let(:timeout) { 30 }
    let(:options) { default_options.merge(timeout: timeout) }

    it "adjusts the sleep time as necessary" do
      expect(runner.sleep_time).to eq (timeout.to_f / Guard::Rails::Runner::MAX_WAIT_COUNT.to_f)
    end
  end
end
