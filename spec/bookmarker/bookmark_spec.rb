# frozen_string_literal: true

RSpec.describe Bookmarker::Bookmark do
  subject(:bookmark) do
    described_class.new(
      id: 1,
      title: "Example Site",
      url: "https://example.com",
      folder: "toolbar",
      date_added: Time.at(1_700_000_000)
    )
  end

  describe "#to_s" do
    it "returns title and url" do
      expect(bookmark.to_s).to eq("Example Site\n  https://example.com")
    end

    it "shows (untitled) when title is nil" do
      bm = described_class.new(id: 2, title: nil, url: "https://example.com", folder: nil, date_added: nil)
      expect(bm.to_s).to eq("(untitled)\n  https://example.com")
    end
  end

  describe "#formatted" do
    it "returns numbered display with title and url" do
      expect(bookmark.formatted(1)).to eq("1. Example Site\n   https://example.com")
    end

    it "shows (untitled) when title is nil" do
      bm = described_class.new(id: 2, title: nil, url: "https://example.com", folder: nil, date_added: nil)
      expect(bm.formatted(5)).to eq("5. (untitled)\n   https://example.com")
    end
  end

  describe "attributes" do
    it "exposes all fields" do
      expect(bookmark.id).to eq(1)
      expect(bookmark.title).to eq("Example Site")
      expect(bookmark.url).to eq("https://example.com")
      expect(bookmark.folder).to eq("toolbar")
      expect(bookmark.date_added).to eq(Time.at(1_700_000_000))
    end
  end
end
