# frozen_string_literal: true

FactoryBot.define do
  factory :document, class: "NlspecToDot::Parser::Document" do
    app_name { "TestApp" }
    description { "A test application" }
    models { [] }
    features { [] }
    constraints { [] }

    initialize_with do
      new(
        app_name: app_name,
        description: description,
        models: models,
        features: features,
        constraints: constraints
      )
    end

    trait :with_models do
      models do
        [
          build(:model_definition, :user),
          build(:model_definition, :post)
        ]
      end
    end

    trait :with_features do
      features do
        [
          NlspecToDot::Parser::FeatureDefinition.new(
            name: "Publishing",
            description: "Users can publish posts",
            related_models: ["Post", "User"]
          )
        ]
      end
    end

    trait :with_constraints do
      constraints do
        [
          NlspecToDot::Parser::ConstraintDefinition.new(key: "Authentication", value: "has_secure_password"),
          NlspecToDot::Parser::ConstraintDefinition.new(key: "Authorization", value: "ActionPolicy")
        ]
      end
    end

    trait :full do
      with_models
      with_features
      with_constraints
    end
  end
end
