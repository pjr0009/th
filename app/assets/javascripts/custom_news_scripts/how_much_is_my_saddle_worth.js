//= require angular
//= require angular-resource
//= require angucomplete
var app = angular.module("saddleApp", ['ngResource','angucomplete'])

app.factory('Discipline', ["$resource", function($resource) {
  return $resource('/disciplines/:id'); // Note the full endpoint address
}]);
app.factory('Brand', ["$resource", function($resource) {
  return $resource('/brands/:id'); // Note the full endpoint address
}]);

app.factory('Product', ["$resource", function($resource) {
  return $resource('/products/:id'); // Note the full endpoint address
}]);

app.controller("saddleAppCtrl", ["$scope", "Discipline", "Brand", "Product", "$http", function($scope, Discipline, Brand, Product, $http){
  $scope.seatSizes = ["", "16", "16.5", "17", "17.5", "18", "18.5", "19"].reverse();
  $scope.treeWidths = ["", "Medium", "Medium Wide", "Wide"].reverse();
  $scope.conditions = ["", "Brand New", "Excellent", "Good", "Fair", "Poor"].reverse();

  $scope.saddleConfiguration = {
    seatSize: "",
    treeWidth: "",
    condition: "",
    saddleType: "",
    brand: {
      originalObject: {
        name: ""
      }
    },
    product: {
      originalObject: {
        model: ""
      }
    }
  };

  $scope.showSubmitButton = function () {
    return $scope.saddleConfiguration.treeWidth && 
    $scope.saddleConfiguration.seatSize && 
    $scope.saddleConfiguration.condition && 
    $scope.saddleConfiguration.brand && 
    $scope.saddleConfiguration.product;
  }
  $scope.estimateData = {};
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
    $scope.caclulateAndSetPreviousSlideNumber();
    var newTransform = $scope.calculateNextTransform();
    $scope.slidesElement.style.transform = "translateX(" + newTransform + "px)";
  }
  $scope.caclulateAndSetPreviousSlideNumber = function(){
    if(($scope.currentSlide - 1) <= 0){
      $scope.currentSlide = 0;
    } else {
      $scope.currentSlide -= 1;
    }
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
    return $scope.currentSlide * currentWidth * -1;
  }

  $scope.reset = function() {
    $scope.currentSlide = -1;
    $scope.nextStep();
    document.getElementById("productModel_value").value = "";
    document.getElementById("brandName_value").value = "";
    $scope.saddleConfiguration = {
      seatSize: "",
      treeWidth: "",
      condition: "",
      saddleType: "",
      brand: {
        originalObject: {
          name: ""
        }
      },
      product: {
        originalObject: {
          model: ""
        }
      }
    };
  };


  $scope.setDiscipline = function(typeName){
    $scope.saddleConfiguration.discipline = typeName;
    $scope.nextStep();
  }


  $scope.persistAnyNewConfigurations = function() {
    var newBrand = new Brand()
    newBrand.name = document.getElementById("brandName_value").value
    newBrand.$save(function(response){
      console.log(response);
      $scope.saddleConfiguration.brand.originalObject = response
      var newProduct = new Product()
      newProduct.brand_id = response.id
      newProduct.model = document.getElementById("productModel_value").value
      newProduct.$save(function(response){
        $scope.saddleConfiguration.product.originalObject = response
        $scope.getSaddleWorth();
        $scope.nextStep();            
      });   
    });
  }

  $scope.getSaddleWorth = function(){
    console.log($scope.saddleConfiguration)
    $http.get("/products/get_estimate", {
      params: {brand: $scope.saddleConfiguration.brand.originalObject.name, model: $scope.saddleConfiguration.product.originalObject.model}
    }).success(function(response){
      $scope.estimateData = response;
    })
  };

  $scope.letsFindText = function(){
    return "Let's find your " + $scope.saddleConfiguration.discipline + " saddle";
  }
  $scope.disciplines = Discipline.query();


}])