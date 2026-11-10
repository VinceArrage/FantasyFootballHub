class AddNeedsToTradeIdeas < ActiveRecord::Migration[8.1]
  def change
    add_column :trade_ideas, :my_need, :string
    add_column :trade_ideas, :their_need, :string
  end
end
