# frozen_string_literal: true

RSpec.describe Bookmarker::Exporter do
  let(:bookmarks) { [] }

  describe '.for' do
    it 'resolves :stdout to Exporter::Stdout' do
      exporter = described_class.for(:stdout, bookmarks, output: StringIO.new, input: StringIO.new)
      expect(exporter).to be_a(Bookmarker::Exporter::Stdout)
    end

    it 'resolves string format names' do
      exporter = described_class.for('stdout', bookmarks, output: StringIO.new, input: StringIO.new)
      expect(exporter).to be_a(Bookmarker::Exporter::Stdout)
    end

    it 'raises Error for unknown formats' do
      expect { described_class.for(:nope, bookmarks) }
        .to raise_error(Bookmarker::Error, /Unknown export format: nope/)
    end
  end

  describe '#export' do
    it 'raises NotImplementedError on the base class' do
      exporter = described_class.new(bookmarks)
      expect { exporter.export }
        .to raise_error(NotImplementedError, /must implement #export/)
    end
  end

  describe '#bookmarks' do
    it 'exposes the bookmarks collection' do
      exporter = described_class.new(bookmarks)
      expect(exporter.bookmarks).to equal(bookmarks)
    end
  end

  describe '#output' do
    it 'defaults to $stdout' do
      exporter = described_class.new(bookmarks)
      expect(exporter.output).to eq($stdout)
    end

    it 'accepts a custom output stream' do
      io = StringIO.new
      exporter = described_class.new(bookmarks, output: io)
      expect(exporter.output).to eq(io)
    end
  end
end
