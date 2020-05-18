require 'rails_helper'

RSpec.describe "todo_items/index", type: :view do
  before(:each) do
    assign(:todo_items, [
      TodoItem.create!(
        :title => "Title",
        :description => "MyText",
        :completed => false
      ),
      TodoItem.create!(
        :title => "Title",
        :description => "MyText",
        :completed => false
      )
    ])
  end

  it "renders a list of todo_items" do
    render
    assert_select "tr>td", :text => "Title".to_s, :count => 2
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
    assert_select "tr>td", :text => false.to_s, :count => 2
  end
end
