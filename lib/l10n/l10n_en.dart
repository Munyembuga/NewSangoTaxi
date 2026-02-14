// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SEn extends S {
  SEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Sango Taxi';

  @override
  String get fastReliable => 'Fast & Reliable Rides';

  @override
  String get getToDestination => 'Get to your destination on time, every time';

  @override
  String get safeSecure => 'Safe & Secure';

  @override
  String get safetyPriority => 'Your safety is our top priority';

  @override
  String get affordablePrices => 'Affordable Prices';

  @override
  String get premiumService => 'Enjoy premium service at competitive rates';

  @override
  String get bookingTypes => 'Booking Types';

  @override
  String get failedToLoad => 'Failed to load booking types';

  @override
  String get retry => 'Retry';

  @override
  String get loginRequired => 'Login Required';

  @override
  String get loginMessage =>
      'You need to create an account or log in to book a ride.';

  @override
  String get cancel => 'Cancel';

  @override
  String get login => 'Log In';

  @override
  String get guestMode => 'Guest Mode';

  @override
  String get myLocation => 'My Location';

  @override
  String get yourLocation => 'Your location';

  @override
  String get currentLocation => 'Your current location';

  @override
  String get useDeviceLocation => 'Use your device\'s location';

  @override
  String get bookYourRide => 'Book Your Ride';

  @override
  String get whereTo => 'Where to?';

  @override
  String get letsGetYouToDestination => 'Let\'s get you to your destination';

  @override
  String get selectCategory => 'Select Category';

  @override
  String get pickupLocation => 'Pickup Location';

  @override
  String get gettingCurrentLocation => 'Getting current location...';

  @override
  String get errorGettingLocation => 'Error getting location';

  @override
  String get destination => 'Destination';

  @override
  String get whereAreYouGoing => 'Where are you going?';

  @override
  String get calculatingDistanceAndFare => 'Calculating distance and fare...';

  @override
  String distance(Object distance) {
    return 'Distance: $distance';
  }

  @override
  String get duration => 'Duration';

  @override
  String get startDate => 'Start';

  @override
  String get endDate => 'End';

  @override
  String estimatedFare(Object fare) {
    return 'Estimated Fare: $fare FCFA';
  }

  @override
  String get confirmBooking => 'Confirm Booking';

  @override
  String confirmBookingWithFare(Object fare) {
    return 'Confirm Booking - $fare FCFA';
  }

  @override
  String get completeYourBooking => 'Complete Your Booking';

  @override
  String get provideContactInfo =>
      'Please provide your contact information to complete the booking:';

  @override
  String get yourName => 'Your Name';

  @override
  String get enterYourFullName => 'Enter your full name';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get phoneHint => '+243 y xxx xx xx ';

  @override
  String get privacyInfo =>
      'Your information will only be used for this booking.';

  @override
  String get fillAllFields => 'Please fill in all fields';

  @override
  String bookingConfirmed(Object category, Object fare) {
    return 'Booking confirmed! $category - $fare FCFA';
  }

  @override
  String get bookingRequestSent =>
      'Booking request sent! You will be contacted shortly.';

  @override
  String bookingFailed(Object message) {
    return 'Booking failed: $message';
  }

  @override
  String errorBooking(Object error) {
    return 'Error creating booking: $error';
  }

  @override
  String get searchCategories => 'Search categories...';

  @override
  String get selectACategory => 'Select a category';

  @override
  String get rentCar => 'Rent a Car';

  @override
  String get rentCarWithDriver => 'Rent a Car with Driver';

  @override
  String get rentalOptions => 'Select your preferred rental options';

  @override
  String get vehicleCategories => 'Vehicle Categories';

  @override
  String get rentalDurationType => 'Rental Duration Type';

  @override
  String get daily => 'Daily';

  @override
  String get weekly => 'Weekly';

  @override
  String get monthly => 'Monthly';

  @override
  String get numberOfUnits => 'Number of Day(s)';

  @override
  String get pickupDate => 'Pickup Date';

  @override
  String get returnDate => 'Return Date';

  @override
  String durationType(Object type) {
    return 'Duration Type: $type';
  }

  @override
  String totalDuration(Object duration, Object unit) {
    return 'Total Duration: $duration $unit';
  }

  @override
  String ratePerDuration(Object price, Object unit) {
    return 'Rate: $price FCFA per $unit';
  }

  @override
  String totalPrice(Object price) {
    return 'Total: $price FCFA';
  }

  @override
  String get priceIncludesDriver => 'Price includes driver';

  @override
  String get confirmRental => 'Confirm Rental';

  @override
  String confirmRentalWithPrice(Object price) {
    return 'Confirm Rental: $price FCFA';
  }

  @override
  String get completeYourRental => 'Complete Your Rental';

  @override
  String get provideRentalContactInfo =>
      'Please provide your contact information to complete the rental:';

  @override
  String get selectVehicle => 'Select Vehicle';

  @override
  String get days => 'days';

  @override
  String get weeks => 'weeks';

  @override
  String get months => 'months';

  @override
  String get loadingRentalOptions => 'Loading rental options...';

  @override
  String get ride => 'Ride';

  @override
  String get details => 'Details';

  @override
  String get driver => 'Driver';

  @override
  String get vehicle => 'Vehicle';

  @override
  String get from => 'From';

  @override
  String get to => 'To';

  @override
  String get date => 'Date';

  @override
  String get time => 'Time';

  @override
  String get fare => 'Fare';

  @override
  String get track => 'Track';

  @override
  String get cancelRide => 'Cancel Ride';

  @override
  String get callDriver => 'Call Driver';

  @override
  String get rideCancelled => 'Ride cancelled';

  @override
  String get phoneNumberNotAvailable => 'Phone number not available';

  @override
  String get completed => 'Completed';

  @override
  String get pending => 'Pending';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get unknown => 'unknown';

  @override
  String get rideHistory => 'Ride History';

  @override
  String get confirmed => 'Confirmed';

  @override
  String get onTrip => 'On Trip';

  @override
  String get startTrip => 'Start Trip';

  @override
  String get enterOtpMessage =>
      'Please ask the client for the OTP code to start the trip.';

  @override
  String get enterOTP => 'Enter OTP';

  @override
  String get sixDigitCode => '6-digit code';

  @override
  String get navigation => 'Navigation';

  @override
  String get locationCoordsNotAvailable =>
      'Location coordinates not available for navigation';

  @override
  String get pause => 'Pause';

  @override
  String get startNavigation => 'Start Navigation';

  @override
  String get googleMaps => 'Google Maps';

  @override
  String get unknownPickup => 'Unknown pickup';

  @override
  String get unknownDestination => 'Unknown destination';

  @override
  String get navigate => 'Navigate';

  @override
  String get start => 'Start';

  @override
  String get inProgress => 'In Progress';

  @override
  String get complete => 'Complete';

  @override
  String tripWithId(Object id) {
    return 'Trip $id';
  }

  @override
  String get navigateToPickup => 'Navigate to Pickup';

  @override
  String startedAt(Object time) {
    return 'Started: $time';
  }

  @override
  String completedAt(Object time) {
    return 'Completed: $time';
  }

  @override
  String get bookingCode => 'Booking';

  @override
  String get initialPayment => 'Initial Payment';

  @override
  String get totalEstimated => 'Total Estimated';

  @override
  String get cancelBooking => 'Cancel Booking';

  @override
  String get checkYourCarRentals => 'Check Your Car Rentals';

  @override
  String get enterPhoneForRentals =>
      'Enter the phone number you used when making the rental booking';

  @override
  String get checkYourConfirmedRentals => 'Check Your Confirmed Rentals';

  @override
  String get contactUs => 'Contact Us';

  @override
  String get checkYourBookings => 'Check Your Bookings';

  @override
  String get enterPhoneForBooking =>
      'Enter the phone number you used when making the booking';

  @override
  String get checkBookings => 'Check Bookings';

  @override
  String get noPendingRides => 'No Pending Rides';

  @override
  String get pendingRidesWillAppearHere =>
      'Your pending rides will appear here';

  @override
  String get checkYourActiveTrips => 'Check Your Active Trips';

  @override
  String get checkActiveTrips => 'Check Active Trips';

  @override
  String get noActiveTrips => 'No Active Trips';

  @override
  String get activeTripsWillAppearHere => 'Your ongoing trips will appear here';

  @override
  String get checkYourCompletedTrips => 'Check Your Completed Trips';

  @override
  String get checkCompletedTrips => 'Check Completed Trips';

  @override
  String get noCompletedRides => 'No Completed Rides';

  @override
  String get completedRidesWillAppearHere =>
      'Your completed rides will appear here';

  @override
  String get noCancelledRides => 'No Cancelled Rides';

  @override
  String get cancelledRidesWillAppearHere =>
      'Your cancelled rides will appear here';

  @override
  String get confirm => 'Confirm';

  @override
  String statusWithValue(Object status) {
    return 'Status: $status';
  }

  @override
  String totalWithValue(Object value) {
    return 'Total: $value';
  }

  @override
  String get provideCancellationReason =>
      'Please provide a reason for cancellation:';

  @override
  String get enterReason => 'Enter reason...';

  @override
  String get pleaseProvideReason => 'Please provide a reason';

  @override
  String get submit => 'Submit';

  @override
  String get noConfirmedRides => 'No Confirmed Rides';

  @override
  String get confirmedRidesWillAppearHere =>
      'Your confirmed rides will appear here';

  @override
  String get unknownClient => 'Unknown Client';

  @override
  String get calculatingRoute => 'Calculating best route...';

  @override
  String get arrivedAtDestination => 'You have arrived at your destination';

  @override
  String get signIn => 'Sign In';

  @override
  String get emailAddress => 'Email Address';

  @override
  String get enterEmail => 'Please enter your email';

  @override
  String get enterValidEmail => 'Please enter a valid email';

  @override
  String get enterPassword => 'Please enter your password';

  @override
  String get password => 'Password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get showPassword => 'Show password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get continueWithoutLogin => 'Continue without login';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get createAccount => 'Create Account';

  @override
  String get needHelp => 'Need Help?';

  @override
  String get callCenter => 'Call Center';

  @override
  String get resetTokenSent => 'Reset token sent to your email';

  @override
  String get failedToSendToken => 'Failed to send reset token';

  @override
  String get error => 'Error';

  @override
  String get tokenVerified => 'Reset token verified successfully';

  @override
  String get invalidToken => 'Invalid reset token';

  @override
  String get passwordResetSuccess => 'Password reset successfully';

  @override
  String get passwordResetFailed => 'Failed to reset password';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get verifyOTP => 'Verify OTP';

  @override
  String get newPassword => 'New Password';

  @override
  String get enterEmailForReset =>
      'Enter your email address to receive a reset token';

  @override
  String enterTokenSentTo(Object email) {
    return 'Enter the reset token sent to $email';
  }

  @override
  String get createNewPassword => 'Create your new password';

  @override
  String get sendResetToken => 'Send Reset Token';

  @override
  String get enterResetToken => 'Enter Reset Token';

  @override
  String get tokenMinLength => 'Reset token must be at least 4 digits';

  @override
  String get resendResetToken => 'Resend Reset Token';

  @override
  String get verifyResetToken => 'Verify Reset Token';

  @override
  String get enterNewPassword => 'Please enter new password';

  @override
  String get passwordMinLength => 'Password must be at least 6 characters';

  @override
  String get confirmNewPassword => 'Confirm New Password';

  @override
  String get confirmPassword => 'Please confirm your password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get registrationSuccessful => 'Registration successful';

  @override
  String get createNewAccount => 'Create new account';

  @override
  String get completeYourProfile => 'Complete Your Profile';

  @override
  String get provideDetailsForAccount =>
      'Please provide your details to create your account';

  @override
  String get firstName => 'First Name';

  @override
  String get enterFirstName => 'Please enter your first name';

  @override
  String get lastName => 'Last Name';

  @override
  String get enterLastName => 'Please enter your last name';

  @override
  String get enterPhoneNumber => 'Please enter your phone number';

  @override
  String get enterValidPhoneNumber => 'Please enter a valid phone number';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get home => 'Home';

  @override
  String get profile => 'Profile';

  @override
  String get carRentals => 'Car Rentals';

  @override
  String get rent => 'Rent';

  @override
  String get driverProfile => 'Driver Profile';

  @override
  String get yourProfile => 'Your Profile';

  @override
  String get totalRides => 'Total Rides';

  @override
  String get thisMonth => 'This Month';

  @override
  String get rating => 'Rating';

  @override
  String get securityPrivacy => 'Security & Privacy';

  @override
  String get enableDriverCalls => 'Enable Driver Calls';

  @override
  String get allowDriversToCall => 'Allow drivers to call you during rides';

  @override
  String get shareLiveLocation => 'Share Live Location';

  @override
  String get shareLocationEmergency =>
      'Share your location with emergency contacts';

  @override
  String get personalInformation => 'Personal Information';

  @override
  String get paymentMethods => 'Payment Methods';

  @override
  String get favoriteDestinations => 'Favorite Destinations';

  @override
  String get notifications => 'Notifications';

  @override
  String get language => 'Language';

  @override
  String get helpSupport => 'Help & Support';

  @override
  String get logout => 'Logout';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get english => 'English';

  @override
  String get french => 'Français';

  @override
  String get areYouSureLogout =>
      'Are you sure you want to logout from your account?';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get wallet => 'Wallet';

  @override
  String get available => 'Available';

  @override
  String get offline => 'Offline';

  @override
  String get driverAvailability => 'Driver Availability';

  @override
  String get toggleAvailabilityDescription =>
      'Toggle your availability for accepting rides (Available/Offline)';

  @override
  String get allowPassengersToCall =>
      'Allow passengers to call you during rides';

  @override
  String get shareLocationWithApp => 'Share your location with the app';

  @override
  String get companyDetails => 'Company Details';

  @override
  String get addNewDestination => 'Add New Destination';

  @override
  String get destinationName => 'Destination Name';

  @override
  String get destinationNameHint => 'e.g., Coffee Shop, Friend\'s House';

  @override
  String get address => 'Address';

  @override
  String get enterAddressHint => 'Enter the full address';

  @override
  String get add => 'Add';

  @override
  String get demoNotice =>
      'Note: This is a demo. New destinations will appear after actual rides.';

  @override
  String get editDestination => 'Edit Destination';

  @override
  String get update => 'Update';

  @override
  String destinationUpdated(Object name) {
    return '$name updated successfully';
  }

  @override
  String get deleteDestination => 'Delete Destination';

  @override
  String confirmDeleteDestination(Object name) {
    return 'Are you sure you want to remove \"$name\" from your favorites?';
  }

  @override
  String get delete => 'Delete';

  @override
  String destinationRemoved(Object name) {
    return '$name removed from favorites';
  }

  @override
  String get failedToLoadDestinations => 'Failed to Load Destinations';

  @override
  String get noFavoriteDestinationsYet => 'No Favorite Destinations Yet';

  @override
  String get noFavoriteDestinations => 'No Favorite Destinations';

  @override
  String get favoritesWillAppearAsYouUse =>
      'Your frequently visited locations will appear here as you use the app';

  @override
  String get addPlacesYouVisit =>
      'Add places you visit frequently to save time on future bookings';

  @override
  String get refresh => 'Refresh';

  @override
  String get frequentlyUsedLocations =>
      'These are your most frequently used locations. Tap to use as destination.';

  @override
  String get pickupLocations => 'Pickup Locations';

  @override
  String get dropoffLocations => 'Drop-off Locations';

  @override
  String usedTimes(Object count, Object s) {
    return 'Used $count time$s';
  }

  @override
  String usingDestination(Object name) {
    return 'Using \"$name\" as destination...';
  }

  @override
  String get pickup => 'Pickup';

  @override
  String get dropoff => 'Dropoff';

  @override
  String get pendingRentals => 'Pending Rentals';

  @override
  String get noRentalsFound => 'No rentals found';

  @override
  String get yourPendingRentalsWillAppear =>
      'Your pending rentals will appear here';

  @override
  String get loadingRentals => 'Loading rentals...';

  @override
  String get errorLoadingRentals => 'Error loading rentals';

  @override
  String get rentalPeriod => 'Rental Period';

  @override
  String get priceEstimated => 'Price Estimated';

  @override
  String get makePayment => 'Make Payment';

  @override
  String get paymentOptions => 'Payment Options';

  @override
  String get selectPaymentMethod => 'Select Payment Method';

  @override
  String get paymentAmount => 'Payment Amount';

  @override
  String get customAmount => 'Custom Amount';

  @override
  String get enterAmount => 'Enter amount';

  @override
  String get processPayment => 'Process Payment';

  @override
  String get paymentProcessing => 'Processing Payment';

  @override
  String get pleaseWait => 'Please wait...';

  @override
  String get paymentSuccessful =>
      'Payment successful! Your booking has been updated.';

  @override
  String paymentFailed(String message) {
    return 'Payment failed: $message';
  }

  @override
  String paymentError(String error) {
    return 'Error processing payment: $error';
  }

  @override
  String get pleaseSelectPaymentMethod =>
      'Please select a payment method and enter amount';

  @override
  String get fcfaCurrency => 'FCFA';

  @override
  String get choosePaymentMethod => 'Choose Payment Method';

  @override
  String totalAmount(String amount) {
    return 'Total amount: $amount FCFA';
  }

  @override
  String enterInitialAmount(String minAmount, String maxAmount) {
    return 'Enter initial amount to pay: $minAmount FCFA - $maxAmount FCFA';
  }

  @override
  String get amountInFcfa => 'Amount in FCFA';

  @override
  String rentalInfo(String categoryName, String duration, String unit) {
    return 'Rental: $categoryName - $duration $unit';
  }

  @override
  String get loadingPaymentMethods => 'Loading payment methods...';

  @override
  String get noPaymentMethods => 'No payment methods available';

  @override
  String get selectedPayment => 'Selected Payment';

  @override
  String payWithMethod(String method) {
    return 'Pay with $method';
  }

  @override
  String get confirmPaymentMethod => 'Confirm Payment Method';

  @override
  String get pleaseEnterValidAmount => 'Please enter a valid payment amount';

  @override
  String get carRental => 'Car Rental';

  @override
  String get standardRental => 'Standard Rental';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get noConfirmedRentalsFound => 'No confirmed rentals found';

  @override
  String get confirmedRentalsWillAppearHere =>
      'Your confirmed car rentals will appear here';

  @override
  String get totalInitialPayment => 'Total Initial Payment';

  @override
  String get rentals => 'rentals';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get email => 'Email';

  @override
  String get save => 'Save';

  @override
  String get myOrders => 'My Orders';

  @override
  String get processing => 'Processing';

  @override
  String get noCompletedOrders => 'No completed orders yet';

  @override
  String get noCancelledOrders => 'No cancelled orders';

  @override
  String get noOrdersInProgress => 'No orders in progress';

  @override
  String orderWithId(Object id) {
    return 'Order #$id';
  }

  @override
  String get total => 'Total';

  @override
  String get viewDetails => 'View Details';

  @override
  String get pleaseLoginToViewOrders => 'Please login to view orders';

  @override
  String get pleaseLoginToViewOrderDetails =>
      'Please login to view order details';

  @override
  String get failedToLoadOrders => 'Failed to load orders';

  @override
  String get failedToLoadOrderDetails => 'Failed to load order details';

  @override
  String errorLoadingOrders(Object error) {
    return 'Error loading orders: $error';
  }

  @override
  String errorLoadingOrderDetails(Object error) {
    return 'Error loading order details: $error';
  }

  @override
  String get orderInformation => 'Order Information';

  @override
  String get orderDate => 'Order Date';

  @override
  String get paymentMethod => 'Payment Method';

  @override
  String get notes => 'Notes';

  @override
  String get deliveryInformation => 'Delivery Information';

  @override
  String get customerName => 'Customer Name';

  @override
  String get phone => 'Phone';

  @override
  String get orderItems => 'Order Items';

  @override
  String get orderSummary => 'Order Summary';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get deliveryFee => 'Delivery Fee';

  @override
  String get delivery => 'Delivery';

  @override
  String get categories => 'Categories';

  @override
  String get selectCategoryToViewProducts =>
      'Select a category to view products';

  @override
  String get noProductsAvailable => 'No products available';

  @override
  String get pleaseLoginToAddToCart => 'Please login to add items to cart';

  @override
  String productAddedToCart(Object productName) {
    return '$productName added to cart';
  }

  @override
  String get failedToAddToCart => 'Failed to add to cart';

  @override
  String errorAddingToCart(Object error) {
    return 'Error adding to cart: $error';
  }

  @override
  String failedToLoadCategories(Object error) {
    return 'Failed to load categories: $error';
  }

  @override
  String failedToLoadProducts(Object error) {
    return 'Failed to load products: $error';
  }

  @override
  String get checkout => 'Checkout';

  @override
  String get deliveryAddress => 'Delivery Address';

  @override
  String get enterDeliveryAddress => 'Enter delivery address';

  @override
  String get deliveryNotesOptional => 'Delivery Notes (Optional)';

  @override
  String get deliveryInstructionsHint =>
      'Add any special instructions for delivery...';

  @override
  String get placeOrder => 'Place Order';

  @override
  String get pleaseEnterDeliveryAddress => 'Please enter a delivery address';

  @override
  String get pleaseSelectValidAddress =>
      'Please select a valid address from suggestions';

  @override
  String get pleaseLoginToPlaceOrder => 'Please login to place order';

  @override
  String get orderPlaced => 'Order Placed';

  @override
  String get orderPlacedSuccessfully =>
      'Your order has been placed successfully!';

  @override
  String notesWithValue(Object value) {
    return 'Notes: $value';
  }

  @override
  String get ok => 'OK';

  @override
  String get failedToPlaceOrder => 'Failed to place order';

  @override
  String errorPlacingOrder(Object error) {
    return 'Error placing order: $error';
  }

  @override
  String get shoppingCart => 'Shopping Cart';

  @override
  String get cartEmpty => 'Your cart is empty';

  @override
  String get pleaseLoginToUpdateCart => 'Please login to update cart';

  @override
  String get invalidCartItem => 'Invalid cart item';

  @override
  String get failedToUpdateCart => 'Failed to update cart';

  @override
  String errorUpdatingCart(Object error) {
    return 'Error updating cart: $error';
  }

  @override
  String get failedToRemoveItem => 'Failed to remove item';

  @override
  String errorRemovingItem(Object error) {
    return 'Error removing item: $error';
  }
}
