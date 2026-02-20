# frozen_string_literal: true

RSpec.describe Bookmarker do
  it 'has a version number' do
    expect(Bookmarker::VERSION).not_to be_nil
    expect(Bookmarker::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
  end

  it 'defines Error as a StandardError subclass' do
    expect(Bookmarker::Error.new).to be_a(StandardError)
  end

  it 'defines ProfileNotFoundError as an Error subclass' do
    expect(Bookmarker::ProfileNotFoundError.new).to be_a(Bookmarker::Error)
  end

  it 'defines DatabaseNotFoundError as an Error subclass' do
    expect(Bookmarker::DatabaseNotFoundError.new).to be_a(Bookmarker::Error)
  end
end
