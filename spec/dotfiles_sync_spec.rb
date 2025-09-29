# frozen_string_literal: true

require "spec_helper"
require "dotfiles_sync"

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
  end
end
