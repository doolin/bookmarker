# frozen_string_literal: true

RSpec.describe Bookmarker::CLI do
  let(:test_data) { create_test_database }
  let(:dir) { test_data[0] }
  let(:db_path) { test_data[1] }
  let(:stdout) { StringIO.new }
  let(:stderr) { StringIO.new }
  let(:stdin) { StringIO.new("q\n") }

  after { cleanup_test_dir(dir) }

  def cli(args = [])
    described_class.new(argv: args, stdout: stdout, stderr: stderr, stdin: stdin)
  end

  describe "--version" do
    it "prints version and exits 0" do
      result = cli(["--version"]).run
      expect(result).to eq(0)
      expect(stdout.string).to include(Bookmarker::VERSION)
    end
  end

  describe "--help" do
    it "prints usage and exits 0" do
      result = cli(["--help"]).run
      expect(result).to eq(0)
      expect(stdout.string).to include("Usage: bookmarker")
      expect(stdout.string).to include("--database")
      expect(stdout.string).to include("--search")
    end
  end

  describe "--database" do
    it "loads bookmarks from specified database" do
      result = cli(["-d", db_path]).run
      expect(result).to eq(0)
      expect(stdout.string).to include("Bookmark 1")
    end

    it "shows error for missing database" do
      result = cli(["-d", "/nonexistent/places.sqlite"]).run
      expect(result).to eq(1)
      expect(stderr.string).to include("Error:")
    end
  end

  describe "--count" do
    it "shows bookmark count" do
      result = cli(["-d", db_path, "--count"]).run
      expect(result).to eq(0)
      expect(stdout.string).to include("Total bookmarks: 30")
    end
  end

  describe "--folders" do
    it "lists all folders" do
      result = cli(["-d", db_path, "--folders"]).run
      expect(result).to eq(0)
      expect(stdout.string).to include("menu")
      expect(stdout.string).to include("toolbar")
    end

    it "shows message when no folders" do
      dir2, db_path2 = create_test_database(bookmarks: [])
      result = cli(["-d", db_path2, "--folders"]).run
      expect(result).to eq(0)
      expect(stdout.string).to include("No folders found.")
    ensure
      cleanup_test_dir(dir2)
    end
  end

  describe "--folder" do
    it "filters by folder" do
      result = cli(["-d", db_path, "--folder", "toolbar"]).run
      expect(result).to eq(0)
      expect(stdout.string).to include("Bookmark")
    end
  end

  describe "--search" do
    it "filters by search term" do
      result = cli(["-d", db_path, "--search", "Bookmark 1"]).run
      expect(result).to eq(0)
      expect(stdout.string).to include("Bookmark 1")
    end
  end

  describe "--per-page" do
    it "sets custom page size" do
      result = cli(["-d", db_path, "-n", "5"]).run
      expect(result).to eq(0)
      expect(stdout.string).to include("Showing 1-5 of 30")
    end
  end

  describe "--profiles" do
    it "lists found databases" do
      finder = instance_double(Bookmarker::ProfileFinder, find_databases: [db_path])
      allow(Bookmarker::ProfileFinder).to receive(:new).and_return(finder)

      result = cli(["--profiles"]).run
      expect(result).to eq(0)
      expect(stdout.string).to include("Firefox bookmark databases:")
      expect(stdout.string).to include(db_path)
    end

    it "shows message when no profiles found" do
      finder = instance_double(Bookmarker::ProfileFinder, find_databases: [])
      allow(Bookmarker::ProfileFinder).to receive(:new).and_return(finder)

      result = cli(["--profiles"]).run
      expect(result).to eq(0)
      expect(stdout.string).to include("No Firefox profiles")
    end
  end

  describe "invalid options" do
    it "prints error and usage for invalid option" do
      result = cli(["--bogus"]).run
      expect(result).to eq(1)
      expect(stderr.string).to include("invalid option")
    end
  end

  describe "default behavior (no database flag)" do
    it "uses ProfileFinder to locate database" do
      finder = instance_double(Bookmarker::ProfileFinder, default_database: db_path)
      allow(Bookmarker::ProfileFinder).to receive(:new).and_return(finder)

      result = cli([]).run
      expect(result).to eq(0)
      expect(stdout.string).to include("Bookmark 1")
    end
  end
end
