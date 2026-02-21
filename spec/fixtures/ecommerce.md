# ShopApp

An e-commerce platform with products, orders, and payments.

## Models

### Organization
- name:string
- slug:string
- has_many :users
- validates :name, presence: true

### User
- email:string
- name:string
- belongs_to :organization
- has_many :orders
- validates :email, presence: true, uniqueness: true

### Product
- name:string
- price:decimal
- description:text
- belongs_to :organization
- has_many :line_items
- validates :name, presence: true
- validates :price, numericality: { greater_than: 0 }

### Order
- status:string
- total:decimal
- belongs_to :user
- has_many :line_items
- validates :status, inclusion: { in: %w[pending paid shipped] }

### LineItem
- quantity:integer
- price:decimal
- belongs_to :order
- belongs_to :product
- validates :quantity, numericality: { greater_than: 0 }

## Features

### Product Catalog
Browse and search products by organization.
Related models: Product, Organization

### Checkout Flow
Users add items to cart and complete purchase.
Related models: Order, LineItem, Product, User

### Order Management
Users can view their order history and status.
Related models: Order, User

## Constraints
- Authentication: has_secure_password
- Authorization: ActionPolicy
- Frontend: Hotwire (Turbo + Stimulus)
- Testing: RSpec with FactoryBot
