# frozen_string_literal: true

require "spec_helper"
require "dotfiles_sync"
require "tmpdir"

RSpec.describe DotfilesSync do
  let(:options) { { dry_run: true } }
  let(:sync) { described_class.new(options) }

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
      expect { sync.run }.to output(/Welcome to Mike's Dotfiles Sync!/).to_stdout
    end

    it "outputs dry run mode message" do
      expect { sync.run }.to output(/Dry run mode: true/).to_stdout
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
          s = described_class.new(dotfiles_dir: tmpdir)
          expect { s.send(:install_mcp_servers) }
            .to output(/No MCP server config found/).to_stdout
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
        end

        it "resolves env vars in output" do
          ENV['TEST_TOKEN'] = 'secret123'
          s = described_class.new(dotfiles_dir: tmpdir)
          s.send(:install_mcp_servers)

          claude_settings = JSON.parse(File.read(File.join(home_dir, ".claude", "settings.json")))
          expect(claude_settings['mcpServers']['test-server']['headers']['Authorization'])
            .to eq('Bearer secret123')
        ensure
          ENV.delete('TEST_TOKEN')
        end

        it "warns and leaves placeholder for missing env vars" do
          ENV.delete('TEST_TOKEN')
          s = described_class.new(dotfiles_dir: tmpdir)
          expect { s.send(:install_mcp_servers) }
            .to output(/Environment variable TEST_TOKEN not set/).to_stdout

          claude_settings = JSON.parse(File.read(File.join(home_dir, ".claude", "settings.json")))
          expect(claude_settings['mcpServers']['test-server']['headers']['Authorization'])
            .to eq('Bearer ${TEST_TOKEN}')
        end

        it "merges into existing Claude settings.json preserving other keys" do
          claude_dir = File.join(home_dir, ".claude")
          FileUtils.mkdir_p(claude_dir)
          File.write(File.join(claude_dir, "settings.json"), JSON.generate({
            "model" => "opus",
            "enabledPlugins" => { "some-plugin" => true }
          }))

          ENV['TEST_TOKEN'] = 'tok'
          s = described_class.new(dotfiles_dir: tmpdir)
          s.send(:install_mcp_servers)

          claude_settings = JSON.parse(File.read(File.join(claude_dir, "settings.json")))
          expect(claude_settings['model']).to eq('opus')
          expect(claude_settings['enabledPlugins']).to eq({ "some-plugin" => true })
          expect(claude_settings['mcpServers']).to be_a(Hash)
        ensure
          ENV.delete('TEST_TOKEN')
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

        it "writes nothing in dry run mode" do
          s = described_class.new(dotfiles_dir: tmpdir, dry_run: true)
          s.send(:install_mcp_servers)

          expect(File.exist?(File.join(home_dir, ".claude", "settings.json"))).to be false
          expect(File.exist?(File.join(home_dir, ".cursor", "mcp.json"))).to be false
        end

        it "resolves NPX_PATH from which npx" do
          s = described_class.new(dotfiles_dir: tmpdir)
          npx_path = `which npx 2>/dev/null`.strip

          ENV['TEST_TOKEN'] = 'tok'
          s.send(:install_mcp_servers)

          claude_settings = JSON.parse(File.read(File.join(home_dir, ".claude", "settings.json")))
          resolved_command = claude_settings['mcpServers']['npx-server']['command']

          if npx_path.empty?
            expect(resolved_command).to eq('${NPX_PATH}')
          else
            expect(resolved_command).to eq(npx_path)
          end
        ensure
          ENV.delete('TEST_TOKEN')
        end
      end
    end
  end
end
