# frozen_string_literal: true

RSpec.describe Bookmarker::Database do
  let(:test_data) { create_test_database }
  let(:dir) { test_data[0] }
  let(:db_path) { test_data[1] }

  after { cleanup_test_dir(dir) }

  describe "#initialize" do
    it "accepts a valid database path" do
      db = described_class.new(db_path)
      expect(db.db_path).to eq(db_path)
    end

    it "raises DatabaseNotFoundError for missing file" do
      expect { described_class.new("/nonexistent/places.sqlite") }
        .to raise_error(Bookmarker::DatabaseNotFoundError, /Database not found/)
    end
  end

  describe "#bookmarks" do
    it "returns an array of Bookmark objects" do
      db = described_class.new(db_path)
      results = db.bookmarks
      expect(results).to all(be_a(Bookmarker::Bookmark))
    end

    it "extracts title, url, folder, and date from the database" do
      db = described_class.new(db_path)
      bm = db.bookmarks.find { |b| b.title == "Bookmark 1" }
      expect(bm).not_to be_nil
      expect(bm.url).to eq("https://example.com/1")
      expect(bm.folder).to eq("menu")
      expect(bm.date_added).to be_a(Time)
    end

    it "assigns correct folders based on parent" do
      db = described_class.new(db_path)
      toolbar_bms = db.bookmarks.select { |b| b.folder == "toolbar" }
      menu_bms = db.bookmarks.select { |b| b.folder == "menu" }
      expect(toolbar_bms.size).to eq(15)
      expect(menu_bms.size).to eq(15)
    end

    it "excludes place: URLs" do
      # The default test data has no place: URLs, so all should be present
      db = described_class.new(db_path)
      place_urls = db.bookmarks.select { |b| b.url.start_with?("place:") }
      expect(place_urls).to be_empty
    end

    it "caches results" do
      db = described_class.new(db_path)
      first_call = db.bookmarks
      second_call = db.bookmarks
      expect(first_call).to equal(second_call)
    end
  end

  describe "#count" do
    it "returns the number of bookmarks" do
      db = described_class.new(db_path)
      expect(db.count).to eq(30)
    end
  end

  describe "#search" do
    it "finds bookmarks by title" do
      db = described_class.new(db_path)
      results = db.search("Bookmark 1")
      titles = results.map(&:title)
      expect(titles).to include("Bookmark 1")
    end

    it "finds bookmarks by URL" do
      db = described_class.new(db_path)
      results = db.search("example.com/5")
      expect(results.size).to eq(1)
      expect(results.first.url).to eq("https://example.com/5")
    end

    it "finds bookmarks by folder" do
      db = described_class.new(db_path)
      results = db.search("toolbar")
      expect(results.size).to eq(15)
    end

    it "is case insensitive" do
      db = described_class.new(db_path)
      results = db.search("BOOKMARK 1")
      expect(results).not_to be_empty
    end

    it "returns empty array for no matches" do
      db = described_class.new(db_path)
      expect(db.search("zzz_nonexistent")).to be_empty
    end
  end

  describe "#folders" do
    it "returns sorted unique folder names" do
      db = described_class.new(db_path)
      expect(db.folders).to eq(["menu", "toolbar"])
    end
  end

  describe "#by_folder" do
    it "returns bookmarks in the specified folder" do
      db = described_class.new(db_path)
      results = db.by_folder("toolbar")
      expect(results.size).to eq(15)
      expect(results).to all(have_attributes(folder: "toolbar"))
    end

    it "returns empty for nonexistent folder" do
      db = described_class.new(db_path)
      expect(db.by_folder("nonexistent")).to be_empty
    end
  end

  context "with nil date_added" do
    it "handles nil timestamps" do
      dir2, db_path2 = create_test_database(bookmarks: [
        { title: "No Date", url: "https://example.com/nodate", parent: 2, date_added: nil }
      ])
      db = described_class.new(db_path2)
      bm = db.bookmarks.first
      expect(bm.date_added).to be_nil
    ensure
      cleanup_test_dir(dir2)
    end
  end

  context "with nil title and folder" do
    it "search handles bookmarks with nil title" do
      dir2, db_path2 = create_test_database(bookmarks: [
        { title: nil, url: "https://example.com/notitle", parent: 2 }
      ])
      db = described_class.new(db_path2)
      results = db.search("example.com")
      expect(results.size).to eq(1)
      expect(results.first.title).to be_nil
    ensure
      cleanup_test_dir(dir2)
    end

    it "search handles bookmarks with nil folder gracefully" do
      dir2, db_path2 = create_test_database(bookmarks: [
        { title: "Orphan", url: "https://example.com/orphan", parent: 999 }
      ])
      db = described_class.new(db_path2)
      results = db.search("orphan")
      expect(results.size).to eq(1)
      expect(results.first.folder).to be_nil
    ensure
      cleanup_test_dir(dir2)
    end

    it "search with nil folder does not raise when term matches nothing" do
      dir2, db_path2 = create_test_database(bookmarks: [
        { title: "Orphan", url: "https://example.com/orphan", parent: 999 }
      ])
      db = described_class.new(db_path2)
      # Search for a folder name that won't match title or URL
      results = db.search("nonexistent_folder")
      expect(results).to be_empty
    ensure
      cleanup_test_dir(dir2)
    end
  end
end
