// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get account => 'Account';

  @override
  String get accountStatusFree => 'Free User';

  @override
  String get accountStatusPremium => 'Premium Member';

  @override
  String get adPlaceholder => 'Ad Placeholder\n300 x 250';

  @override
  String get add => 'Add';

  @override
  String get added => 'ADDED';

  @override
  String get addedToActiveList => 'Added to active list';

  @override
  String addedTo(String listName) {
    return 'Added to \"$listName\"';
  }

  @override
  String get addToList => 'Add to list';

  @override
  String get anUnknownErrorOccurred => 'An unknown error occurred';

  @override
  String get anUnexpectedErrorOccurred => 'An unexpected error occurred.';

  @override
  String get appName => 'SaleSeekr';

  @override
  String get apply => 'APPLY';

  @override
  String get cancel => 'Cancel';

  @override
  String get categories => 'Categories';

  @override
  String get categoryBeverages => 'Beverages';

  @override
  String get categoryCoffeeTeaCocoa => 'Coffee, Tea & Cocoa';

  @override
  String get categorySoftDrinksEnergyDrinks => 'Soft Drinks & Energy Drinks';

  @override
  String get categoryWaterJuices => 'Water & Juices';

  @override
  String get categoryAlcoholicBeverages => 'Alcoholic Beverages';

  @override
  String get categoryBeer => 'Beer';

  @override
  String get categorySpiritsAssorted => 'Spirits & Assorted';

  @override
  String get categoryWinesSparklingWines => 'Wines & Sparkling Wines';

  @override
  String get categoryBreadBakery => 'Bread & Bakery';

  @override
  String get categoryBakingIngredients => 'Baking Ingredients';

  @override
  String get categoryBread => 'Bread';

  @override
  String get categoryPastriesDesserts => 'Pastries & Desserts';

  @override
  String get categoryFishMeat => 'Fish & Meat';

  @override
  String get categoryMeatMixesAssorted => 'Meat Mixes & Assorted';

  @override
  String get categoryFishSeafood => 'Fish & Seafood';

  @override
  String get categoryPoultry => 'Poultry';

  @override
  String get categoryBeefVeal => 'Beef & Veal';

  @override
  String get categoryPork => 'Pork';

  @override
  String get categorySausagesColdCuts => 'Sausages & Cold Cuts';

  @override
  String get categoryFruitsVegetables => 'Fruits & Vegetables';

  @override
  String get categoryFruits => 'Fruits';

  @override
  String get categoryVegetables => 'Vegetables';

  @override
  String get categoryDairyEggs => 'Dairy & Eggs';

  @override
  String get categoryButterEggs => 'Butter & Eggs';

  @override
  String get categoryCheese => 'Cheese';

  @override
  String get categoryMilkDairyProducts => 'Milk & Dairy Products';

  @override
  String get categorySaltySnacksSweets => 'Salty Snacks & Sweets';

  @override
  String get categorySnacksAppetizers => 'Snacks & Appetizers';

  @override
  String get categoryChipsNuts => 'Chips & Nuts';

  @override
  String get categoryIceCreamSweets => 'Ice Cream & Sweets';

  @override
  String get categoryChocolateCookies => 'Chocolate & Cookies';

  @override
  String get categorySpecialDiet => 'Special Diet';

  @override
  String get categoryConvenienceReadyMeals => 'Convenience & Ready Meals';

  @override
  String get categoryVeganProducts => 'Vegan Products';

  @override
  String get categoryPantry => 'Pantry';

  @override
  String get categoryCerealsGrains => 'Cereals & Grains';

  @override
  String get categoryCannedGoodsOilsSaucesSpices =>
      'Cans, Oils, Sauces & Spices';

  @override
  String get categoryHoneyJamSpreads => 'Honey, Jam & Spreads';

  @override
  String get categoryRicePasta => 'Rice & Pasta';

  @override
  String get categoryFrozenProductsSoups => 'Frozen Products & Soups';

  @override
  String get categoryCustom => 'Custom Items';

  @override
  String get categoryOther => 'Other';

  @override
  String get categoryUncategorized => 'Uncategorized';

  @override
  String get changePassword => 'Change Password';

  @override
  String get checkItem => 'Check item';

  @override
  String get remove => 'Remove';

  @override
  String get close => 'CLOSE';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get couldNotOpenProductLink => 'Could not open product link';

  @override
  String get createAccount => 'Create Account';

  @override
  String get createAndAddItem => 'CREATE & ADD ITEM';

  @override
  String get createAndSelect => 'CREATE AND SELECT';

  @override
  String createdAndSelectedList(String listName) {
    return 'Created and selected list \"$listName\"';
  }

  @override
  String get createCustomItem => 'Create Custom Item';

  @override
  String createCustomListsWithPremium(int count) {
    return 'Create up to $count custom lists with Premium.';
  }

  @override
  String get createItem => 'CREATE ITEM';

  @override
  String get createNew => 'Create New';

  @override
  String get currencyFrancs => 'Fr.';

  @override
  String get currentPassword => 'Current Password';

  @override
  String get customCategoryPremium => 'Custom Category (Premium)';

  @override
  String customItemLimitReached(int count) {
    return 'You have reached your limit of $count custom items.';
  }

  @override
  String get customItems => 'Custom Items';

  @override
  String get customItemsEmpty => 'You haven\'t created any custom items yet.';

  @override
  String get dangerZone => 'Danger Zone';

  @override
  String get decreaseQuantity => 'Decrease quantity';

  @override
  String get defaultListName => 'Merkliste';

  @override
  String get defaultListIsBeingPrepared =>
      'Your default list is being prepared...';

  @override
  String get delete => 'Delete';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get deleteAccountConfirmationBody =>
      'This action is permanent and cannot be undone. All your lists and data will be lost. Please enter your password to confirm.';

  @override
  String get deleteItemConfirmationBody =>
      'This will permanently remove the item from your library.';

  @override
  String deleteItemConfirmationTitle(String itemName) {
    return 'Delete \"$itemName\"?';
  }

  @override
  String get deleteListConfirmationBody =>
      'This action is permanent and cannot be undone.';

  @override
  String deleteListConfirmationTitle(String listName) {
    return 'Delete \"$listName\"?';
  }

  @override
  String get deletePermanently => 'DELETE PERMANENTLY';

  @override
  String get displayName => 'Display Name';

  @override
  String get editCustomItem => 'Edit Custom Item';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get emailAddress => 'Email Address';

  @override
  String get enterNewListName => 'Enter new list name';

  @override
  String error(String error) {
    return 'Error: $error';
  }

  @override
  String get errorCouldNotLoadData => 'Error: Could not load data.';

  @override
  String errorLoadingList(String error) {
    return 'Error loading list: $error';
  }

  @override
  String get errorLoadingProfile => 'Error loading profile';

  @override
  String errorSavingItem(String error) {
    return 'Error saving item: $error';
  }

  @override
  String get failedToSendResetEmail => 'Failed to send reset email.';

  @override
  String fatalError(String error) {
    return 'Fatal Error: $error';
  }

  @override
  String featureNotImplemented(String featureName) {
    return '$featureName is not yet implemented.';
  }

  @override
  String get filter => 'Filter';

  @override
  String get filterByStore => 'Filter by Store';

  @override
  String get filterProducts => 'Filter Products';

  @override
  String get finish => 'Finish';

  @override
  String get finishShoppingBody =>
      'Do you want to remove the checked items from your list or keep everything?';

  @override
  String get finishShoppingTitle => 'Finish Shopping?';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get hideCheckedItems => 'Hide checked items';

  @override
  String get increaseQuantity => 'Increase quantity';

  @override
  String get initializing => 'Initializing...';

  @override
  String itemAddedToList(String itemName) {
    return '\"$itemName\" added to list.';
  }

  @override
  String itemDeleted(String itemName) {
    return '\"$itemName\" deleted.';
  }

  @override
  String itemLimitReachedBody(int currentItems, int limit) {
    return 'Your list contains $currentItems items, but the maximum is $limit. Please remove some items to continue.';
  }

  @override
  String get itemLimitReachedTitle => 'Item Limit Reached';

  @override
  String get itemsLabel => 'Items';

  @override
  String itemSavedSuccessfully(String itemName) {
    return '\"$itemName\" saved successfully.';
  }

  @override
  String get itemName => 'Item Name';

  @override
  String get keepAllItems => 'Keep All Items';

  @override
  String get listIsEmpty =>
      'This list is empty.\nDouble-tap an item on the sales page to add it.';

  @override
  String get listOptions => 'List Options';

  @override
  String get loadingAllSet => 'All set!';

  @override
  String get loadingCheckingUpdates => 'Checking for updates...';

  @override
  String get loadingDownloadingDeals => 'Downloading latest deals...';

  @override
  String get loadingFromCache => 'Loading from local cache...';

  @override
  String get loadingInitializing => 'Initializing...';

  @override
  String get loadingPreparingStorage => 'Preparing local storage...';

  @override
  String get login => 'Login';

  @override
  String get logout => 'Logout';

  @override
  String get logoutConfirmation => 'Are you sure you want to logout?';

  @override
  String get manageCustomItemsTitle => 'Manage Custom Items';

  @override
  String get manageItems => 'Manage Items';

  @override
  String get manageLists => 'Manage Lists';

  @override
  String get manageMyLists => 'Manage My Lists';

  @override
  String get manageSubscription => 'Manage Subscription';

  @override
  String maximumListsReached(int count) {
    return 'You have reached the maximum of $count lists.';
  }

  @override
  String get myItems => 'My Items';

  @override
  String get myLists => 'My Lists';

  @override
  String get navAccount => 'Account';

  @override
  String get navAllSales => 'All Sales';

  @override
  String get navLists => 'Lists';

  @override
  String get newPassword => 'New Password';

  @override
  String get noEmailAvailable => 'No email available';

  @override
  String get noProductsFound => 'No products found matching your criteria.';

  @override
  String get noProductsMatchFilter => 'No products match your current filter';

  @override
  String get noSubcategoriesAvailable =>
      'No specific subcategories available\nfor the selected category.';

  @override
  String get noUserSignedIn => 'No user is currently signed in.';

  @override
  String get notifications => 'Notifications';

  @override
  String get ok => 'OK';

  @override
  String get or => 'OR';

  @override
  String get organizeList => 'Organize List';

  @override
  String get orSelectMainCategory => 'Or select a main category below:';

  @override
  String get password => 'Password';

  @override
  String get passwordChangedSuccessfully => 'Password changed successfully!';

  @override
  String passwordResetEmailSent(String email) {
    return 'Password reset email sent to $email';
  }

  @override
  String passwordTooShort(int count) {
    return 'Password must be at least $count characters long.';
  }

  @override
  String get pleaseEnterCurrentPassword => 'Please enter your current password';

  @override
  String get pleaseEnterEmail => 'Please enter an email address.';

  @override
  String get pleaseEnterItemName => 'Please enter an item name.';

  @override
  String get pleaseEnterNewPassword => 'Please enter a new password';

  @override
  String get pleaseEnterPassword => 'Please enter your password.';

  @override
  String get pleaseEnterValidEmail => 'Please enter a valid email address.';

  @override
  String get pleaseSelectCategory => 'Please select a category.';

  @override
  String get pleaseSelectCategoryFirst =>
      'Please select a category first\nto see available subcategories.';

  @override
  String get premium => 'Premium';

  @override
  String get premiumFeatureListsBody =>
      'Unlock the ability to create and manage multiple shopping lists by upgrading to Premium.';

  @override
  String get premiumFeatureListsTitle => 'Create More Lists';

  @override
  String get premiumStatus => 'Premium Status (Test)';

  @override
  String get rememberMe => 'Remember me';

  @override
  String get removeCheckedItems => 'Remove Checked Items';

  @override
  String get removedFromList => 'Removed from list';

  @override
  String removedFrom(String listName) {
    return 'Removed from \"$listName\"';
  }

  @override
  String removedItem(String itemName) {
    return 'Removed \"$itemName\"';
  }

  @override
  String get reset => 'RESET';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get resetPasswordInstructions =>
      'Enter your email address and we will send you a link to reset your password.';

  @override
  String get save => 'Save';

  @override
  String get saveChanges => 'SAVE CHANGES';

  @override
  String get saved => 'Saved';

  @override
  String get search => 'Search';

  @override
  String get searchProducts => 'Search Products';

  @override
  String get searchProductsHint => 'Search products...';

  @override
  String get selectCategory => 'Select Category';

  @override
  String get selectList => 'Select List';

  @override
  String get sendEmail => 'Send Email';

  @override
  String get settings => 'Settings';

  @override
  String get shop => 'Shop';

  @override
  String get shoppingListEmpty => 'Your shopping list is empty.';

  @override
  String get shoppingMode => 'Shopping Mode';

  @override
  String get showCheckedItems => 'Show checked items';

  @override
  String showMore(int count) {
    return 'Show $count more';
  }

  @override
  String get signUp => 'Sign Up';

  @override
  String get sort => 'Sort';

  @override
  String get sortBy => 'Sort By';

  @override
  String get sortDiscountHighToLow => 'Discount: High-Low';

  @override
  String get sortDiscountLowToHigh => 'Discount: Low-High';

  @override
  String get sortPriceHighToLow => 'Price: High-Low';

  @override
  String get sortPriceLowToHigh => 'Price: Low-High';

  @override
  String get sortProductAZ => 'Product: A-Z';

  @override
  String get sortStoreAZ => 'Store: A-Z';

  @override
  String get stores => 'Stores';

  @override
  String get subcategories => 'Subcategories';

  @override
  String get theme => 'Theme';

  @override
  String get tooltipShowAsGrid => 'Show as grid';

  @override
  String get tooltipShowAsList => 'Show as list';

  @override
  String get total => 'Total';

  @override
  String get uncheckAllItems => 'Uncheck All Items';

  @override
  String get uncheckItem => 'Uncheck item';

  @override
  String get updatePassword => 'UPDATE PASSWORD';

  @override
  String get upgradeButton => 'Upgrade Now';

  @override
  String get upgradeNow => 'Upgrade Now';

  @override
  String get upgradeToPremiumAction => 'Upgrade to Premium';

  @override
  String get upgradeToPremiumFeature1 => '• Unlimited Shopping Lists';

  @override
  String get upgradeToPremiumFeature2 => '• Unlimited Custom Items';

  @override
  String get upgradeToPremiumFeature3 => '• Ad-Free Experience';

  @override
  String get upgradeToPremiumTitle => 'Upgrade to Premium';

  @override
  String get user => 'User';

  @override
  String get usingCustomCategoryAbove => 'Using custom category above';

  @override
  String validFrom(String fromDate) {
    return 'Valid from $fromDate';
  }

  @override
  String validFromTo(String fromDate, String toDate) {
    return 'Valid from $fromDate to $toDate';
  }

  @override
  String validUntil(String toDate) {
    return 'Valid until $toDate';
  }

  @override
  String get validityUnknown => 'Validity unknown';

  @override
  String welcomeToAppName(String appName) {
    return 'Welcome to $appName';
  }

  @override
  String get dealExpired => 'Expired';

  @override
  String get tooltipManageListItems => 'Manage list items';

  @override
  String get manageItemsTitle => 'Manage Items';

  @override
  String get purgeButtonLabel => 'Purge Expired';

  @override
  String get purgeExpiredConfirmationTitle => 'Purge Expired?';

  @override
  String get purgeExpiredConfirmationBody =>
      'This will remove all expired (greyed-out) items from your list. This cannot be undone.';

  @override
  String get purgeButton => 'Purge';

  @override
  String get clearAllButtonLabel => 'Clear All Items';

  @override
  String get clearAllConfirmationTitle => 'Clear All Items?';

  @override
  String get clearAllConfirmationBody =>
      'This will permanently remove ALL items from your current list. This action cannot be undone.';

  @override
  String get clearAllButton => 'Clear All';

  @override
  String get moreOptions => 'More Options';

  @override
  String get customItem => 'Custom Item';
}
