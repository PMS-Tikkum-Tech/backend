FactoryBot.define do
  factory :review do
    tenant { nil }
    property { nil }
    rating { 1 }
    comment { "MyText" }
  end
end
