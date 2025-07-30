# Personal Coach API

This is the Rails API backend for the Personal Coach application.

## Development Setup

### Ruby version
Ruby 3.1.1

### System dependencies
- PostgreSQL
- Redis (optional)

### Configuration
1. Copy `config/database.yml.example` to `config/database.yml` and configure your database
2. Run `bundle install` to install dependencies

### Database creation
```bash
rails db:create
rails db:migrate
```

### Database initialization
```bash
rails db:seed
```

### How to run the test suite
```bash
bundle exec rspec
```

### Code Quality

#### RuboCop
This project uses RuboCop for code linting and style enforcement.

**Quick Start:**
```bash
# Run RuboCop on all code
./bin/rubocop

# Run RuboCop on specific files/directories
./bin/rubocop app/models/
./bin/rubocop spec/

# Run RuboCop manually with bundle exec
bundle exec rubocop
```

**Configuration:**
- Configuration file: `.rubocop.yml`
- Uses Rails and RSpec specific cops
- Auto-corrects many style issues automatically

### Services (job queues, cache servers, search engines, etc.)
- OpenAI API integration for AI features

### Deployment instructions
TBD
