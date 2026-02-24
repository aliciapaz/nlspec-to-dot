# nlspec-to-dot

Compile natural language specifications (NLSpecs) describing Rails apps into DOT pipeline files executable by [attractor-rb](https://github.com/aliciapaz/attractor-rb).

**NLSpec markdown → compile → DOT pipeline → `attractor run`**

## Installation

```bash
gem build nlspec_to_dot.gemspec
gem install nlspec_to_dot-0.1.0.gem
```

Or add to your Gemfile:

```ruby
gem "nlspec-to-dot"
```

## Usage

```bash
nlspec-to-dot compile spec.md -o pipeline.dot
attractor run pipeline.dot --backend codex --interviewer console
```

Options:

- `-o, --output` — Output file path (prints to stdout if omitted)
- `--app-name` — Override the app name extracted from the spec

## NLSpec Format

Structured markdown with `# AppName`, `## Models`, `## Features`, and `## Constraints` sections:

```markdown
# SimpleBlog

A simple blog application where users can create and publish posts.

## Models

### User
- email:string
- name:string
- has_many :posts
- validates :email, presence: true, uniqueness: true

### Post
- title:string
- body:text
- belongs_to :user
- validates :title, presence: true

## Features

### Publishing Posts
Users can create draft posts and publish them.
Related models: Post, User

## Constraints
- Authentication: has_secure_password
- Authorization: ActionPolicy
- Frontend: Hotwire (Turbo + Stimulus)
- Testing: RSpec with FactoryBot
```

## What it produces

A DOT digraph with stages for scaffolding, models (topologically sorted by `belongs_to` dependencies), routes, controllers, services, views, tests, a test runner, a pass/fail gate with retry loop, and a human review gate. All `box` nodes include prompts with embedded Telos conventions.

The output passes all 13 attractor lint rules.
The scaffold `tool` stage uses a `10m` timeout to accommodate initial `rails new` and dependency setup.

Generated DOT is backend-agnostic; choose `simulation`, `codex`, or `claude` when running the pipeline with `attractor run --backend ...`.

## Development

```bash
bundle install
bundle exec rspec
bundle exec standardrb
```

## License

MIT
