# Server — Personal Coach API

Rails 7.2 / Ruby 3.3 / PostgreSQL. Run all commands from this directory (`server/`).

## Definition of done (`/verify`)

Before marking a branch ready for review or merge, all three of the following must pass. Run them from `server/`:

1. **Tests** — `bundle exec rspec` must report `0 failures`.
2. **ERB lint** — `bundle exec erb_lint --lint-all` must report `No errors were found in ERB files`.
3. **RuboCop** — `bundle exec rubocop` must report `no offenses detected`.

If any step fails:

- Fix the root cause; do not skip, disable, or `--no-verify` around a failure.
- For RuboCop offenses that pre-date your branch (i.e., in files you did not touch), call them out explicitly in the PR description rather than silently ignoring them.
- Redis and Postgres must be running locally — `RedisClient::CannotConnectError` or `ActiveRecord::ConnectionNotEstablished` are environment issues, not test failures; start the services and re-run.

A branch is not "done" until all three commands are green on the final commit that will be reviewed.
