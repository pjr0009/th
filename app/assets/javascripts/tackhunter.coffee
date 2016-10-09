'use strict'
app = angular.module('TackHunter', [
  'ngMaterial'
  'ngResource'
]).config(["$mdThemingProvider", ($mdThemingProvider) ->
  $mdThemingProvider.definePalette 'tackhunterPalette',
    '50': 'fff'
    '100': 'fff'
    '200': 'fff'
    '300': 'B09E99'
    '400': 'BAC1B8'
    '500': '064f2f'
    '600': 'fff'
    '700': 'fff'
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
