import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en')
  ];

  /// Title for the account section or page.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// Label indicating the user has a free account.
  ///
  /// In en, this message translates to:
  /// **'Free User'**
  String get accountStatusFree;

  /// Label indicating the user has a premium account.
  ///
  /// In en, this message translates to:
  /// **'Premium Member'**
  String get accountStatusPremium;

  /// Placeholder text for an advertisement block on the loading screen.
  ///
  /// In en, this message translates to:
  /// **'Ad Placeholder\n300 x 250'**
  String get adPlaceholder;

  /// Button text indicating an item has already been added to a list.
  ///
  /// In en, this message translates to:
  /// **'ADDED'**
  String get added;

  /// Notification message when an item is added to the default active list.
  ///
  /// In en, this message translates to:
  /// **'Added to active list'**
  String get addedToActiveList;

  /// Notification message when an item is added to a specifically named list.
  ///
  /// In en, this message translates to:
  /// **'Added to \"{listName}\"'**
  String addedTo(String listName);

  /// Tooltip for the button to add a library item to the current shopping list.
  ///
  /// In en, this message translates to:
  /// **'Add to list'**
  String get addToList;

  /// Generic fallback error message.
  ///
  /// In en, this message translates to:
  /// **'An unknown error occurred'**
  String get anUnknownErrorOccurred;

  /// Generic fallback error message for unexpected issues.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred.'**
  String get anUnexpectedErrorOccurred;

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'SaleSeekr'**
  String get appName;

  /// Button text for applying filters.
  ///
  /// In en, this message translates to:
  /// **'APPLY'**
  String get apply;

  /// Generic text for a cancel button on a dialog.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Tab title for categories filter.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @categoryBeverages.
  ///
  /// In en, this message translates to:
  /// **'Beverages'**
  String get categoryBeverages;

  /// No description provided for @categoryCoffeeTeaCocoa.
  ///
  /// In en, this message translates to:
  /// **'Coffee, Tea & Cocoa'**
  String get categoryCoffeeTeaCocoa;

  /// No description provided for @categorySoftDrinksEnergyDrinks.
  ///
  /// In en, this message translates to:
  /// **'Soft Drinks & Energy Drinks'**
  String get categorySoftDrinksEnergyDrinks;

  /// No description provided for @categoryWaterJuices.
  ///
  /// In en, this message translates to:
  /// **'Water & Juices'**
  String get categoryWaterJuices;

  /// No description provided for @categoryAlcoholicBeverages.
  ///
  /// In en, this message translates to:
  /// **'Alcoholic Beverages'**
  String get categoryAlcoholicBeverages;

  /// No description provided for @categoryBeer.
  ///
  /// In en, this message translates to:
  /// **'Beer'**
  String get categoryBeer;

  /// No description provided for @categorySpiritsAssorted.
  ///
  /// In en, this message translates to:
  /// **'Spirits & Assorted'**
  String get categorySpiritsAssorted;

  /// No description provided for @categoryWinesSparklingWines.
  ///
  /// In en, this message translates to:
  /// **'Wines & Sparkling Wines'**
  String get categoryWinesSparklingWines;

  /// No description provided for @categoryBreadBakery.
  ///
  /// In en, this message translates to:
  /// **'Bread & Bakery'**
  String get categoryBreadBakery;

  /// No description provided for @categoryBakingIngredients.
  ///
  /// In en, this message translates to:
  /// **'Baking Ingredients'**
  String get categoryBakingIngredients;

  /// No description provided for @categoryBread.
  ///
  /// In en, this message translates to:
  /// **'Bread'**
  String get categoryBread;

  /// No description provided for @categoryPastriesDesserts.
  ///
  /// In en, this message translates to:
  /// **'Pastries & Desserts'**
  String get categoryPastriesDesserts;

  /// No description provided for @categoryFishMeat.
  ///
  /// In en, this message translates to:
  /// **'Fish & Meat'**
  String get categoryFishMeat;

  /// No description provided for @categoryMeatMixesAssorted.
  ///
  /// In en, this message translates to:
  /// **'Meat Mixes & Assorted'**
  String get categoryMeatMixesAssorted;

  /// No description provided for @categoryFishSeafood.
  ///
  /// In en, this message translates to:
  /// **'Fish & Seafood'**
  String get categoryFishSeafood;

  /// No description provided for @categoryPoultry.
  ///
  /// In en, this message translates to:
  /// **'Poultry'**
  String get categoryPoultry;

  /// No description provided for @categoryBeefVeal.
  ///
  /// In en, this message translates to:
  /// **'Beef & Veal'**
  String get categoryBeefVeal;

  /// No description provided for @categoryPork.
  ///
  /// In en, this message translates to:
  /// **'Pork'**
  String get categoryPork;

  /// No description provided for @categorySausagesColdCuts.
  ///
  /// In en, this message translates to:
  /// **'Sausages & Cold Cuts'**
  String get categorySausagesColdCuts;

  /// No description provided for @categoryFruitsVegetables.
  ///
  /// In en, this message translates to:
  /// **'Fruits & Vegetables'**
  String get categoryFruitsVegetables;

  /// No description provided for @categoryFruits.
  ///
  /// In en, this message translates to:
  /// **'Fruits'**
  String get categoryFruits;

  /// No description provided for @categoryVegetables.
  ///
  /// In en, this message translates to:
  /// **'Vegetables'**
  String get categoryVegetables;

  /// No description provided for @categoryDairyEggs.
  ///
  /// In en, this message translates to:
  /// **'Dairy & Eggs'**
  String get categoryDairyEggs;

  /// No description provided for @categoryButterEggs.
  ///
  /// In en, this message translates to:
  /// **'Butter & Eggs'**
  String get categoryButterEggs;

  /// No description provided for @categoryCheese.
  ///
  /// In en, this message translates to:
  /// **'Cheese'**
  String get categoryCheese;

  /// No description provided for @categoryMilkDairyProducts.
  ///
  /// In en, this message translates to:
  /// **'Milk & Dairy Products'**
  String get categoryMilkDairyProducts;

  /// No description provided for @categorySaltySnacksSweets.
  ///
  /// In en, this message translates to:
  /// **'Salty Snacks & Sweets'**
  String get categorySaltySnacksSweets;

  /// No description provided for @categorySnacksAppetizers.
  ///
  /// In en, this message translates to:
  /// **'Snacks & Appetizers'**
  String get categorySnacksAppetizers;

  /// No description provided for @categoryChipsNuts.
  ///
  /// In en, this message translates to:
  /// **'Chips & Nuts'**
  String get categoryChipsNuts;

  /// No description provided for @categoryIceCreamSweets.
  ///
  /// In en, this message translates to:
  /// **'Ice Cream & Sweets'**
  String get categoryIceCreamSweets;

  /// No description provided for @categoryChocolateCookies.
  ///
  /// In en, this message translates to:
  /// **'Chocolate & Cookies'**
  String get categoryChocolateCookies;

  /// No description provided for @categorySpecialDiet.
  ///
  /// In en, this message translates to:
  /// **'Special Diet'**
  String get categorySpecialDiet;

  /// No description provided for @categoryConvenienceReadyMeals.
  ///
  /// In en, this message translates to:
  /// **'Convenience & Ready Meals'**
  String get categoryConvenienceReadyMeals;

  /// No description provided for @categoryVeganProducts.
  ///
  /// In en, this message translates to:
  /// **'Vegan Products'**
  String get categoryVeganProducts;

  /// No description provided for @categoryPantry.
  ///
  /// In en, this message translates to:
  /// **'Pantry'**
  String get categoryPantry;

  /// No description provided for @categoryCerealsGrains.
  ///
  /// In en, this message translates to:
  /// **'Cereals & Grains'**
  String get categoryCerealsGrains;

  /// No description provided for @categoryCannedGoodsOilsSaucesSpices.
  ///
  /// In en, this message translates to:
  /// **'Cans, Oils, Sauces & Spices'**
  String get categoryCannedGoodsOilsSaucesSpices;

  /// No description provided for @categoryHoneyJamSpreads.
  ///
  /// In en, this message translates to:
  /// **'Honey, Jam & Spreads'**
  String get categoryHoneyJamSpreads;

  /// No description provided for @categoryRicePasta.
  ///
  /// In en, this message translates to:
  /// **'Rice & Pasta'**
  String get categoryRicePasta;

  /// No description provided for @categoryFrozenProductsSoups.
  ///
  /// In en, this message translates to:
  /// **'Frozen Products & Soups'**
  String get categoryFrozenProductsSoups;

  /// No description provided for @categoryCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom Items'**
  String get categoryCustom;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// No description provided for @categoryUncategorized.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get categoryUncategorized;

  /// Title for the change password page and button.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// Tooltip for the checkbox in shopping mode to mark an item as found.
  ///
  /// In en, this message translates to:
  /// **'Check item'**
  String get checkItem;

  /// Button text to remove an item from a list.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// Button text to add an item to a list.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Button text to close a dialog or screen.
  ///
  /// In en, this message translates to:
  /// **'CLOSE'**
  String get close;

  /// Button text for signing in with a Google account.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// Error message when the app fails to launch a URL to a product page.
  ///
  /// In en, this message translates to:
  /// **'Could not open product link'**
  String get couldNotOpenProductLink;

  /// Button text for the sign-up form.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// Button text for creating a new custom item and adding it to a list.
  ///
  /// In en, this message translates to:
  /// **'CREATE & ADD ITEM'**
  String get createAndAddItem;

  /// Button text for creating a new shopping list and making it the active one.
  ///
  /// In en, this message translates to:
  /// **'CREATE AND SELECT'**
  String get createAndSelect;

  /// Success message shown after creating a new shopping list.
  ///
  /// In en, this message translates to:
  /// **'Created and selected list \"{listName}\"'**
  String createdAndSelectedList(String listName);

  /// AppBar title for the page where users create a new custom item.
  ///
  /// In en, this message translates to:
  /// **'Create Custom Item'**
  String get createCustomItem;

  /// Informational text for non-premium users about the list creation limit.
  ///
  /// In en, this message translates to:
  /// **'Create up to {count} custom lists with Premium.'**
  String createCustomListsWithPremium(int count);

  /// Button text for creating a new custom item.
  ///
  /// In en, this message translates to:
  /// **'CREATE ITEM'**
  String get createItem;

  /// Abbreviation for the currency Swiss Francs.
  ///
  /// In en, this message translates to:
  /// **'Fr.'**
  String get currencyFrancs;

  /// Label for the current password input field.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// Label for the custom category input field, a premium feature.
  ///
  /// In en, this message translates to:
  /// **'Custom Category (Premium)'**
  String get customCategoryPremium;

  /// Error message shown when a user tries to create more custom items than their plan allows.
  ///
  /// In en, this message translates to:
  /// **'You have reached your limit of {count} custom items.'**
  String customItemLimitReached(int count);

  /// Label for the button or section related to user-created custom items.
  ///
  /// In en, this message translates to:
  /// **'Custom Items'**
  String get customItems;

  /// Message shown in the custom items library when it's empty.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t created any custom items yet.'**
  String get customItemsEmpty;

  /// Section header on the account page for destructive actions.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get dangerZone;

  /// Tooltip for the minus button on the quantity stepper.
  ///
  /// In en, this message translates to:
  /// **'Decrease quantity'**
  String get decreaseQuantity;

  /// The default name for the user's first shopping list.
  ///
  /// In en, this message translates to:
  /// **'Merkliste'**
  String get defaultListName;

  /// Loading message shown while the initial default shopping list is being created for a user.
  ///
  /// In en, this message translates to:
  /// **'Your default list is being prepared...'**
  String get defaultListIsBeingPrepared;

  /// Generic text for a delete button on a dialog.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Title and button text for the account deletion feature.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// Warning message in the account deletion confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'This action is permanent and cannot be undone. All your lists and data will be lost. Please enter your password to confirm.'**
  String get deleteAccountConfirmationBody;

  /// Warning message in the confirmation dialog for deleting a custom item.
  ///
  /// In en, this message translates to:
  /// **'This will permanently remove the item from your library.'**
  String get deleteItemConfirmationBody;

  /// Title of the confirmation dialog when deleting a custom item.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{itemName}\"?'**
  String deleteItemConfirmationTitle(String itemName);

  /// Warning message in the confirmation dialog for deleting a list.
  ///
  /// In en, this message translates to:
  /// **'This action is permanent and cannot be undone.'**
  String get deleteListConfirmationBody;

  /// Title of the confirmation dialog when deleting a list.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{listName}\"?'**
  String deleteListConfirmationTitle(String listName);

  /// Confirmation button text for permanently deleting an account.
  ///
  /// In en, this message translates to:
  /// **'DELETE PERMANENTLY'**
  String get deletePermanently;

  /// Label for the display name input field.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get displayName;

  /// AppBar title for the page where users edit an existing custom item.
  ///
  /// In en, this message translates to:
  /// **'Edit Custom Item'**
  String get editCustomItem;

  /// Title for the edit profile dialog and button.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// Label for the email input field.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// Label for the text field where a user enters the name for a new shopping list.
  ///
  /// In en, this message translates to:
  /// **'Enter new list name'**
  String get enterNewListName;

  /// Generic error message prefix.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String error(String error);

  /// Error message shown on the loading screen if initialization fails.
  ///
  /// In en, this message translates to:
  /// **'Error: Could not load data.'**
  String get errorCouldNotLoadData;

  /// Error message shown on the shopping list page when data fails to load.
  ///
  /// In en, this message translates to:
  /// **'Error loading list: {error}'**
  String errorLoadingList(String error);

  /// Error message shown on the account page when the user's profile fails to load.
  ///
  /// In en, this message translates to:
  /// **'Error loading profile'**
  String get errorLoadingProfile;

  /// Error message shown when saving a custom item fails.
  ///
  /// In en, this message translates to:
  /// **'Error saving item: {error}'**
  String errorSavingItem(String error);

  /// Error message when the password reset email fails to send.
  ///
  /// In en, this message translates to:
  /// **'Failed to send reset email.'**
  String get failedToSendResetEmail;

  /// Error message for a critical, unrecoverable error.
  ///
  /// In en, this message translates to:
  /// **'Fatal Error: {error}'**
  String fatalError(String error);

  /// Placeholder message for features that are not yet built.
  ///
  /// In en, this message translates to:
  /// **'{featureName} is not yet implemented.'**
  String featureNotImplemented(String featureName);

  /// Button text to open filtering options.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// Section header for filtering by store
  ///
  /// In en, this message translates to:
  /// **'Filter by Store'**
  String get filterByStore;

  /// Header title for the product filtering bottom sheet.
  ///
  /// In en, this message translates to:
  /// **'Filter Products'**
  String get filterProducts;

  /// Button text in shopping mode to finish the shopping session.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// Content of the confirmation dialog when finishing shopping.
  ///
  /// In en, this message translates to:
  /// **'Do you want to remove the checked items from your list or keep everything?'**
  String get finishShoppingBody;

  /// Title of the confirmation dialog when finishing shopping.
  ///
  /// In en, this message translates to:
  /// **'Finish Shopping?'**
  String get finishShoppingTitle;

  /// Button text for the password reset flow.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// Tooltip for the visibility toggle in shopping mode to hide checked items.
  ///
  /// In en, this message translates to:
  /// **'Hide checked items'**
  String get hideCheckedItems;

  /// Tooltip for the plus button on the quantity stepper.
  ///
  /// In en, this message translates to:
  /// **'Increase quantity'**
  String get increaseQuantity;

  /// Text shown on the splash screen while the app is loading.
  ///
  /// In en, this message translates to:
  /// **'Initializing...'**
  String get initializing;

  /// Notification text shown when a custom item is successfully added to a specific shopping list.
  ///
  /// In en, this message translates to:
  /// **'\'{itemName}\' added to {listName}.'**
  String itemAddedToList(String itemName, String listName);

  /// Success message shown after deleting a custom item from the library.
  ///
  /// In en, this message translates to:
  /// **'\"{itemName}\" deleted.'**
  String itemDeleted(String itemName);

  /// Message shown when the user has too many items in their shopping list.
  ///
  /// In en, this message translates to:
  /// **'Your list contains {currentItems} items, but the maximum is {limit}. Please remove some items to continue.'**
  String itemLimitReachedBody(int currentItems, int limit);

  /// Title for the dialog when the shopping list is too full.
  ///
  /// In en, this message translates to:
  /// **'Item Limit Reached'**
  String get itemLimitReachedTitle;

  /// Label for a counter showing the number of items.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get itemsLabel;

  /// Success message shown after an item is saved.
  ///
  /// In en, this message translates to:
  /// **'\"{itemName}\" saved successfully.'**
  String itemSavedSuccessfully(String itemName);

  /// Label for the item name input field.
  ///
  /// In en, this message translates to:
  /// **'Item Name'**
  String get itemName;

  /// Button text in the finish shopping dialog to keep all items on the list.
  ///
  /// In en, this message translates to:
  /// **'Keep All Items'**
  String get keepAllItems;

  /// Message shown on the shopping list page when it contains no items.
  ///
  /// In en, this message translates to:
  /// **'This list is empty.'**
  String get listIsEmpty;

  /// Header title for the list options bottom sheet.
  ///
  /// In en, this message translates to:
  /// **'List Options'**
  String get listOptions;

  /// Final success message before entering the app.
  ///
  /// In en, this message translates to:
  /// **'All set!'**
  String get loadingAllSet;

  /// Loading message when checking if a sync from Firestore is needed.
  ///
  /// In en, this message translates to:
  /// **'Checking for updates...'**
  String get loadingCheckingUpdates;

  /// Loading message during a sync from Firestore.
  ///
  /// In en, this message translates to:
  /// **'Downloading latest deals...'**
  String get loadingDownloadingDeals;

  /// Loading message when using local data instead of syncing.
  ///
  /// In en, this message translates to:
  /// **'Loading from local cache...'**
  String get loadingFromCache;

  /// Initial loading message.
  ///
  /// In en, this message translates to:
  /// **'Initializing...'**
  String get loadingInitializing;

  /// Loading message when setting up Hive/local database.
  ///
  /// In en, this message translates to:
  /// **'Preparing local storage...'**
  String get loadingPreparingStorage;

  /// Tab and button text for the login action.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Title and button text for the logout action.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Confirmation message in the logout dialog.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmation;

  /// AppBar title for the page where users manage their custom items.
  ///
  /// In en, this message translates to:
  /// **'Manage Custom Items'**
  String get manageCustomItemsTitle;

  /// Button label for navigating to the 'Manage Custom Items' page.
  ///
  /// In en, this message translates to:
  /// **'Manage Items'**
  String get manageItems;

  /// Button label for opening the 'Manage Lists' bottom sheet.
  ///
  /// In en, this message translates to:
  /// **'Manage Lists'**
  String get manageLists;

  /// Header title for the shopping list management bottom sheet.
  ///
  /// In en, this message translates to:
  /// **'Manage My Lists'**
  String get manageMyLists;

  /// Button text for managing a premium subscription.
  ///
  /// In en, this message translates to:
  /// **'Manage Subscription'**
  String get manageSubscription;

  /// Message shown to premium users when they have reached their shopping list limit.
  ///
  /// In en, this message translates to:
  /// **'You have reached the maximum of {count} lists.'**
  String maximumListsReached(int count);

  /// Tab title for the user's library of custom created items.
  ///
  /// In en, this message translates to:
  /// **'My Items'**
  String get myItems;

  /// Tab title for the user's existing shopping lists.
  ///
  /// In en, this message translates to:
  /// **'My Lists'**
  String get myLists;

  /// Label for the Account tab in the bottom navigation bar.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get navAccount;

  /// Label for the Home/All Sales tab in the bottom navigation bar.
  ///
  /// In en, this message translates to:
  /// **'All Sales'**
  String get navAllSales;

  /// Label for the Shopping Lists tab in the bottom navigation bar.
  ///
  /// In en, this message translates to:
  /// **'Lists'**
  String get navLists;

  /// Label for the new password input field.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// Fallback text shown on the account page if a user has no email.
  ///
  /// In en, this message translates to:
  /// **'No email available'**
  String get noEmailAvailable;

  /// Message shown on the home page when filters result in no products.
  ///
  /// In en, this message translates to:
  /// **'No products found matching your criteria.'**
  String get noProductsFound;

  /// Message shown on the shopping list when filters result in an empty list
  ///
  /// In en, this message translates to:
  /// **'No products match your current filter'**
  String get noProductsMatchFilter;

  /// Message shown in the subcategory filter when the selected main category has no subcategories.
  ///
  /// In en, this message translates to:
  /// **'No specific subcategories available\nfor the selected category.'**
  String get noSubcategoriesAvailable;

  /// Error message for actions that require an authenticated user.
  ///
  /// In en, this message translates to:
  /// **'No user is currently signed in.'**
  String get noUserSignedIn;

  /// Button text for the notifications settings.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// A generic confirmation button text.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// A separator text, typically used between login methods.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// Title for the bottom sheet and tooltip for organizing a shopping list
  ///
  /// In en, this message translates to:
  /// **'Organize List'**
  String get organizeList;

  /// Instructional text when creating a custom item.
  ///
  /// In en, this message translates to:
  /// **'Or select a main category below:'**
  String get orSelectMainCategory;

  /// Label for the password input field.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Success message shown after a user changes their password.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully!'**
  String get passwordChangedSuccessfully;

  /// Success message after sending a password reset email.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent to {email}'**
  String passwordResetEmailSent(String email);

  /// Validation error for a password that is too short.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least {count} characters long.'**
  String passwordTooShort(int count);

  /// Validation error for an empty current password field.
  ///
  /// In en, this message translates to:
  /// **'Please enter your current password'**
  String get pleaseEnterCurrentPassword;

  /// Validation error for an empty email field.
  ///
  /// In en, this message translates to:
  /// **'Please enter an email address.'**
  String get pleaseEnterEmail;

  /// Validation error for an empty item name field.
  ///
  /// In en, this message translates to:
  /// **'Please enter an item name.'**
  String get pleaseEnterItemName;

  /// Validation error for an empty new password field.
  ///
  /// In en, this message translates to:
  /// **'Please enter a new password'**
  String get pleaseEnterNewPassword;

  /// Validation error for an empty password field.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password.'**
  String get pleaseEnterPassword;

  /// Validation error for an incorrectly formatted email.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get pleaseEnterValidEmail;

  /// Validation error when no category has been selected.
  ///
  /// In en, this message translates to:
  /// **'Please select a category.'**
  String get pleaseSelectCategory;

  /// Instructional text in the subcategory filter tab when no main category is selected yet.
  ///
  /// In en, this message translates to:
  /// **'Please select a category first\nto see available subcategories.'**
  String get pleaseSelectCategoryFirst;

  /// Title for the Premium/Subscription section on the account page.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premium;

  /// Body text for a premium feature highlight.
  ///
  /// In en, this message translates to:
  /// **'Unlock the ability to create and manage multiple shopping lists by upgrading to Premium.'**
  String get premiumFeatureListsBody;

  /// Title for a premium feature highlight.
  ///
  /// In en, this message translates to:
  /// **'Create More Lists'**
  String get premiumFeatureListsTitle;

  /// Text showing the user's premium status, for testing purposes.
  ///
  /// In en, this message translates to:
  /// **'Premium Status (Test)'**
  String get premiumStatus;

  /// Label for the 'keep me logged in' checkbox.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get rememberMe;

  /// Button text in the finish shopping dialog to remove checked items from the list.
  ///
  /// In en, this message translates to:
  /// **'Remove Checked Items'**
  String get removeCheckedItems;

  /// Notification message when an item is removed from the active list.
  ///
  /// In en, this message translates to:
  /// **'Removed from list'**
  String get removedFromList;

  /// Notification message when an item is removed from a specific list.
  ///
  /// In en, this message translates to:
  /// **'Removed from \"{listName}\"'**
  String removedFrom(String listName);

  /// Notification message shown when an item is removed from the list via double tap.
  ///
  /// In en, this message translates to:
  /// **'Removed \"{itemName}\"'**
  String removedItem(String itemName);

  /// Button text for resetting filters to their default state.
  ///
  /// In en, this message translates to:
  /// **'RESET'**
  String get reset;

  /// Title for the password reset dialog.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// Instructions in the password reset dialog.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address and we will send you a link to reset your password.'**
  String get resetPasswordInstructions;

  /// A common button label for saving changes.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Button text for saving changes when editing an item.
  ///
  /// In en, this message translates to:
  /// **'SAVE CHANGES'**
  String get saveChanges;

  /// Label for the total amount of money saved in the shopping summary bar.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// Button text to open search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Header title for the search bottom sheet.
  ///
  /// In en, this message translates to:
  /// **'Search Products'**
  String get searchProducts;

  /// Hint text for the search input field.
  ///
  /// In en, this message translates to:
  /// **'Search products...'**
  String get searchProductsHint;

  /// Label for the category selection dropdown menu.
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get selectCategory;

  /// Default text on the button to select a shopping list when none is active.
  ///
  /// In en, this message translates to:
  /// **'Select List'**
  String get selectList;

  /// Button text for sending a password reset email.
  ///
  /// In en, this message translates to:
  /// **'Send Email'**
  String get sendEmail;

  /// Title for the settings section on the account page.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Short button text to begin a shopping session.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get shop;

  /// Message shown in shopping mode when the list has no items.
  ///
  /// In en, this message translates to:
  /// **'Your shopping list is empty.'**
  String get shoppingListEmpty;

  /// Title for the screen where users check off items from their list.
  ///
  /// In en, this message translates to:
  /// **'Shopping Mode'**
  String get shoppingMode;

  /// Tooltip for the visibility toggle in shopping mode to show checked items.
  ///
  /// In en, this message translates to:
  /// **'Show checked items'**
  String get showCheckedItems;

  /// Button text to paginate and show more items in a category.
  ///
  /// In en, this message translates to:
  /// **'Show {count} more'**
  String showMore(int count);

  /// Tab text for the sign-up form.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// Button text to open sorting options.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// Header title for the sorting options bottom sheet.
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get sortBy;

  /// Sort option display name
  ///
  /// In en, this message translates to:
  /// **'Discount: High-Low'**
  String get sortDiscountHighToLow;

  /// Sort option display name
  ///
  /// In en, this message translates to:
  /// **'Discount: Low-High'**
  String get sortDiscountLowToHigh;

  /// Sort option display name
  ///
  /// In en, this message translates to:
  /// **'Price: High-Low'**
  String get sortPriceHighToLow;

  /// Sort option display name
  ///
  /// In en, this message translates to:
  /// **'Price: Low-High'**
  String get sortPriceLowToHigh;

  /// Sort option display name
  ///
  /// In en, this message translates to:
  /// **'Product: A-Z'**
  String get sortProductAZ;

  /// Sort option display name
  ///
  /// In en, this message translates to:
  /// **'Store: A-Z'**
  String get sortStoreAZ;

  /// Tab title for the stores filter.
  ///
  /// In en, this message translates to:
  /// **'Stores'**
  String get stores;

  /// Tab title for the subcategories filter.
  ///
  /// In en, this message translates to:
  /// **'Subcategories'**
  String get subcategories;

  /// Button text for theme settings.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// Tooltip for the button to switch to grid view.
  ///
  /// In en, this message translates to:
  /// **'Show as grid'**
  String get tooltipShowAsGrid;

  /// Tooltip for the button to switch to list view.
  ///
  /// In en, this message translates to:
  /// **'Show as list'**
  String get tooltipShowAsList;

  /// Label for the total cost of items in the shopping summary bar.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// Tooltip for the refresh button in shopping mode.
  ///
  /// In en, this message translates to:
  /// **'Uncheck All Items'**
  String get uncheckAllItems;

  /// Tooltip for the checkbox in shopping mode to unmark an item as found.
  ///
  /// In en, this message translates to:
  /// **'Uncheck item'**
  String get uncheckItem;

  /// Button text to confirm a password update.
  ///
  /// In en, this message translates to:
  /// **'UPDATE PASSWORD'**
  String get updatePassword;

  /// Button text to initiate the upgrade process.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Now'**
  String get upgradeButton;

  /// Button text prompting non-premium users to upgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Now'**
  String get upgradeNow;

  /// Button text prompting a free user to upgrade their account.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium'**
  String get upgradeToPremiumAction;

  /// Feature description for premium.
  ///
  /// In en, this message translates to:
  /// **'• Unlimited Shopping Lists'**
  String get upgradeToPremiumFeature1;

  /// Feature description for premium.
  ///
  /// In en, this message translates to:
  /// **'• Unlimited Custom Items'**
  String get upgradeToPremiumFeature2;

  /// Feature description for premium.
  ///
  /// In en, this message translates to:
  /// **'• Ad-Free Experience'**
  String get upgradeToPremiumFeature3;

  /// Title for the upgrade to premium dialog.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium'**
  String get upgradeToPremiumTitle;

  /// Fallback display name for a user if their name is not set.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// Informational text shown when a user has entered a custom category, disabling the dropdown.
  ///
  /// In en, this message translates to:
  /// **'Using custom category above'**
  String get usingCustomCategoryAbove;

  /// Indicates the start date of a product's sale.
  ///
  /// In en, this message translates to:
  /// **'Valid from {fromDate}'**
  String validFrom(String fromDate);

  /// Indicates the start and end date of a product's sale.
  ///
  /// In en, this message translates to:
  /// **'Valid from {fromDate} to {toDate}'**
  String validFromTo(String fromDate, String toDate);

  /// Indicates the end date of a product's sale.
  ///
  /// In en, this message translates to:
  /// **'Valid until {toDate}'**
  String validUntil(String toDate);

  /// Text shown when a product's sale period is not known.
  ///
  /// In en, this message translates to:
  /// **'Validity unknown'**
  String get validityUnknown;

  /// Welcome message on the login screen.
  ///
  /// In en, this message translates to:
  /// **'Welcome to {appName}'**
  String welcomeToAppName(String appName);

  /// Label for expired deals
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get dealExpired;

  /// Tooltip for the button that opens the list management options (purge, clear all).
  ///
  /// In en, this message translates to:
  /// **'Manage list items'**
  String get tooltipManageListItems;

  /// Title for the bottom sheet that manages shopping list items.
  ///
  /// In en, this message translates to:
  /// **'Manage Items'**
  String get manageItemsTitle;

  /// Text for the button that purges expired items.
  ///
  /// In en, this message translates to:
  /// **'Purge Expired'**
  String get purgeButtonLabel;

  /// Confirmation dialog title for purging expired items.
  ///
  /// In en, this message translates to:
  /// **'Purge Expired?'**
  String get purgeExpiredConfirmationTitle;

  /// Confirmation dialog body for purging expired items.
  ///
  /// In en, this message translates to:
  /// **'This will remove all expired (greyed-out) items from your list. This cannot be undone.'**
  String get purgeExpiredConfirmationBody;

  /// Text for the confirmation button to purge items.
  ///
  /// In en, this message translates to:
  /// **'Purge'**
  String get purgeButton;

  /// Text for the button that clears all items.
  ///
  /// In en, this message translates to:
  /// **'Clear All Items'**
  String get clearAllButtonLabel;

  /// Confirmation dialog title for clearing all items.
  ///
  /// In en, this message translates to:
  /// **'Clear All Items?'**
  String get clearAllConfirmationTitle;

  /// Confirmation dialog body for clearing all items.
  ///
  /// In en, this message translates to:
  /// **'This will permanently remove ALL items from your current list. This action cannot be undone.'**
  String get clearAllConfirmationBody;

  /// Text for the confirmation button to clear all items.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAllButton;

  /// Tooltip for a button that opens a menu with more actions like Edit or Delete.
  ///
  /// In en, this message translates to:
  /// **'More Options'**
  String get moreOptions;

  /// A generic fallback label for a custom item when it doesn't have a specific user-defined category.
  ///
  /// In en, this message translates to:
  /// **'Custom Item'**
  String get customItem;

  /// Button text for re-authenticating with Google, typically for sensitive actions.
  ///
  /// In en, this message translates to:
  /// **'Re-authenticate with Google'**
  String get reauthenticateWithGoogle;

  /// Instructional text in the delete account dialog for users who signed in with Google.
  ///
  /// In en, this message translates to:
  /// **'To delete your account, you must re-authenticate with Google.'**
  String get deleteAccountGooglePrompt;

  /// Button text on the delete account confirmation for Google users.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogleForDelete;

  /// Generic confirm button
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Tooltip text for the 'show less' button, indicating that a long press will reset the list.
  ///
  /// In en, this message translates to:
  /// **'Long-press to collapse list'**
  String get tooltipCollapseList;

  /// Label indicating where a product can be bought.
  ///
  /// In en, this message translates to:
  /// **'Available at'**
  String get availableAt;

  /// Message displayed when the user has not created any custom shopping lists.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t created any custom lists yet.'**
  String get shoppingListsEmpty;

  /// Label for the count of shopping lists in the management page.
  ///
  /// In en, this message translates to:
  /// **'Lists'**
  String get listsLabel;

  /// Button and tab text for creating a new item or list.
  ///
  /// In en, this message translates to:
  /// **'Create New'**
  String get createNew;

  /// Short text displayed in the app bar when the user has created zero shopping lists.
  ///
  /// In en, this message translates to:
  /// **'No Lists'**
  String get noListsExist;

  /// A generic fallback name for a shopping list if its name cannot be found.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get list;

  /// A short label for a button that creates a new item, like a shopping list.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// A generic welcome message for a new user.
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get welcome;

  /// The title for the dialog where a user can rename a shopping list.
  ///
  /// In en, this message translates to:
  /// **'Rename List'**
  String get renameListTitle;

  /// The label for the text field where a user enters the name of a shopping list.
  ///
  /// In en, this message translates to:
  /// **'List Name'**
  String get listNameLabel;

  /// Instructional text prompting a new user to create their first shopping list.
  ///
  /// In en, this message translates to:
  /// **'Create your first shopping list to get started.'**
  String get createFirstListPrompt;

  /// Button text for creating a new shopping list from an empty state.
  ///
  /// In en, this message translates to:
  /// **'Create a List'**
  String get createListButton;

  /// Fallback text for a shopping list's name when it cannot be found.
  ///
  /// In en, this message translates to:
  /// **'your list'**
  String get yourList;

  /// Indicates how many items are selected in the app bar during multi-select mode.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String itemsSelected(int count);

  /// Tooltip for the button to delete multiple selected items.
  ///
  /// In en, this message translates to:
  /// **'Delete selected items'**
  String get tooltipDeleteSelected;

  /// Title for the confirmation dialog before deleting items.
  ///
  /// In en, this message translates to:
  /// **'Confirm Deletion'**
  String get confirmDeletionTitle;

  /// Confirmation message asking the user to confirm the deletion of multiple items.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {count} items?'**
  String confirmDeletionMessage(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
