class TodoItem < ActiveRecord::Base

  def self.completed?
    where(completed: true).count
  end
end
