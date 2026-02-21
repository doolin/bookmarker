# frozen_string_literal: true

require 'json'

RSpec.describe Bookmarker::Exporter::Json do
  let(:output) { StringIO.new }
  let(:date) { Time.new(2024, 6, 15, 12, 0, 0, '+00:00') }
  let(:bookmark) do
    Bookmarker::Bookmark.new(
      id: 1, title: 'Ruby Docs', url: 'https://ruby-doc.org',
      folder: 'toolbar', path: %w[menu toolbar], date_added: date
    )
  end

  def parsed
    JSON.parse(output.string)
  end

  def export(bookmarks)
    described_class.new(bookmarks, output: output).export
  end

  describe '#export' do
    it 'outputs a JSON array' do
      export([bookmark])
      expect(parsed).to be_an(Array)
    end

    it 'includes all bookmarks' do
      second = bookmark.with(id: 2, title: 'Example')
      export([bookmark, second])
      expect(parsed.size).to eq(2)
    end

    it 'serializes id' do
      export([bookmark])
      expect(parsed.first['id']).to eq(1)
    end

    it 'serializes title' do
      export([bookmark])
      expect(parsed.first['title']).to eq('Ruby Docs')
    end

    it 'serializes url' do
      export([bookmark])
      expect(parsed.first['url']).to eq('https://ruby-doc.org')
    end

    it 'serializes folder' do
      export([bookmark])
      expect(parsed.first['folder']).to eq('toolbar')
    end

    it 'serializes path as array' do
      export([bookmark])
      expect(parsed.first['path']).to eq(%w[menu toolbar])
    end

    it 'serializes date_added as ISO 8601' do
      export([bookmark])
      expect(parsed.first['date_added']).to eq(date.iso8601)
    end

    it 'serializes nil title as null' do
      bm = Bookmarker::Bookmark.new(id: 3, title: nil, url: 'https://example.com',
                                    folder: 'menu', path: ['menu'], date_added: date)
      export([bm])
      expect(parsed.first['title']).to be_nil
    end

    it 'serializes nil date_added as null' do
      bm = Bookmarker::Bookmark.new(id: 4, title: 'No Date', url: 'https://example.com',
                                    folder: 'menu', path: ['menu'], date_added: nil)
      export([bm])
      expect(parsed.first['date_added']).to be_nil
    end

    it 'serializes nil path as null' do
      bm = Bookmarker::Bookmark.new(id: 5, title: 'Orphan', url: 'https://example.com',
                                    folder: nil, path: nil, date_added: date)
      export([bm])
      expect(parsed.first['path']).to be_nil
    end

    it 'outputs empty array for no bookmarks' do
      export([])
      expect(parsed).to eq([])
    end

    it 'is accessible via the factory' do
      exporter = Bookmarker::Exporter.for(:json, [bookmark], output: output)
      expect(exporter).to be_a(described_class)
    end
  end
end
