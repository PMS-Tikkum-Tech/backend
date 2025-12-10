FactoryBot.define do
  factory :booking do
    tenant { nil }
    room { nil }
    start_date { "2025-12-10" }
    end_date { "2025-12-10" }
    total_price { "9.99" }
    status { "MyString" }
    notes { "MyText" }
  end
end
