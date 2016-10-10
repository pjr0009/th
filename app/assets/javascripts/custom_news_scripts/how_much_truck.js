var app = angular.module("TackHunter");
app.controller("truckAppCtrl", ["$scope", function($scope){
  $scope.toggles = {};
  $scope.toggles.aluminum = true;
  $scope.toggles.dressingRoom = false;
  $scope.toggles.livingQuarter = false;
  $scope.horseSlider = {
    value: 1,
    options: {
      floor: 1,
      ceil: 9,
      showTicks: true
    }
  };
  $scope.passengerSlider = {
    value: 1,
    options: {
      floor: 1,
      ceil: 5,
      showTicks: true
    }
  };
  $scope.getNumber = function(num) {
      return new Array(num);   
  }

  $scope.getResult = function(){
    var total = $scope.superTotal();
    if(total > 0 && total < 8350){
      return "1";
    } else if(total > 8350 && total < 14050) {
      return "2";
    } else if(total >  14050 && total < 20300) {
      return "3";
    } else if(total > 20300 && total < 28000) {
      return "4";
    } else if(total > 28000) {
      return "5";
    }
  }

  $scope.$watch("toggles", function(newVal, oldVal){
    if(newVal.aluminum != oldVal.aluminum || newVal.livingQuarter != oldVal.livingQuarter || newVal.dressingRoom != oldVal.dressingRoom){
      $scope.setAfterToggle();
    }
  }, true)

  $scope.$watch("horseSlider.value", function(newVal, oldVal){
    $scope.setAfterToggle();

  })

  $scope.setAfterToggle = function(){
    $scope.horseWeight = $scope.horseSlider.value * 1200;
    var start = ($scope.horseSlider.value) * 970 + 1300;
    $scope.trailerWeight = parseInt(start);    

    $scope.setTrailerWeight(start);
  }


  $scope.setTrailerWeight = function(startWeight) {
    var options = 0;
    
    if($scope.toggles.livingQuarter){
      options += 1100;
    }
    if($scope.toggles.dressingRoom){
      options += 400;
    }
    var total = startWeight + options;
    if($scope.toggles.aluminum){
      total = total * .90;
    }
    $scope.trailerWeight = parseInt(total);    
  }


  $scope.horseWeight = function() {
    return $scope.horseSlider.value * 1200;
  };
  $scope.trailerWeight = function() {
    var start = ($scope.horseSlider.value) * 970 + 1300;
    var options = 0;
    
    if($scope.toggles.livingQuarter){
      options += 1100;
    }
    if($scope.toggles.dressingRoom){
      options += 400;
    }
    var total = start + options;
    if($scope.toggles.aluminum){
      total = total * .90;
    }
    return total;
  };
  $scope.passengerWeight = function() {
    return ($scope.passengerSlider.value * 150) + 250;
  };

  $scope.truckWeight = function(){
    var w = 0;
    var total = $scope.getTotal();
    if(total > 0 && total < 5000){
      w = 4000;
    } else if(total > 5000 && total < 7000) {
      w = 5000;
    } else if(total >  7000 && total < 16000) {
      w = 6000;
    } else if(total > 16000 && total < 25500) {
      w = 6300;
    } else if(total > 25500) {
      w = 8500;
    }
    return w;
  }
  $scope.hitchText = function(){
    if($scope.horseSlider.value > 3 || ($scope.horseSlider.value > 2 && $scope.toggles.livingQuarter)) {
      return "Gooseneck";
    } else {
      return "Bumper Pull";
    }
  }

  $scope.getTotal = function(){
    var horseWeight = parseInt($scope.horseWeight);
    var trailerWeight = parseInt($scope.trailerWeight);
    var passengerWeight = $scope.passengerWeight();
    

    var total = horseWeight + trailerWeight + (passengerWeight * 2);

    return total;
  }
  $scope.superTotal = function(){
    return $scope.getTotal() + $scope.truckWeight();
  }

  $scope.resetStuff = function(){
    $scope.horseSlider.value = 1;
    $scope.passengerSlider.value = 1;
    $scope.toggles = {
      aluminum: true,
      dressingRoom: false,
      livingQuarter: false
    };
  }
}])

