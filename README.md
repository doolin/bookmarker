# Bookmarker

Extract and browse Firefox bookmarks from the terminal.

Reads bookmarks directly from Firefox's `places.sqlite` database and presents them in a paginated terminal interface.

## Installation

```bash
gem install bookmarker
```

Or add to your Gemfile:

```ruby
gem "bookmarker"
```

## CLI Usage

```bash
# Browse all bookmarks (25 per page, interactive)
bookmarker

# Show total bookmark count
bookmarker --count

# List all bookmark folders
bookmarker --folders

# Filter by folder
bookmarker --folder "toolbar"

# Search by title, URL, or folder
bookmarker --search "ruby"

# Custom page size
bookmarker -n 10

# List detected Firefox profiles
bookmarker --profiles

# Use a specific database file
bookmarker -d /path/to/places.sqlite
```

### Interactive Navigation

When browsing bookmarks, use these commands at the prompt:

| Command | Action |
|---------|--------|
| `n` / `next` | Next page |
| `p` / `prev` | Previous page |
| `3` | Jump to page 3 (any number) |
| `q` / `quit` / `exit` | Exit |

### All Options

```
Usage: bookmarker [options]

Options:
    -d, --database PATH              Path to places.sqlite
    -s, --search TERM                Search bookmarks by title, URL, or folder
    -f, --folder NAME                Show bookmarks in a specific folder
        --folders                    List all bookmark folders
    -n, --per-page NUM               Bookmarks per page (default: 25)
        --profiles                   List available Firefox profiles with databases
    -c, --count                      Show total bookmark count and exit
    -v, --version                    Show version
    -h, --help                       Show this help
```

## Library Usage

```ruby
require "bookmarker"

# Auto-detect Firefox profile
finder = Bookmarker::ProfileFinder.new
db = Bookmarker::Database.new(finder.default_database)

# Access bookmarks
db.bookmarks.each do |bm|
  puts "#{bm.title} - #{bm.url} [#{bm.folder}]"
end

# Search
db.search("github").each { |bm| puts bm }

# Filter by folder
db.by_folder("toolbar").each { |bm| puts bm }

# List folders
db.folders # => ["Auth", "Bookmarks Toolbar", "Mozilla Firefox", ...]

# Paginate
pager = Bookmarker::Pager.new(db.bookmarks, page_size: 10)
pager.render           # Print current page
pager.next_page        # Advance
pager.interactive      # Full interactive loop
```

## How It Works

1. **Profile detection** locates Firefox's `places.sqlite` across macOS, Linux, and Windows
2. **Database access** copies the SQLite file to a tempfile before reading, avoiding lock conflicts with a running Firefox
3. Bookmarks are extracted by joining `moz_bookmarks` and `moz_places`, excluding internal `place:` URLs
4. Results are sorted by date added (newest first)

### Platform Paths

| Platform | Firefox Profiles Directory |
|----------|---------------------------|
| macOS | `~/Library/Application Support/Firefox/Profiles/` |
| Linux | `~/.mozilla/firefox/` |
| Windows | `%APPDATA%/Mozilla/Firefox/Profiles/` |

## Development

```bash
bundle install
bundle exec rspec       # Run specs
bundle exec rake        # Default task runs specs
```

SimpleCov is configured for line and branch coverage. Reports are generated in `coverage/`.

## Requirements

- Ruby >= 3.1
- Firefox (with at least one profile containing bookmarks)

## License

MIT
