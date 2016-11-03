Feature: Signed out user creates a new listing

  # Scenario: I should see the new listing link
  #   Given I am on the home page
  #   Then I should see a link to sell my item
  
  # Scenario: I should be able to visit the new listing page
  #   Given I am on the home page
  #   And I click the sell link
  #   Then I should see the new listing page

  # Scenario: I should see the next button when I fill out the new listing info form correctly
  #   Given I am on the new listing page
  #   And the next button is disabled
  #   And I fill in the info form correctly
  #   Then the next button should be enabled
  
  # Scenario: I should see category section when I fill out the new listing info form correctly and click next
  #   Given I am on the new listing page
  #   And the next button is disabled
  #   And the category section is not visible
  #   And I fill in the info form correctly
  #   And I click the next button
  #   Then I should see the category section
  
  # Scenario: On the category section I should see a list of top level categories for the selected discipline
  #   Given I am on the new listing page
  #   And I fill in the info form correctly for the english discipline
  #   And I click the next button
  #   Then I should see a list of top level categories for the english discipline

  # Scenario: On the category section I should see a list of subcategories when I pick a top level category that has subcategories
  #   Given I am on the new listing page
  #   And I fill in the info form correctly for the english discipline
  #   And I click the next button
  #   And I click the english saddles category
  #   Then I should see a list of saddle subcategories

  # Scenario: On the category section I should not see a list of subcategories if the top level category has no subcategories
  #   Given I am on the new listing page
  #   And I fill in the info form correctly for the english discipline
  #   And I click the next button
  #   And I click the english saddles category
  #   Then I should see a list of saddle subcategories
  #   And I click the breeches category
  #   Then I should not see a list of subcategories

  Scenario: Should only be required to fill out a category if no subcategories exist
    Given I am on the new listing page
    And I fill in the info form correctly for the english discipline
    And I click the next button
    And the next button is disabled
    And I click the breeches category
    And I click the next button
    Then I should be on the details step

  Scenario: On the details section I should be required to fill out a description
    Given I am on the new listing page
    And I fill in the info form correctly for the english discipline
    And I click the next button
    And I click the breeches category
    And I click the next button
    And the next button is disabled
    And I fill in the description
    And I click the next button
    Then I should be on the photos step

  # Scenario: I should not be able to progress to categories and see a general message if more than one info field is incomplete
  #   Given I am on the new listing page
  #   And I do not see the next button
  #   #implicitly not filling in form
  #   When I click step 1
  #   Then I should see a notification that the current step is incomplete
  #   And I should be on step 0

  # Scenario: I should see a specific error message if one info field is missing and i click on 
  #   Given I am on the new listing page
  #   And I do not see the next button
  #   And I fill in the info form correctly
  #   And I delete the brand field
  #   And I click step 1
  #   And I obseve an error message for brand
  #   And I fill in the info form correctly
  #   And I delete the field
  #   And I click step 1
  #   And I obseve an error message for brand

  #   When I click step 1
  #   And I see a notification that the brand is missing
  #   And I fill in the brand 
  #   And I should be on step 0