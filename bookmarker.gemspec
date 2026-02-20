# frozen_string_literal: true

require_relative 'lib/bookmarker/version'

Gem::Specification.new do |spec|
  spec.name = 'bookmarker'
  spec.version = Bookmarker::VERSION
  spec.authors = ['David Doolin']
  spec.summary = 'Extract and browse Firefox bookmarks from the terminal'
  spec.description = 'Reads Firefox bookmarks directly from the places.sqlite database ' \
                     'and presents them in a paginated terminal interface.'
  spec.homepage = 'https://github.com/daviddoolin/bookmarker'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.2.0'

  spec.files = Dir['lib/**/*.rb', 'exe/*', 'LICENSE', 'README.md']
  spec.bindir = 'exe'
  spec.executables = ['bookmarker']

  spec.add_dependency 'sqlite3', '~> 2.0'

  spec.metadata['rubygems_mfa_required'] = 'true'
end
