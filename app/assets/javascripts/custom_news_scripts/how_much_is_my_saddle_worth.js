//= require angular
var app = angular.module("saddleApp", [])
app.controller("saddleAppCtrl", ["$scope", function($scope){
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

  $scope.setSaddleType = function(typeName){
    $scope.saddleConfiguration.saddleType = typeName;
    $scope.nextStep();
  }

  $scope.letsFindText = function(){
    return "Let's find your " + $scope.saddleConfiguration.saddleType + " saddle";
  }

  $scope.saddleTypes = [
    {"name": "Dressage", "image":"https://s3.amazonaws.com/assets.tackhunter.com/news/dressage-saddle.jpeg"},
    {"name": "Jumping", "image": "https://s3.amazonaws.com/assets.tackhunter.com/news/jumping-saddle.jpeg"},
    {"name": "All Purpose", "image": "https://s3.amazonaws.com/assets.tackhunter.com/news/general-purpose-saddle.jpg"}
  ]
}])