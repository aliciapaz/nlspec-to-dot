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

Structured markdown with `# AppName`, `## Models`, `## Features`, `## Constraints`, `## Assets`, and `## Seeds` sections:

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
- published:boolean
- enum status: { draft: 0, published: 1 }
- belongs_to :user
- has_many :comments, dependent: :destroy
- has_one_attached :cover_image
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

## Assets
- chart.js: npm:chart.js@4.4.4 -> vendor/javascript/chart.umd.js

## Seeds
- Admin user: email=admin@example.com, name=Admin
```

## What it produces

A DOT digraph with stages for template cloning, models (topologically sorted and parallelized by `belongs_to` dependencies), routes, controllers, services, views, seeds, tests, a test runner, a pass/fail gate with retry loop, and a human review gate. Independent stages (models, controllers, views) run in parallel via fan-out/fan-in nodes. All `box` nodes include prompts with embedded Telos conventions.

The output passes all 13 attractor lint rules.

Generated DOT is backend-agnostic; choose `simulation`, `codex`, or `claude` when running the pipeline with `attractor run --backend ...`.

## Development

```bash
bundle install
bundle exec rspec
bundle exec standardrb
```

## License

MIT
