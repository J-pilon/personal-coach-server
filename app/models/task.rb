class Task < ApplicationRecord
  validates :title, presence: true

  enum action_category: {
    do: 1,
    defer: 2,
    delegate: 3
  }
end
