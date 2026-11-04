class Account < ApplicationRecord
  validates :sleeper_username, :sleeper_user_id, presence: true

  def self.current = first
end
