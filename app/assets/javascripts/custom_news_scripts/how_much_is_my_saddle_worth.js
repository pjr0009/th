//= require angular
//= require angular-resource
//= require angucomplete
var app = angular.module("saddleApp", ['ngResource','angucomplete'])

app.factory('Discipline', function($resource) {
  return $resource('/disciplines/:id'); // Note the full endpoint address
});
app.factory('Brand', function($resource) {
  return $resource('/brands/:id'); // Note the full endpoint address
});
app.controller("saddleAppCtrl", ["$scope", "Discipline", "Brand", function($scope, Discipline, Brand){
  $scope.saddleConfiguration = {
    saddleType: "",
    brand: {
      name: ""
    },
    model: {
      name: ""
    }
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

  $scope.persistAnyNewConfigurations = function (){
    if($scope.saddleConfiguration.brand.name){
      $scope.nextStep();
    } else {
      var newBrand = new Brand()
      newBrand.name = document.getElementById("brandName_value").value
      newBrand.$save(function(){
        $scope.nextStep();
      })
    }
  }

  $scope.letsFindText = function(){
    return "Let's find your " + $scope.saddleConfiguration.discipline + " saddle";
  }
  $scope.disciplines = Discipline.query();


}])