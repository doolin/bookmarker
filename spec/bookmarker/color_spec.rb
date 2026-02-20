# frozen_string_literal: true

RSpec.describe Bookmarker::Color do
  after do
    described_class.enabled = false
    described_class.instance_variable_set(:@depth, nil)
  end

  describe '.wrap' do
    context 'when disabled' do
      before { described_class.enabled = false }

      it 'returns plain text' do
        expect(described_class.wrap('hello', :bold)).to eq('hello')
      end

      it 'converts non-string to string' do
        expect(described_class.wrap(42, :dim)).to eq('42')
      end
    end

    context 'when enabled' do
      before { described_class.enabled = true }

      it 'wraps text with bold' do
        result = described_class.wrap('title', :bold)
        expect(result).to eq("\e[1mtitle\e[0m")
      end

      it 'wraps text with dim' do
        result = described_class.wrap('info', :dim)
        expect(result).to eq("\e[2minfo\e[0m")
      end

      it 'combines multiple styles' do
        result = described_class.wrap('key', :key, :bold)
        expect(result).to match(/\A\e\[.*\e\[1mkey\e\[0m\z/)
      end
    end
  end

  describe 'semantic styles' do
    before { described_class.enabled = true }

    context 'with 256-color depth' do
      before { allow(described_class).to receive(:depth).and_return(:color256) }

      it 'uses steel blue for :url' do
        expect(described_class.wrap('link', :url)).to include("\e[38;5;74m")
      end

      it 'uses warm gold for :path' do
        expect(described_class.wrap('folder', :path)).to include("\e[38;5;179m")
      end

      it 'uses teal for :key' do
        expect(described_class.wrap('n', :key)).to include("\e[38;5;73m")
      end
    end

    context 'with basic color depth' do
      before { allow(described_class).to receive(:depth).and_return(:basic) }

      it 'uses cyan for :url' do
        expect(described_class.wrap('link', :url)).to include("\e[36m")
      end

      it 'uses yellow for :path' do
        expect(described_class.wrap('folder', :path)).to include("\e[33m")
      end

      it 'uses green for :key' do
        expect(described_class.wrap('n', :key)).to include("\e[32m")
      end
    end
  end

  describe '.auto_detect' do
    it 'enables for TTY output' do
      tty = instance_double(IO, tty?: true)
      described_class.auto_detect(tty)
      expect(described_class).to be_enabled
    end

    it 'disables for non-TTY output' do
      described_class.auto_detect(StringIO.new)
      expect(described_class).not_to be_enabled
    end

    it 'disables when NO_COLOR is set' do
      tty = instance_double(IO, tty?: true)
      allow(ENV).to receive(:key?).and_call_original
      allow(ENV).to receive(:key?).with('NO_COLOR').and_return(true)
      described_class.auto_detect(tty)
      expect(described_class).not_to be_enabled
    end
  end

  describe '.depth' do
    it 'detects 256-color from TERM' do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with('TERM', '').and_return('xterm-256color')
      allow(ENV).to receive(:fetch).with('COLORTERM', '').and_return('')
      expect(described_class.depth).to eq(:color256)
    end

    it 'detects 256-color from COLORTERM' do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with('TERM', '').and_return('xterm')
      allow(ENV).to receive(:fetch).with('COLORTERM', '').and_return('truecolor')
      expect(described_class.depth).to eq(:color256)
    end

    it 'falls back to basic' do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with('TERM', '').and_return('xterm')
      allow(ENV).to receive(:fetch).with('COLORTERM', '').and_return('')
      expect(described_class.depth).to eq(:basic)
    end
  end
end
