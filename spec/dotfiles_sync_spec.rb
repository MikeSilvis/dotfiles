# frozen_string_literal: true

require "spec_helper"
require "dotfiles_sync"
require "tmpdir"

RSpec.describe DotfilesSync do
  let(:options) { { dry_run: true } }
  let(:sync) { described_class.new(options) }

  def capture_stdout
    original = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original
  end

  describe "#initialize" do
    it "sets default options" do
      sync = described_class.new
      expect(sync.dry_run).to be false
      expect(sync.verbose).to be false
      expect(sync.force).to be false
      expect(sync.backup_dir).to match(/\.dotfiles_backup_\d{8}_\d{6}/)
    end

    it "accepts custom options" do
      custom_options = {
        dry_run: true,
        verbose: true,
        force: true,
        backup_dir: "/custom/backup"
      }
      sync = described_class.new(custom_options)

      expect(sync.dry_run).to be true
      expect(sync.verbose).to be true
      expect(sync.force).to be true
      expect(sync.backup_dir).to eq("/custom/backup")
    end
  end

  describe "#run" do
    it "runs without errors in dry run mode" do
      expect { sync.run }.not_to raise_error
    end

    it "outputs welcome message" do
      expect { sync.run }.to output(/Welcome to Mike's Personal Dotfiles Sync!/).to_stdout
    end

    it "outputs dry run mode message" do
      expect { sync.run }.to output(/Dry run mode: true/).to_stdout
    end

    it "outputs summary" do
      expect { sync.run }.to output(/=== Summary ===/).to_stdout
    end

    it "outputs sync complete" do
      expect { sync.run }.to output(/Sync complete\./).to_stdout
    end

    it "shows actions in summary when changes are detected" do
      output = capture_stdout { sync.run }
      expect(output).to match(/=== Summary ===/)
      # On a real repo dry run, things like fonts/AI skills will be detected
      expect(output).to match(/(Configured:|Everything already up to date)/)
    end
  end

  describe "quiet vs verbose output" do
    let(:tmpdir) { Dir.mktmpdir }
    let(:home_dir) { Dir.mktmpdir }

    before do
      @original_home = ENV['HOME']
      ENV['HOME'] = home_dir
      # Create .oh-my-zsh so it thinks it's installed
      FileUtils.mkdir_p(File.join(home_dir, ".oh-my-zsh"))
    end

    after do
      ENV['HOME'] = @original_home
      FileUtils.rm_rf(tmpdir)
      FileUtils.rm_rf(home_dir)
    end

    it "hides 'already installed' messages in quiet mode" do
      s = described_class.new(dry_run: true, dotfiles_dir: tmpdir)
      output = capture_stdout { s.send(:check_and_install_oh_my_zsh) }
      expect(output).not_to include("already installed")
    end

    it "shows 'already installed' messages in verbose mode" do
      s = described_class.new(dry_run: true, verbose: true, dotfiles_dir: tmpdir)
      output = capture_stdout { s.send(:check_and_install_oh_my_zsh) }
      expect(output).to include("Oh My Zsh already installed")
    end

    it "hides section headers when nothing changed in quiet mode" do
      s = described_class.new(dry_run: true, dotfiles_dir: tmpdir)
      output = capture_stdout { s.send(:section, "Test Section") { s.send(:log_detail, "  detail") } }
      expect(output).not_to include("[ Test Section ]")
    end

    it "shows section headers in verbose mode" do
      s = described_class.new(dry_run: true, verbose: true, dotfiles_dir: tmpdir)
      output = capture_stdout { s.send(:section, "Test Section") { s.send(:log_detail, "  detail") } }
      expect(output).to include("[ Test Section ]")
    end

    it "always shows log_change messages with section header" do
      s = described_class.new(dry_run: true, dotfiles_dir: tmpdir)
      output = capture_stdout { s.send(:section, "Test Section") { s.send(:log_change, "Did something") } }
      expect(output).to include("[ Test Section ]")
      expect(output).to include("+ Did something")
    end
  end

  describe "private methods" do
    describe "#run_command" do
      it "outputs command in verbose mode" do
        verbose_sync = described_class.new(verbose: true, dry_run: true)
        expect { verbose_sync.send(:run_command, "echo test", "Test command") }
          .to output(/Test command/).to_stdout
      end

      it "does not execute commands in dry run mode" do
        expect(sync).not_to receive(:system)
        sync.send(:run_command, "echo test")
      end
    end

    describe "#install_mcp_servers" do
      let(:tmpdir) { Dir.mktmpdir }
      let(:home_dir) { Dir.mktmpdir }

      before do
        @original_home = ENV['HOME']
        ENV['HOME'] = home_dir
      end

      after do
        ENV['HOME'] = @original_home
        FileUtils.rm_rf(tmpdir)
        FileUtils.rm_rf(home_dir)
      end

      context "when config file is missing" do
        it "skips gracefully" do
          s = described_class.new(dotfiles_dir: tmpdir, verbose: true)
          expect { s.send(:install_mcp_servers) }
            .to output(/No MCP server config found/).to_stdout
        end

        it "produces no output in quiet mode" do
          s = described_class.new(dotfiles_dir: tmpdir)
          expect { s.send(:install_mcp_servers) }
            .not_to output(/No MCP server config found/).to_stdout
        end
      end

      context "with a valid config" do
        let(:config) do
          {
            "mcpServers" => {
              "test-server" => {
                "url" => "https://example.com",
                "headers" => { "Authorization" => "Bearer ${TEST_TOKEN}" }
              },
              "npx-server" => {
                "command" => "${NPX_PATH}",
                "args" => ["-y", "some-package"]
              }
            }
          }
        end

        before do
          config_dir = File.join(tmpdir, "configs", "ai")
          FileUtils.mkdir_p(config_dir)
          File.write(File.join(config_dir, "mcp-servers.json"), JSON.generate(config))
          File.write(File.join(config_dir, "mcp-servers-enabled.json"), JSON.generate(%w[test-server npx-server]))
        end

        it "warns and leaves placeholder for missing env vars" do
          ENV.delete('TEST_TOKEN')
          s = described_class.new(dotfiles_dir: tmpdir, dry_run: true)
          expect { s.send(:install_mcp_servers) }
            .to output(/Environment variable TEST_TOKEN not set/).to_stdout
        end

        it "writes full replacement to Cursor mcp.json" do
          ENV['TEST_TOKEN'] = 'tok'
          s = described_class.new(dotfiles_dir: tmpdir)
          s.send(:install_mcp_servers)

          cursor_mcp = JSON.parse(File.read(File.join(home_dir, ".cursor", "mcp.json")))
          expect(cursor_mcp.keys).to eq(['mcpServers'])
          expect(cursor_mcp['mcpServers']).to have_key('test-server')
        ensure
          ENV.delete('TEST_TOKEN')
        end

        it "only syncs enabled servers to Cursor" do
          config_dir = File.join(tmpdir, "configs", "ai")
          File.write(File.join(config_dir, "mcp-servers-enabled.json"), JSON.generate(%w[test-server]))

          ENV['TEST_TOKEN'] = 'tok'
          s = described_class.new(dotfiles_dir: tmpdir)
          s.send(:install_mcp_servers)

          cursor_mcp = JSON.parse(File.read(File.join(home_dir, ".cursor", "mcp.json")))
          expect(cursor_mcp['mcpServers']).to have_key('test-server')
          expect(cursor_mcp['mcpServers']).not_to have_key('npx-server')
        ensure
          ENV.delete('TEST_TOKEN')
        end

        it "syncs no servers when enabled list is empty" do
          config_dir = File.join(tmpdir, "configs", "ai")
          File.write(File.join(config_dir, "mcp-servers-enabled.json"), JSON.generate([]))

          s = described_class.new(dotfiles_dir: tmpdir)
          s.send(:install_mcp_servers)

          cursor_mcp = JSON.parse(File.read(File.join(home_dir, ".cursor", "mcp.json")))
          expect(cursor_mcp['mcpServers']).to be_empty
        end

        it "does not write Cursor mcp.json in dry run mode" do
          s = described_class.new(dotfiles_dir: tmpdir, dry_run: true)
          s.send(:install_mcp_servers)

          expect(File.exist?(File.join(home_dir, ".cursor", "mcp.json"))).to be false
        end

        it "resolves NPX_PATH from which npx" do
          s = described_class.new(dotfiles_dir: tmpdir)
          npx_path = `which npx 2>/dev/null`.strip

          ENV['TEST_TOKEN'] = 'tok'
          s.send(:install_mcp_servers)

          cursor_mcp = JSON.parse(File.read(File.join(home_dir, ".cursor", "mcp.json")))
          resolved_command = cursor_mcp['mcpServers']['npx-server']['command']

          if npx_path.empty?
            expect(resolved_command).to eq('${NPX_PATH}')
          else
            expect(resolved_command).to eq(npx_path)
          end
        ensure
          ENV.delete('TEST_TOKEN')
        end

        it "resolves NODE_BIN_DIR to the directory containing npx" do
          config_with_node_bin = {
            "mcpServers" => {
              "node-server" => {
                "command" => "${NPX_PATH}",
                "args" => ["-y", "some-package"],
                "env" => { "PATH" => "${NODE_BIN_DIR}:/usr/bin" }
              }
            }
          }
          config_dir = File.join(tmpdir, "configs", "ai")
          File.write(File.join(config_dir, "mcp-servers.json"), JSON.generate(config_with_node_bin))
          File.write(File.join(config_dir, "mcp-servers-enabled.json"), JSON.generate(%w[node-server]))

          s = described_class.new(dotfiles_dir: tmpdir)
          npx_path = `which npx 2>/dev/null`.strip
          s.send(:install_mcp_servers)

          cursor_mcp = JSON.parse(File.read(File.join(home_dir, ".cursor", "mcp.json")))
          resolved_path = cursor_mcp['mcpServers']['node-server']['env']['PATH']

          if npx_path.empty?
            expect(resolved_path).to eq('${NODE_BIN_DIR}:/usr/bin')
          else
            expect(resolved_path).to start_with(File.dirname(npx_path))
          end
        end
      end
    end

    describe "#claude_mcp_add_args" do
      let(:sync) { described_class.new }

      it "builds args for a URL-based server with headers" do
        server = {
          "url" => "https://example.com/mcp",
          "headers" => { "Authorization" => "Bearer token123" }
        }
        args = sync.send(:claude_mcp_add_args, "my-server", server)
        expect(args).to eq([
          "claude", "mcp", "add", "-s", "user", "-t", "http",
          "my-server", "https://example.com/mcp",
          "-H", "Authorization: Bearer token123"
        ])
      end

      it "builds args for a URL-based server without headers" do
        server = { "url" => "https://example.com/mcp", "headers" => {} }
        args = sync.send(:claude_mcp_add_args, "my-server", server)
        expect(args).to eq(%w[claude mcp add -s user -t http my-server https://example.com/mcp])
      end

      it "builds args for a command-based server with env and args" do
        server = {
          "command" => "/usr/bin/npx",
          "args" => ["-y", "some-package"],
          "env" => { "API_KEY" => "secret" }
        }
        args = sync.send(:claude_mcp_add_args, "my-server", server)
        expect(args).to eq(%w[
          claude mcp add -s user
          my-server
          -e API_KEY=secret
          -- /usr/bin/npx -y some-package
        ])
      end

      it "builds args for a command-based server without env" do
        server = { "command" => "docker", "args" => %w[mcp gateway run] }
        args = sync.send(:claude_mcp_add_args, "docker-mcp", server)
        expect(args).to eq(%w[claude mcp add -s user docker-mcp -- docker mcp gateway run])
      end

      it "returns nil for unknown server types" do
        args = sync.send(:claude_mcp_add_args, "bad", { "something" => "else" })
        expect(args).to be_nil
      end

      it "skips headers with empty values" do
        server = { "url" => "https://example.com", "headers" => { "X-Key" => "" } }
        args = sync.send(:claude_mcp_add_args, "my-server", server)
        expect(args).to eq(%w[claude mcp add -s user -t http my-server https://example.com])
      end
    end

    describe "#clean_claude_settings_mcp_servers" do
      let(:home_dir) { Dir.mktmpdir }

      before do
        @original_home = ENV['HOME']
        ENV['HOME'] = home_dir
      end

      after do
        ENV['HOME'] = @original_home
        FileUtils.rm_rf(home_dir)
      end

      it "removes mcpServers key from settings.json preserving other keys" do
        claude_dir = File.join(home_dir, ".claude")
        FileUtils.mkdir_p(claude_dir)
        File.write(File.join(claude_dir, "settings.json"), JSON.generate({
          "model" => "opus",
          "enabledPlugins" => { "some-plugin" => true },
          "mcpServers" => { "old-server" => { "url" => "https://example.com" } }
        }))

        s = described_class.new
        s.send(:clean_claude_settings_mcp_servers)

        settings = JSON.parse(File.read(File.join(claude_dir, "settings.json")))
        expect(settings['model']).to eq('opus')
        expect(settings['enabledPlugins']).to eq({ "some-plugin" => true })
        expect(settings).not_to have_key('mcpServers')
      end

      it "does nothing when settings.json has no mcpServers" do
        claude_dir = File.join(home_dir, ".claude")
        FileUtils.mkdir_p(claude_dir)
        original = { "model" => "opus" }
        File.write(File.join(claude_dir, "settings.json"), JSON.generate(original))

        s = described_class.new
        expect { s.send(:clean_claude_settings_mcp_servers) }
          .not_to(change { File.read(File.join(claude_dir, "settings.json")) })
      end
    end
  end
end
