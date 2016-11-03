'use strict'
app = angular.module('TackHunter', [
  'ngMaterial'
  'ngMessages'
  'ngResource'
  'ngFileUpload'
  'ngImgCrop'
  'rzModule'
  'toggle-switch'
  'md-steppers'
]).config(["$mdThemingProvider", ($mdThemingProvider) ->
  $mdThemingProvider.definePalette 'tackhunterPalette',
    '50': 'fff'
    '100': 'fff'
    '200': 'fff'
    '300': 'B09E99'
    '400': 'BAC1B8'
    '500': '064f2f'
    '600': 'BAC1B8'
    '700': 'BAC1B8'
    '800': 'fff'
    '900': 'b71c1c'
    'A100': 'BAC1B8'
    'A200': 'BAC1B8'
    'A400': 'BAC1B8'
    'A700': 'BAC1B8'
    'contrastDefaultColor': 'light'
    'contrastDarkColors': [
      '50'
      '100'
      '200'
      '300'
      '400'
      'A100'
    ]
    'contrastLightColors': undefined
  $mdThemingProvider.theme('default').primaryPalette 'tackhunterPalette'
]).controller("TackHunterCtrl", ["$mdSidenav", "$scope", ($mdSidenav, $scope) ->
  $scope.toggleLeftNav = () ->
    $mdSidenav('left').toggle();
])

app.factory('Listing', ["$resource", ($resource) ->
  return $resource('/listings/:id')
])
app.factory('Category', ["$resource", ($resource) ->
  return $resource('/categories/:id', null, {
    subcategories: {
      url: "/api/categories/:id/subcategories"
      method: 'GET',
      isArray: true
    }
  })
])

app.factory('CategoryApi', ["$resource", ($resource) ->
  return $resource('/api/categories/:id', null, {
    subcategories: {
      url: "/api/categories/:id/subcategories"
      method: 'GET',
      isArray: true
    }
  })
])
app.factory('Discipline', ["$resource", ($resource) ->
  return $resource('/disciplines/:id')
])

app.factory('Brand', ["$resource", ($resource) -> 
  return $resource('/brands/:id'); 
]);

app.factory('Product', ["$resource", ($resource) -> 
  return $resource('/products/:id'); 
]);
app.factory('Sale', ["$resource", ($resource) -> 
  return $resource('/api/sales/:id', null, {
    query: {
      method: 'GET',
      isArray: false
    }
  });
]);

