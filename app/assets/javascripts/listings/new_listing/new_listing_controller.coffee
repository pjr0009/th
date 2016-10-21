app = angular.module("TackHunter")
app.controller("newListingCtrl", ["$scope", "$http", ($scope, $http) ->
  $scope.listing = {}
  $scope.disciplines = [{name: "Dressage", slug: "dressage"}, {name: "Hunter-Jumper", slug: "hunter-jumper"}, {name: "Western"}]
  $scope.fetchCategories = () ->
    if $scope.listing.discipline_id
      $http.get("/" + $scope.listing.discipline_id + "/categories").success (data) ->
        $scope.categories = data
])