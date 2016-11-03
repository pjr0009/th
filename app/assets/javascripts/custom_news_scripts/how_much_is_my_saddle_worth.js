var app = angular.module("TackHunter")

app.controller("saddleAppCtrl", ["$scope", "Discipline", "Brand", "Product", "Sale", "$http", function($scope, Discipline, Brand, Product, Sale, $http){
  $scope.englishSeatSizes = ["", "16", "16.5", "17", "17.5", "18", "18.5", "19"].reverse();
  $scope.westernSeatSizes = ["", "13", "13.5", "14", "14.5", "15", "15.5", "16", "16.5", "17"].reverse();
  $scope.englishTreeWidths = ["", "Narrow", "Regular","Medium", "Medium Wide", "Wide"].reverse();
  $scope.westernTreeWidths = ["", "Semi-QH", "Full-QH", "Arabian", "Gaited", "Haflinger", "Draft"].reverse();
  $scope.conditions = ["", "Brand New", "Excellent", "Good", "Fair", "Poor"].reverse();
  $scope.loading = true;

  $scope.saddleConfiguration = {
    seatSize: "",
    treeWidth: "",
    condition: "",
    saddleType: ""
  };

  $scope.showSubmitButton = function () {
    return $scope.saddleConfiguration.treeWidth && 
    $scope.saddleConfiguration.seatSize && 
    $scope.saddleConfiguration.condition && 
    ($scope.saddleConfiguration.brand || $scope.brandSearchText.length > 0 )&& 
    ($scope.saddleConfiguration.product || $scope.productSearchText.length > 0);
  }
  $scope.estimateData = {};
  $scope.slidesElement = document.getElementById("slides");
  $scope.currentSlideElement = document.getElementsByClassName("slide")[0];
  $scope.numberOfSlides = 10;
  $scope.currentSlide = 0;
  $scope.nextStep = function() {
    $scope.caclulateAndSetNextSlideNumber();
  }
  $scope.previousStep = function() {
    $scope.caclulateAndSetPreviousSlideNumber();
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
    $scope.saddleConfiguration = {
      seatSize: "",
      treeWidth: "",
      condition: "",
      saddleType: "",
      product: "",
      brand: ""
    };
    $scope.brandSearchText = "";
    $scope.productSearchText = "";
    $scope.currentSlide = -1;
    $scope.nextStep();
  };


  $scope.setDiscipline = function(typeName){
    $scope.saddleConfiguration.discipline = typeName;
    $scope.nextStep();

  }


  $scope.persistAnyNewConfigurations = function() {
    var newBrand = new Brand();
    newBrand.name = $scope.brandSearchText
    newBrand.$save(function(response){
      $scope.saddleConfiguration.brand = response
      var newProduct = new Product()
      newProduct.brand_id = response.id
      newProduct.model = $scope.productSearchText;
      newProduct.$save(function(response){
        $scope.saddleConfiguration.product = response
        $scope.getSaddleWorth(response.brand_id, response.id);
        $scope.nextStep();            
      });   
    });
  }

  $scope.brandSearchTextChange = function (searchText) {
    return Brand.query({q: searchText}).$promise;
  }

  $scope.productSearchTextChange = function (searchText) {
    var query = {q: searchText};
    if($scope.saddleConfiguration.brand && $scope.saddleConfiguration.brand.id){
      query["brand_id"] = $scope.saddleConfiguration.brand.id
    }
    return Product.query(query).$promise;
  }

  $scope.getSaddleWorth = function(brand_id, product_id){
    Sale.query({brand_id: brand_id, product_id: product_id, sync_external: true}, function(response) {
      $scope.loading = false;
      $scope.estimateData = response;
    })
  };

  $scope.letsFindText = function(){
    return "Let's find your " + $scope.saddleConfiguration.discipline + " saddle";
  }
  $scope.disciplines = Discipline.query();


}])