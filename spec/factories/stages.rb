# frozen_string_literal: true

FactoryBot.define do
  factory :stage, class: "NlspecToDot::Planner::Stage" do
    id { "task_1" }
    label { "Task 1" }
    shape { "box" }
    prompt { "Do something" }
    attrs { {} }

    initialize_with do
      new(id: id, label: label, shape: shape, prompt: prompt, attrs: attrs)
    end

    trait :start do
      id { "start" }
      label { "Start" }
      shape { "Mdiamond" }
      prompt { nil }
    end

    trait :exit do
      id { "exit" }
      label { "Exit" }
      shape { "Msquare" }
      prompt { nil }
    end

    trait :conditional do
      id { "gate" }
      label { "Check" }
      shape { "diamond" }
      prompt { nil }
    end

    trait :human do
      id { "review" }
      label { "Review" }
      shape { "hexagon" }
      prompt { nil }
    end

    trait :tool do
      id { "run_tests" }
      label { "Run Tests" }
      shape { "parallelogram" }
      prompt { "bundle exec rspec" }
    end
  end
end
