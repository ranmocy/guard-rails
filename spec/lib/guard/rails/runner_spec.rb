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
        runner.pid.should == pid
      end
    end

    context 'pid file does not exist' do
      it "should return nil" do
        runner.pid.should be_nil
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
        runner.pid_file.should match %r{spec/dummy/tmp/pids/development.pid}
      end
    end

  end

  describe '#build_command' do
    context "CLI" do
      let(:custom_cli) { 'custom_CLI_command' }
      let(:options) { default_options.merge(:CLI => custom_cli) }
      it "should have only custom CLI" do
        runner.build_command.should match(%r{#{custom_cli} --pid })
      end

      let(:custom_pid_file) { "tmp/pids/rails_dev.pid" }
      let(:options) { default_options.merge(:CLI => custom_cli, :pid_file => custom_pid_file) }
      it "should use custom pid_file" do
        pid_file_path = File.expand_path custom_pid_file
        runner.build_command.should match(%r{#{custom_cli} --pid \"#{pid_file_path}\"})
      end
    end

    context "daemon" do
      it "should should not have daemon switch" do
        runner.build_command.should_not match(%r{ -d})
      end
    end

    context "no daemon" do
      let(:options) { default_options.merge(:daemon => true) }
      it "should have a daemon switch" do
        runner.build_command.should match(%r{ -d})
      end
    end

    context "development" do
      it "should have environment switch to development" do
        runner.build_command.should match(%r{ -e development})
      end
    end

    context "test" do
      let(:options) { default_options.merge(:environment => 'test') }
      it "should have environment switch to test" do
        runner.build_command.should match(%r{ -e test})
      end
    end

    context 'debugger' do
      let(:options) { default_options.merge(:debugger => true) }

      it "should have a debugger switch" do
        runner.build_command.should match(%r{ -u})
      end
    end

    context 'custom server' do
      let(:options) { default_options.merge(:server => 'thin') }

      it "should have the server name" do
        runner.build_command.should match(%r{thin})
      end
    end

    context "no pid_file" do
      it "should use default pid_file" do
        pid_file_path = File.expand_path "tmp/pids/development.pid"
        runner.build_command.should match(%r{ --pid \"#{pid_file_path}\"})
      end
    end

    context "custom pid_file" do
      let(:custom_pid_file) { "tmp/pids/rails_dev.pid" }
      let(:options) { default_options.merge(:pid_file => custom_pid_file) }

      it "should use custom pid_file" do
        pid_file_path = File.expand_path custom_pid_file
        runner.build_command.should match(%r{ --pid \"#{pid_file_path}\"})
      end
    end

    context "zeus enabled" do
      let(:options) { default_options.merge(:zeus => true) }
      it "should have zeus in command" do
        runner.build_command.should match(%r{zeus server })
      end

      context "custom zeus plan" do
        let(:options) { default_options.merge(:zeus => true, :zeus_plan => 'test_server') }
        it "should use custom zeus plan" do
          runner.build_command.should match(%r{zeus test_server})
        end

        context "custom server" do
          let(:options) { default_options.merge(:zeus => true, :zeus_plan => 'test_server', :server => 'thin') }
          it "should use custom server" do
            runner.build_command.should match(%r{zeus test_server .* thin})
          end
        end
      end
    end

    context "zeus disabled" do
      it "should not have zeus in command" do
        runner.build_command.should_not match(%r{zeus server })
      end

      let(:options) { default_options.merge(:zeus_plan => 'test_server') }
      it "should have no effect of command" do
        runner.build_command.should_not match(%r{test_server})
      end
    end

    context 'custom rails root' do
      let(:options) { default_options.merge(:root => 'spec/dummy') }

      it "should have a cd with the custom rails root" do
        runner.build_command.should match(%r{cd .*/spec/dummy\" &&})
      end
    end
  end

  describe '#environment' do
    it "defaults RAILS_ENV to development" do
      runner.environment["RAILS_ENV"].should == "development"
    end

    context "with options[:environment]" do
      let(:options) { default_options.merge(:environment => 'bob') }

      it "defaults RAILS_ENV to nil" do
        runner.environment["RAILS_ENV"].should == "bob"
      end

      context "zeus enabled" do
        let(:options) { default_options.merge(:zeus => true) }

        it "should set RAILS_ENV to nil" do
          runner.environment["RAILS_ENV"].should be_nil
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
        runner.start.should be_true
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
        runner.start.should be_true
      end
    end

    context "don't write the pid" do
      before do
        pid_stub.returns(false)
        kill_expectation.never
        runner.expects(:wait_for_pid_action).times(Guard::RailsRunner::MAX_WAIT_COUNT)
      end

      it "should act properly" do
        runner.start.should be_false
      end
    end
  end

  describe '#sleep_time' do
    let(:timeout) { 30 }
    let(:options) { default_options.merge(:timeout => timeout) }

    it "should adjust the sleep time as necessary" do
      runner.sleep_time.should == (timeout.to_f / Guard::RailsRunner::MAX_WAIT_COUNT.to_f)
    end
  end
end
