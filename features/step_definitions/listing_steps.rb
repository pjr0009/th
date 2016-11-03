Given(/^I am on the new listing page$/) do
  visit "/sell"
end

Given(/^I am on the home page$/) do
  visit "/"
end

Then(/^I should see a link to sell my item$/) do
  page.assert_selector("#new-listing-link")
end

Given(/^I click the sell link$/) do
  page.find("#new-listing-link").click
end


Then(/^I should see the new listing page$/) do
  page.assert_selector("form[name='listingForms.infoForm']")
end

Given(/^I fill in the info form correctly$/) do
  sleep 1
  page.find("[name='brand']").find('input').set("Prestige")
  page.fill_in 'model', :with => 'Nona Garson'
  page.fill_in 'title', :with => 'Awesome Prestige Nona Garson, Great Condition'
  page.fill_in 'price', :with => '100'
  page.fill_in 'shipping_price', :with => '50'
  page.find("md-select[name='condition']").click
  sleep 1
  page.first("md-option[value='New']").click
  page.first("md-radio-button[value='english']").click
end

Given(/^the next button is disabled$/) do
  page.assert_selector(".md-button#next-button[disabled]")
end

Then(/^the next button should be enabled$/) do
  page.assert_no_selector(".md-button#next-button[disabled]")
end

Given(/^I click the next button$/) do
  page.find(".md-button#next-button").click
  sleep 1
end

Given(/^the category section is not visible$/) do
  page.assert_no_selector("md-content#categories", visible: true)
end

Then(/^I should see the category section$/) do
  page.assert_selector("md-content#categories", visible: true)
end

Given(/^I fill in the info form correctly for the english discipline$/) do
  steps %Q{
    And I fill in the info form correctly
  }
end

Then(/^I should see a list of top level categories for the english discipline$/) do
  english = Discipline.find("english").categories.where(:parent_id => nil)
  english_sub = Discipline.find("english").categories.where("parent_id IS NOT NULL")
  western = Discipline.find("western").categories
  english.each do |category|
    page.assert_selector("md-radio-button[value='#{category.id}']")
  end
  english_sub.each do |category|
    page.assert_no_selector("md-radio-button[value='#{category.id}']")
  end
  western.each do |category|
    page.assert_no_selector("md-radio-button[value='#{category.id}']")
  end
end

Given(/^I click the english saddles category$/) do

  cat = Discipline.find("english").categories.where(:name => "Saddles").first
  page.first("md-radio-button[value='#{cat.id}']").click
end

Then(/^I should see a list of saddle subcategories$/) do
  english_sub = Discipline.find("english").categories.where("parent_id IS NOT NULL")
  western = Discipline.find("western").categories
  #wait for ajax
  sleep 2
  english_sub.each do |category|
    if category.parent.slug == "saddles"
      page.assert_selector("md-radio-button[value='#{category.id}']")
    else
      page.assert_no_selector("md-radio-button[value='#{category.id}']")
    end
  end
  western.each do |category|
    page.assert_no_selector("md-radio-button[value='#{category.id}']")
  end
end

Given(/^I click the breeches category$/) do
  cat = Discipline.find("english").categories.where(:name => "Breeches").first
  page.first("md-radio-button[value='#{cat.id}']").click
end

Then(/^I should not see a list of subcategories$/) do
  english_sub = Discipline.find("english").categories.where("parent_id IS NOT NULL")
  western = Discipline.find("western").categories
  english_sub.each do |category|
    page.assert_no_selector("md-radio-button[value='#{category.id}']")
  end
  western.each do |category|
    page.assert_no_selector("md-radio-button[value='#{category.id}']")
  end
end

Then(/^I should be on the details step$/) do
  page.assert_selector("md-content#details", visible: true)
end

Given(/^I fill in the description$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^I should be on the photos step$/) do
  page.assert_selector("md-content#photos", visible: true)
  pending # Write code here that turns the phrase above into concrete actions
end


