# frozen_string_literal: true

RSpec.describe Bookmarker::Bookmark do
  subject(:bookmark) do
    described_class.new(
      id: 1,
      title: 'Example Site',
      url: 'https://example.com',
      folder: 'toolbar',
      path: %w[menu toolbar],
      date_added: Time.at(1_700_000_000)
    )
  end

  describe '#to_s' do
    it 'returns title and url' do
      expect(bookmark.to_s).to eq("Example Site\n  https://example.com")
    end

    it 'shows (untitled) when title is nil' do
      bm = described_class.new(id: 2, title: nil, url: 'https://example.com',
                               folder: nil, path: nil, date_added: nil)
      expect(bm.to_s).to eq("(untitled)\n  https://example.com")
    end
  end

  describe '#formatted' do
    it 'returns numbered display with title, path, and url' do
      expect(bookmark.formatted(1)).to eq(
        "1. Example Site\n   [menu > toolbar]\n   https://example.com"
      )
    end

    it 'shows (untitled) when title is nil' do
      bm = described_class.new(id: 2, title: nil, url: 'https://example.com',
                               folder: nil, path: nil, date_added: nil)
      expect(bm.formatted(5)).to eq("5. (untitled)\n   https://example.com")
    end

    it 'omits path line when path has only one element' do
      bm = described_class.new(id: 3, title: 'Single', url: 'https://example.com',
                               folder: 'menu', path: ['menu'], date_added: nil)
      expect(bm.formatted(1)).to eq("1. Single\n   https://example.com")
    end

    it 'shows deep paths' do
      bm = described_class.new(id: 4, title: 'Deep', url: 'https://example.com',
                               folder: 'gems', path: %w[menu toolbar ruby gems],
                               date_added: nil)
      expect(bm.formatted(1)).to eq(
        "1. Deep\n   [menu > toolbar > ruby > gems]\n   https://example.com"
      )
    end
  end

  describe '#full_path' do
    it 'joins path segments with >' do
      expect(bookmark.full_path).to eq('menu > toolbar')
    end

    it 'returns folder when path is nil' do
      bm = described_class.new(id: 2, title: 'X', url: 'https://example.com',
                               folder: 'toolbar', path: nil, date_added: nil)
      expect(bm.full_path).to eq('toolbar')
    end

    it 'returns empty string when both path and folder are nil' do
      bm = described_class.new(id: 2, title: 'X', url: 'https://example.com',
                               folder: nil, path: nil, date_added: nil)
      expect(bm.full_path).to eq('')
    end

    it 'returns folder when path is empty' do
      bm = described_class.new(id: 2, title: 'X', url: 'https://example.com',
                               folder: 'toolbar', path: [], date_added: nil)
      expect(bm.full_path).to eq('toolbar')
    end
  end

  describe 'attributes' do
    it 'exposes all fields' do
      expect(bookmark.id).to eq(1)
      expect(bookmark.title).to eq('Example Site')
      expect(bookmark.url).to eq('https://example.com')
      expect(bookmark.folder).to eq('toolbar')
      expect(bookmark.path).to eq(%w[menu toolbar])
      expect(bookmark.date_added).to eq(Time.at(1_700_000_000))
    end
  end
end
