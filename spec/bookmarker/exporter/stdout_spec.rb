# frozen_string_literal: true

RSpec.describe Bookmarker::Exporter::Stdout do
  include TestHelpers

  let(:test_data) { create_test_database }
  let(:dir) { test_data[0] }
  let(:db_path) { test_data[1] }
  let(:output) { StringIO.new }
  let(:input) { StringIO.new('q') }

  after { cleanup_test_dir(dir) }

  def bookmarks
    Bookmarker::Database.new(db_path).bookmarks
  end

  describe '#export' do
    it 'renders bookmarks through the pager' do
      exporter = described_class.new(bookmarks, output: output, input: input)
      exporter.export
      expect(output.string).to include('Bookmark 1')
    end

    it 'respects custom page size' do
      exporter = described_class.new(bookmarks, output: output, input: input, page_size: 5)
      exporter.export
      expect(output.string).to include('Showing 1-5 of 30')
    end

    it 'uses default page size when nil' do
      exporter = described_class.new(bookmarks, output: output, input: input)
      exporter.export
      expect(output.string).to include('Showing 1-25 of 30')
    end

    it 'handles empty bookmark list' do
      exporter = described_class.new([], output: output, input: input)
      exporter.export
      expect(output.string).to include('No bookmarks found.')
    end

    it 'ignores unknown keyword arguments' do
      expect { described_class.new(bookmarks, output: output, input: input, unknown: 'ignored') }
        .not_to raise_error
    end
  end

  describe 'inheritance' do
    it 'is an Exporter' do
      exporter = described_class.new([], output: output, input: input)
      expect(exporter).to be_a(Bookmarker::Exporter)
    end
  end
end
