# frozen_string_literal: true

RSpec.describe Bookmarker::ProfileFinder do
  describe '#profiles_dir' do
    it 'returns macOS path for darwin' do
      finder = described_class.new(platform: 'darwin')
      expect(finder.profiles_dir).to include('Library/Application Support/Firefox/Profiles')
    end

    it 'returns Linux path for linux' do
      finder = described_class.new(platform: 'linux')
      expect(finder.profiles_dir).to include('.mozilla/firefox')
    end

    it 'returns Windows path for windows' do
      finder = described_class.new(platform: 'windows')
      expect(finder.profiles_dir).to include('Mozilla/Firefox/Profiles')
    end

    it 'raises for unsupported platform' do
      finder = described_class.new(platform: 'haiku')
      expect { finder.profiles_dir }.to raise_error(Bookmarker::Error, /Unsupported platform/)
    end
  end

  describe '#find_databases' do
    it 'returns empty array when profiles dir does not exist' do
      finder = described_class.new(platform: 'linux')
      allow(Dir).to receive(:exist?).and_return(false)
      expect(finder.find_databases).to eq([])
    end

    it 'finds places.sqlite files in profile directories' do
      dir, db_path = create_test_database(bookmarks: [])
      profile_dir = File.dirname(db_path)

      # Create a fake profiles dir structure
      fake_profiles = File.join(dir, 'Profiles')
      fake_profile = File.join(fake_profiles, 'abc123.default-release')
      FileUtils.mkdir_p(fake_profile)
      FileUtils.cp(db_path, File.join(fake_profile, 'places.sqlite'))

      finder = described_class.new(platform: 'darwin')
      allow(finder).to receive(:profiles_dir).and_return(fake_profiles)

      results = finder.find_databases
      expect(results.size).to eq(1)
      expect(results.first).to end_with('places.sqlite')
    ensure
      cleanup_test_dir(dir)
    end
  end

  describe '#default_database' do
    it 'raises DatabaseNotFoundError when no databases exist' do
      finder = described_class.new(platform: 'darwin')
      allow(finder).to receive(:find_databases).and_return([])
      expect { finder.default_database }.to raise_error(Bookmarker::DatabaseNotFoundError)
    end

    it 'prefers default-release profile' do
      finder = described_class.new(platform: 'darwin')
      dbs = [
        '/path/to/abc123.other/places.sqlite',
        '/path/to/xyz789.default-release/places.sqlite'
      ]
      allow(finder).to receive(:find_databases).and_return(dbs)
      expect(finder.default_database).to eq(dbs[1])
    end

    it 'falls back to first database when no default-release' do
      finder = described_class.new(platform: 'darwin')
      dbs = [
        '/path/to/abc123.other/places.sqlite',
        '/path/to/xyz789.backup/places.sqlite'
      ]
      allow(finder).to receive(:find_databases).and_return(dbs)
      expect(finder.default_database).to eq(dbs[0])
    end
  end

  describe 'platform detection' do
    it 'detects the current platform automatically' do
      finder = described_class.new
      # On macOS CI/dev, this should resolve to darwin
      expect(finder.profiles_dir).to be_a(String)
    end
  end
end
