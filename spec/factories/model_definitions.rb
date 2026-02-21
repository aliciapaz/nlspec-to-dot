# frozen_string_literal: true

FactoryBot.define do
  factory :model_definition, class: "NlspecToDot::Parser::ModelDefinition" do
    name { "Thing" }
    fields { [{name: "name", type: "string"}] }
    associations { [] }
    validations { [] }

    initialize_with do
      new(name: name, fields: fields, associations: associations, validations: validations)
    end

    trait :user do
      name { "User" }
      fields { [{name: "email", type: "string"}, {name: "name", type: "string"}] }
      associations { [{kind: :has_many, target: "Post"}] }
      validations { ["validates :email, presence: true, uniqueness: true"] }
    end

    trait :post do
      name { "Post" }
      fields { [{name: "title", type: "string"}, {name: "body", type: "text"}] }
      associations { [{kind: :belongs_to, target: "User"}] }
      validations { ["validates :title, presence: true"] }
    end

    trait :independent do
      name { "Tag" }
      fields { [{name: "label", type: "string"}] }
      associations { [] }
      validations { [] }
    end
  end
end
