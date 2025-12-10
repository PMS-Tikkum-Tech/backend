FactoryBot.define do
  factory :room do
    name { "MyString" }
    description { "MyText" }
    property { nil }
    price { "9.99" }
    size { "9.99" }
    capacity { 1 }
    status { "MyString" }
    available_from { "2025-12-10" }
    amenities { "MyText" }
  end
end
