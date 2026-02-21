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
- belongs_to :user
- validates :title, presence: true

## Features

### Publishing Posts
Users can create draft posts and publish them.
Related models: Post, User

### User Registration
New users can sign up with email and password.
Related models: User

## Constraints
- Authentication: has_secure_password
- Authorization: ActionPolicy
- Frontend: Hotwire (Turbo + Stimulus)
- Testing: RSpec with FactoryBot
