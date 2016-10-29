app = angular.module("TackHunter")

app.factory('Listing', ["$resource", ($resource) ->
  return $resource('/listings/:id')
])
app.factory('Category', ["$resource", ($resource) ->
  return $resource('/categories/:id')
])
app.factory('Discipline', ["$resource", ($resource) ->
  return $resource('/disciplines/:id')
])
app.controller("newListingCtrl", ["$scope", "$http", "Upload", "Listing", "Category", "Discipline", ($scope, $http, Upload, Listing, Category, Discipline) ->
  $scope.listing_resource = new Listing();
  $scope.listing_resource.listing = {
    listing_image_ids: []
  };
  $scope.croppedStagingUrl = ""
  $scope.selectedStep = 0
  $scope.listing_images = []
  $scope.step = [
    {complete: true}
  ]
  $scope.disciplines = Discipline.query()

  $scope.fetchCategories = () ->
    if $scope.listing_resource.listing.discipline_id
      $http.get("/" + $scope.listing_resource.listing.discipline_id + "/categories").success (data) ->
        $scope.categories = data
  
  $scope.fetchCustomFields = () ->
    if $scope.listing_resource.listing.category_id
      $http.get("/api/categories/" + $scope.listing_resource.listing.category_id + "/custom_fields").success (data) ->
        $scope.custom_fields = data
  
  $scope.nextStep = () ->
    $scope.selectedStep += 1 if $scope.selectedStep < 4

  $scope.confirmStagingPic = () ->
    $scope.listing_images.unshift($scope.croppedStagingUrl)
    Upload.upload(
      url: '/listing_images/add_from_file'
      data:
        listing_image: {image: Upload.dataUrltoBlob($scope.croppedStagingUrl, $scope.stagingPic.name)}).then ((resp) ->
      $scope.listing_resource.listing.listing_image_ids.push(resp.data.id)
      return
    ), ((resp) ->
      console.log 'Error status: ' + resp.status
      return
    ), (evt) ->
      console.log('progress')
      return


     
    delete $scope.stagingPic
    $scope.croppedStagingUrl = ""

  $scope.destroyStagingPic = () ->
    delete $scope.stagingPic
    $scope.croppedStagingUrl = ""

  $scope.removeFromListingImages = (index) ->
    $scope.listing_images.splice(index, 1)

  $scope.sortListingImage = (index, direction) ->
    candidate = index+direction
    if candidate < ($scope.listing_images.length) and candidate >= 0
      tmp = $scope.listing_images[candidate]
      $scope.listing_images[candidate] = $scope.listing_images[index]
      $scope.listing_images[index] = tmp
  
  $scope.submitListing = () ->
    if $scope.listingIsValid()
      $scope.listing_resource.$save();
  $scope.listingIsValid = () ->
    return \
      $scope.listing_resource.listing.listing_image_ids \
      && $scope.listing_resource.listing.listing_image_ids.length > 0




  $scope.conditions = ["New", "Excellent", "Good", "Fair", "Poor/Non-Functioning"]
])