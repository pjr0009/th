app = angular.module("TackHunter")
app.controller("newListingCtrl", ["$scope", ($scope) ->
  $scope.listing = {}
  $scope.disciplines = [{name: "Dressage"}, {name: "Hunter-Jumper"}, {name: "Western"}]
  $scope.categories = [
    {
      name: "Saddles"
    },
    {
      name: "Riding Boots"
    },
    {
      name: "Horse Blankets"
    }
  ]

])