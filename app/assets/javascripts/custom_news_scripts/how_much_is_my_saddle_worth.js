//= require angular
//= require angular-resource
//= require angucomplete
var app = angular.module("saddleApp", ['ngResource','angucomplete'])

app.factory('Discipline', function($resource) {
  return $resource('/disciplines/:id'); // Note the full endpoint address
});

app.controller("saddleAppCtrl", ["$scope", "Discipline", function($scope, Discipline){
  $scope.saddleConfiguration = {
    saddleType: "",
    brand: "",
    model: ""
  };
  $scope.slidesElement = document.getElementById("slides");
  $scope.currentSlideElement = document.getElementsByClassName("slide")[0];
  $scope.numberOfSlides = 10;
  $scope.currentSlide = 0;
  $scope.nextStep = function() {
    $scope.caclulateAndSetNextSlideNumber();
    var newTransform = $scope.calculateNextTransform();
    $scope.slidesElement.style.transform = "translateX(" + newTransform + "px)";
  }
  $scope.previousStep = function() {
    $scope.caclulateAndSetNextSlideNumber();
    var newTransform = $scope.calculatePreviousTransform();
    $scope.slidesElement.style.transform = "translateX(" + newTransform + "px)";
  }
  $scope.caclulateAndSetNextSlideNumber = function(){
    if(($scope.currentSlide + 1) > $scope.numberOfSlides){
      $scope.currentSlide = 0;
    } else {
      $scope.currentSlide += 1;
    }
  }
  $scope.calculateNextTransform = function(){
    var currentWidth = $scope.currentSlideElement.offsetWidth;
    console.log(currentWidth);
    return $scope.currentSlide * currentWidth * -1;
  }

  $scope.setDiscipline = function(typeName){
    $scope.saddleConfiguration.discipline = typeName;
    $scope.nextStep();
  }

  $scope.letsFindText = function(){
    return "Let's find your " + $scope.saddleConfiguration.discipline + " saddle";
  }
  $scope.disciplines = Discipline.query();


}])