require 'spec_helper'
require 'guard/rails/runner'
require 'fakefs/spec_helpers'

describe Guard::RailsRunner do
  let(:runner) { Guard::RailsRunner.new(options) }
  let(:environment) { 'development' }
  let(:port) { 3000 }

  let(:default_options) { { :environment => environment, :port => port } }
  let(:options) { default_options }

  describe '#pid' do
    include FakeFS::SpecHelpers

    context 'pid file exists' do
      let(:pid) { 12345 }

      before do
        FileUtils.mkdir_p File.split(runner.pid_file).first
        File.open(runner.pid_file, 'w') { |fh| fh.print pid }
      end

      it "should read the pid" do
        expect(runner.pid).to eq(pid)
      end
    end

    context 'pid file does not exist' do
      it "should return nil" do
        expect(runner.pid).to be nil
      end
    end

    context 'custom rails root given' do
      let(:options) { default_options.merge(:root => 'spec/dummy') }
      let(:pid) { 12345 }

      before do
        FileUtils.mkdir_p File.split(runner.pid_file).first
        File.open(runner.pid_file, 'w') { |fh| fh.print pid }
      end

      it "should point to the right pid file" do
        expect(runner.pid_file).to match %r{spec/dummy/tmp/pids/development.pid}
      end
    end

  end

  describe '#build_command' do
    context "CLI" do
      let(:custom_cli) { 'custom_CLI_command' }
      let(:options) { default_options.merge(:CLI => custom_cli) }
      it "should have only custom CLI" do
        expect(runner.build_command).to match(%r{#{custom_cli} --pid })
      end

      let(:custom_pid_file) { "tmp/pids/rails_dev.pid" }
      let(:options) { default_options.merge(:CLI => custom_cli, :pid_file => custom_pid_file) }
      it "should use custom pid_file" do
        pid_file_path = File.expand_path custom_pid_file
        expect(runner.build_command).to match(%r{#{custom_cli} --pid \"#{pid_file_path}\"})
      end
    end

    context "daemon" do
      it "should should not have daemon switch" do
        expect(runner.build_command).not_to match(%r{ -d})
      end
    end

    context "no daemon" do
      let(:options) { default_options.merge(:daemon => true) }
      it "should have a daemon switch" do
        expect(runner.build_command).to match(%r{ -d})
      end
    end

    context "development" do
      it "should have environment switch to development" do
        expect(runner.build_command).to match(%r{ -e development})
      end
    end

    context "test" do
      let(:options) { default_options.merge(:environment => 'test') }
      it "should have environment switch to test" do
        expect(runner.build_command).to match(%r{ -e test})
      end
    end

    context 'debugger' do
      let(:options) { default_options.merge(:debugger => true) }

      it "should have a debugger switch" do
        expect(runner.build_command).to match(%r{ -u})
      end
    end

    context 'custom server' do
      let(:options) { default_options.merge(:server => 'thin') }

      it "should have the server name" do
        expect(runner.build_command).to match(%r{thin})
      end
    end

    context "no pid_file" do
      it "should use default pid_file" do
        pid_file_path = File.expand_path "tmp/pids/development.pid"
        expect(runner.build_command).to match(%r{ --pid \"#{pid_file_path}\"})
      end
    end

    context "custom pid_file" do
      let(:custom_pid_file) { "tmp/pids/rails_dev.pid" }
      let(:options) { default_options.merge(:pid_file => custom_pid_file) }

      it "should use custom pid_file" do
        pid_file_path = File.expand_path custom_pid_file
        expect(runner.build_command).to match(%r{ --pid \"#{pid_file_path}\"})
      end
    end

    context "zeus enabled" do
      let(:options) { default_options.merge(:zeus => true) }
      it "should have zeus in command" do
        expect(runner.build_command).to match(%r{zeus server })
      end

      context "custom zeus plan" do
        let(:options) { default_options.merge(:zeus => true, :zeus_plan => 'test_server') }
        it "should use custom zeus plan" do
          expect(runner.build_command).to match(%r{zeus test_server})
        end

        context "custom server" do
          let(:options) { default_options.merge(:zeus => true, :zeus_plan => 'test_server', :server => 'thin') }
          it "should use custom server" do
            expect(runner.build_command).to match(%r{zeus test_server .* thin})
          end
        end
      end
    end

    context "zeus disabled" do
      it "should not have zeus in command" do
        expect(runner.build_command).to_not match(%r{zeus server })
      end

      let(:options) { default_options.merge(:zeus_plan => 'test_server') }
      it "should have no effect of command" do
        expect(runner.build_command).to_not match(%r{test_server})
      end
    end

    context 'custom rails root' do
      let(:options) { default_options.merge(:root => 'spec/dummy') }

      it "should have a cd with the custom rails root" do
        expect(runner.build_command).to match(%r{cd .*/spec/dummy\" &&})
      end
    end
  end

  describe '#environment' do
    it "defaults RAILS_ENV to development" do
      expect(runner.environment["RAILS_ENV"]).to eq "development"
    end

    context "with options[:environment]" do
      let(:options) { default_options.merge(:environment => 'bob') }

      it "defaults RAILS_ENV to nil" do
        expect(runner.environment["RAILS_ENV"]).to eq "bob"
      end

      context "zeus enabled" do
        let(:options) { default_options.merge(:zeus => true) }

        it "should set RAILS_ENV to nil" do
          expect(runner.environment["RAILS_ENV"]).to be nil
        end
      end
    end
  end

  describe '#run_rails_command' do
    before do
      runner.stubs(:build_command).returns("printenv BUNDLE_GEMFILE > /dev/null")
    end

    context 'when guard-rails is outside of bundler' do
      before do
        @bundler_env = ENV['BUNDLE_GEMFILE']
        ENV['BUNDLE_GEMFILE'] = 'Gemfile'
      end
      after do
        ENV['BUNDLE_GEMFILE'] = @bundler_env
      end

      context 'when under default env' do
        it 'run rails inside of bundler' do
          expect(runner.send(:run_rails_command!)).to be true
        end
      end

      context 'when under zeus' do
        let(:options) { default_options.merge(:zeus => true) }

        it 'run rails outside of bundler' do
          expect(runner.send(:run_rails_command!)).to be false
        end
      end

      context 'when under CLI' do
        let(:custom_cli) { 'custom_CLI_command' }
        let(:options) { default_options.merge(:CLI => custom_cli) }

        it 'run rails outside of bundler' do
          expect(runner.send(:run_rails_command!)).to be false
        end
      end
    end

    context 'when guard-rails is outside of bundler' do
      before do
        @bundler_env = ENV['BUNDLE_GEMFILE']
        ENV['BUNDLE_GEMFILE'] = nil
      end
      after do
        ENV['BUNDLE_GEMFILE'] = @bundler_env
      end

      context 'when under default env' do
        it 'run rails inside of bundler' do
          expect(runner.send(:run_rails_command!)).to be false
        end
      end

      context 'when under zeus' do
        let(:options) { default_options.merge(:zeus => true) }

        it 'run rails outside of bundler' do
          expect(runner.send(:run_rails_command!)).to be false
        end
      end

      context 'when under CLI' do
        let(:custom_cli) { 'custom_CLI_command' }
        let(:options) { default_options.merge(:CLI => custom_cli) }

        it 'run rails outside of bundler' do
          expect(runner.send(:run_rails_command!)).to be false
        end
      end
    end
  end

  describe '#start' do
    let(:kill_expectation) { runner.expects(:kill_unmanaged_pid!) }
    let(:pid_stub) { runner.stubs(:has_pid?) }

    before do
      runner.expects(:run_rails_command!).once
    end

    context 'do not force run' do
      before do
        pid_stub.returns(true)
        kill_expectation.never
        runner.expects(:wait_for_pid_action).never
      end

      it "should act properly" do
        expect(runner.start).to be true
      end
    end

    context 'force run' do
      let(:options) { default_options.merge(:force_run => true) }

      before do
        pid_stub.returns(true)
        kill_expectation.once
        runner.expects(:wait_for_pid_action).never
      end

      it "should act properly" do
        expect(runner.start).to be true
      end
    end

    context "don't write the pid" do
      before do
        pid_stub.returns(false)
        kill_expectation.never
        runner.expects(:wait_for_pid_action).times(Guard::RailsRunner::MAX_WAIT_COUNT)
      end

      it "should act properly" do
        expect(runner.start).to be false
      end
    end
  end

  describe '#sleep_time' do
    let(:timeout) { 30 }
    let(:options) { default_options.merge(:timeout => timeout) }

    it "should adjust the sleep time as necessary" do
      expect(runner.sleep_time).to eq (timeout.to_f / Guard::RailsRunner::MAX_WAIT_COUNT.to_f)
    end
  end
end
