app = angular.module("TackHunter")
app.controller("newListingCtrl", ["$scope", "$http", ($scope, $http) ->
  $scope.listing = {}
  $scope.selectedStep = 0
  $scope.step = [
    {complete: true}
  ]
  $scope.disciplines = [{name: "English Riders", slug: "hunter-jumper"}, {name: "Western Riders", slug: "western"}, {name: "Both", slug:"endurance"}]
  

  $scope.fetchCategories = () ->
    if $scope.listing.discipline_id
      $http.get("/" + $scope.listing.discipline_id + "/categories").success (data) ->
        $scope.categories = data

  $scope.nextStep = () ->
    $scope.selectedStep += 1 if $scope.selectedStep < 4

  $scope.conditions = ["New", "Excellent", "Good", "Fair", "Poor/Non-Functioning"]
])