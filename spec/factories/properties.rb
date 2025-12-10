FactoryBot.define do
  factory :property do
    title { "MyString" }
    description { "MyText" }
    address { "MyString" }
    city { "MyString" }
    province { "MyString" }
    postal_code { "MyString" }
    country { "MyString" }
    property_type { "MyString" }
    accommodation_type { "MyString" }
    status { "MyString" }
    landlord { nil }
  end
end
