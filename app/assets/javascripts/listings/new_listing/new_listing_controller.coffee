app = angular.module("TackHunter")

app.controller("newListingCtrl", ["$scope", "$http", "Upload", "Listing", "Category", "CategoryApi", "Discipline", "Brand", ($scope, $http, Upload, Listing, Category, CategoryApi, Discipline, Brand) ->
  $scope.listing_resource = new Listing();
  $scope.listingForms = {
    categoryForm: {},
    infoForm: {}
    detailsForm: {}
    pictureForm: {}
  }
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

  $scope.disableStep = (step) ->
    unless $scope.eligibleForNextStep and $scope.selectedstep < step
      return false
    else
      return true

  $scope.brandSearchTextChange = (searchText) ->
    return Brand.query({q: searchText}).$promise;

  $scope.fetchCategories = () ->
    if $scope.listing_resource.listing.discipline_id
      $http.get("/" + $scope.listing_resource.listing.discipline_id + "/categories").success (data) ->
        $scope.categories = data
  
  $scope.fetchSubcategories = () ->
    $scope.subcategories = [] 
    if $scope.listing_resource.listing.discipline_id
      CategoryApi.subcategories {id: $scope.listing_resource.listing.category_id}, (data) ->
        $scope.subcategories = data  
  
  $scope.fetchCustomFields = () ->
    if $scope.listing_resource.listing.category_id
      $http.get("/api/categories/" + $scope.listing_resource.listing.category_id + "/custom_fields").success (data) ->
        $scope.custom_fields = data
  
  $scope.nextStep = () ->
    if $scope.eligibleForNextStep
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

  $scope.eligibleForNextStep = () ->
    switch $scope.selectedStep
      when 0 then $scope.listingForms.infoForm.$valid
      when 1 then $scope.listingForms.infoForm.$valid && $scope.listingForms.categoryForm.$valid
      when 2 then $scope.listingForms.infoForm.$valid && $scope.listingForms.categoryForm.$valid && $scope.listingForms.detailsForm.$valid


  $scope.conditions = ["New", "Excellent", "Good", "Fair", "Poor/Non-Functioning"]
])