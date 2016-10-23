app = angular.module("TackHunter")
app.controller("newListingCtrl", ["$scope", "$http", ($scope, $http) ->
  $scope.listing = {}
  $scope.selected = 1
  $scope.step = [
    {complete: true}
  ]
  $scope.disciplines = [{name: "English", slug: "english"}, {name: "Western", slug: "western"}, {name: "Doesn't Matter"}]
  $scope.fetchCategories = () ->
    if $scope.listing.discipline_id
      $http.get("/" + $scope.listing.discipline_id + "/categories").success (data) ->
        $scope.categories = data

  $scope.conditions = ["New", "Excellent", "Good", "Fair", "Poor/Non-Functioning"]
])