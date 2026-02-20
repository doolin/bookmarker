# frozen_string_literal: true

RSpec.describe Bookmarker::Pager do
  let(:bookmarks) do
    (1..50).map do |i|
      Bookmarker::Bookmark.new(
        id: i, title: "Bookmark #{i}", url: "https://example.com/#{i}",
        folder: 'test', path: %w[menu test], date_added: Time.now
      )
    end
  end

  describe '#initialize' do
    it 'starts at page 0' do
      pager = described_class.new(bookmarks)
      expect(pager.current_page).to eq(0)
    end

    it 'uses default page size of 25' do
      pager = described_class.new(bookmarks)
      expect(pager.page_size).to eq(25)
    end

    it 'accepts custom page size' do
      pager = described_class.new(bookmarks, page_size: 10)
      expect(pager.page_size).to eq(10)
    end
  end

  describe '#total_pages' do
    it 'calculates total pages correctly' do
      pager = described_class.new(bookmarks)
      expect(pager.total_pages).to eq(2)
    end

    it 'rounds up for partial pages' do
      pager = described_class.new(bookmarks, page_size: 15)
      expect(pager.total_pages).to eq(4) # 50/15 = 3.33 -> 4
    end

    it 'returns 0 for empty list' do
      pager = described_class.new([])
      expect(pager.total_pages).to eq(0)
    end
  end

  describe '#current_items' do
    it 'returns first page of items' do
      pager = described_class.new(bookmarks)
      items = pager.current_items
      expect(items.size).to eq(25)
      expect(items.first.title).to eq('Bookmark 1')
      expect(items.last.title).to eq('Bookmark 25')
    end

    it 'returns empty for empty list' do
      pager = described_class.new([])
      expect(pager.current_items).to eq([])
    end
  end

  describe '#advance?' do
    it 'advances to the next page' do
      pager = described_class.new(bookmarks)
      expect(pager.advance?).to be true
      expect(pager.current_page).to eq(1)
      expect(pager.current_items.first.title).to eq('Bookmark 26')
    end

    it 'returns false on last page' do
      pager = described_class.new(bookmarks)
      pager.advance?
      expect(pager.advance?).to be false
      expect(pager.current_page).to eq(1)
    end
  end

  describe '#go_back?' do
    it 'goes back to previous page' do
      pager = described_class.new(bookmarks)
      pager.advance?
      expect(pager.go_back?).to be true
      expect(pager.current_page).to eq(0)
    end

    it 'returns false on first page' do
      pager = described_class.new(bookmarks)
      expect(pager.go_back?).to be false
    end
  end

  describe '#next_page?' do
    it 'returns true when there are more pages' do
      pager = described_class.new(bookmarks)
      expect(pager.next_page?).to be true
    end

    it 'returns false on last page' do
      pager = described_class.new(bookmarks)
      pager.advance?
      expect(pager.next_page?).to be false
    end
  end

  describe '#prev_page?' do
    it 'returns false on first page' do
      pager = described_class.new(bookmarks)
      expect(pager.prev_page?).to be false
    end

    it 'returns true after advancing' do
      pager = described_class.new(bookmarks)
      pager.advance?
      expect(pager.prev_page?).to be true
    end
  end

  describe '#go_to?' do
    it 'jumps to a specific page' do
      pager = described_class.new(bookmarks)
      expect(pager.go_to?(1)).to be true
      expect(pager.current_page).to eq(1)
    end

    it 'returns false for invalid page numbers' do
      pager = described_class.new(bookmarks)
      expect(pager.go_to?(-1)).to be false
      expect(pager.go_to?(5)).to be false
    end
  end

  describe '#page_status' do
    it 'shows correct status for first page' do
      pager = described_class.new(bookmarks)
      expect(pager.page_status).to eq('Showing 1-25 of 50 (page 1/2)')
    end

    it 'shows correct status for last page with partial items' do
      pager = described_class.new(bookmarks)
      pager.advance?
      expect(pager.page_status).to eq('Showing 26-50 of 50 (page 2/2)')
    end

    it "shows 'No items' for empty list" do
      pager = described_class.new([])
      expect(pager.page_status).to eq('No items')
    end
  end

  describe '#render' do
    it 'outputs formatted bookmarks and status' do
      pager = described_class.new(bookmarks, page_size: 2)
      output = StringIO.new
      pager.render(output: output)
      text = output.string
      expect(text).to include('1. Bookmark 1')
      expect(text).to include('https://example.com/1')
      expect(text).to include('2. Bookmark 2')
      expect(text).to include('Showing 1-2 of 50')
    end

    it 'shows message for empty list' do
      pager = described_class.new([])
      output = StringIO.new
      pager.render(output: output)
      expect(output.string).to include('No bookmarks found.')
    end
  end

  describe '#interactive' do
    it 'displays page and processes quit' do
      pager = described_class.new(bookmarks, page_size: 2)
      input = StringIO.new("q\n")
      output = StringIO.new
      pager.interactive(input: input, output: output)
      expect(output.string).to include('1. Bookmark 1')
      expect(output.string).to include('[n]ext')
      expect(output.string).to include('[q]uit')
    end

    it 'navigates forward and back' do
      pager = described_class.new(bookmarks, page_size: 2)
      input = StringIO.new("n\np\nq\n")
      output = StringIO.new
      pager.interactive(input: input, output: output)
      text = output.string
      expect(text).to include('Bookmark 3') # page 2
      expect(text).to include('Bookmark 1') # back to page 1
    end

    it 'handles page number input' do
      pager = described_class.new(bookmarks, page_size: 25)
      input = StringIO.new("2\nq\n")
      output = StringIO.new
      pager.interactive(input: input, output: output)
      expect(output.string).to include('Bookmark 26')
    end

    it 'handles invalid page number' do
      pager = described_class.new(bookmarks, page_size: 25)
      input = StringIO.new("99\nq\n")
      output = StringIO.new
      pager.interactive(input: input, output: output)
      expect(output.string).to include('Invalid page number')
    end

    it 'handles unknown commands' do
      pager = described_class.new(bookmarks, page_size: 25)
      input = StringIO.new("xyz\nq\n")
      output = StringIO.new
      pager.interactive(input: input, output: output)
      expect(output.string).to include('Unknown command')
    end

    it 'handles EOF on input' do
      pager = described_class.new(bookmarks, page_size: 25)
      input = StringIO.new('')
      output = StringIO.new
      pager.interactive(input: input, output: output)
      expect(output.string).to include('Bookmark 1')
    end

    it "shows 'already on last page' message" do
      pager = described_class.new(bookmarks, page_size: 25)
      input = StringIO.new("n\nn\nq\n")
      output = StringIO.new
      pager.interactive(input: input, output: output)
      expect(output.string).to include('Already on last page')
    end

    it "shows 'already on first page' message" do
      pager = described_class.new(bookmarks, page_size: 25)
      input = StringIO.new("p\nq\n")
      output = StringIO.new
      pager.interactive(input: input, output: output)
      expect(output.string).to include('Already on first page')
    end

    it "accepts 'next' and 'prev' as full words" do
      pager = described_class.new(bookmarks, page_size: 2)
      input = StringIO.new("next\nprev\nquit\n")
      output = StringIO.new
      pager.interactive(input: input, output: output)
      text = output.string
      expect(text).to include('Bookmark 3') # page 2
      expect(text).to include('page 1/') # back to page 1
    end

    it "accepts 'exit' command" do
      pager = described_class.new(bookmarks, page_size: 25)
      input = StringIO.new("exit\n")
      output = StringIO.new
      pager.interactive(input: input, output: output)
      expect(output.string).to include('Bookmark 1')
    end
  end
end
