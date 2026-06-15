// lib/core/constants/strings.dart

class Strings {
  Strings._();

  // ---- General ----
  static const String appTitle = 'Our Heart';
  static const String ok = 'OK';
  static const String cancel = 'Cancel';
  static const String save = 'Save';
  static const String delete = 'Delete';
  static const String confirm = 'Confirm';
  static const String retry = 'Retry';
  static const String noData = 'No data yet.';
  static const String loading = 'Loading…';
  static const String errorOccurred = 'Something went wrong. Please try again.';

  // ---- PIN / Auth ----
  static const String enterPin = 'Enter your PIN';
  static const String setPin = 'Set a new PIN';
  static const String confirmPin = 'Confirm your PIN';
  static const String pinMismatch = 'PINs do not match.';
  static const String pinTooShort = 'PIN must be exactly 4 digits.';
  static const String wrongPin = 'Incorrect PIN.';
  static const String pinSetSuccess = 'PIN has been set successfully.';

  // ---- Home ----
  static const String homeRelationshipLabel = 'Together since';
  static const String homeNoPartnerName = 'Your Partner';
  static const String homeNoProfilePic = 'Tap to add a profile picture';
  static const String homeAffirmationsTitle = 'Today’s Affirmations';
  static const String homeDaysCounter = 'days';

  // ---- Settings ----
  static const String settingsTitle = 'Settings';
  static const String settingsYourName = 'Your Name';
  static const String settingsPartnerName = 'Partner’s Name';
  static const String settingsYourGender = 'Your Gender';
  static const String settingsPartnerGender = 'Partner’s Gender';
  static const String settingsTheme = 'Theme';
  static const String settingsChangePin = 'Change PIN';
  static const String settingsExportData = 'Export all data';
  static const String settingsExportWarning =
      'Your data will be saved as an unencrypted ZIP file. Please keep it safe.';
  static const String settingsExportSuccess = 'Data exported successfully.';
  static const String settingsExportFailed = 'Export failed.';
  static const String settingsProfilePicture = 'Profile Picture';
  static const String settingsPartnerProfilePicture = 'Partner Profile Picture';

  // ---- Info ----
  static const String infoTitle = 'Info';
  static const String infoAddNew = 'Add Info Entry';
  static const String infoEditEntry = 'Edit Entry';
  static const String infoTitleField = 'Title';
  static const String infoContentField = 'Content';
  static const String infoTitleValidation = 'Title cannot be empty.';

  // ---- Plans / Calendar ----
  static const String plansTitle = 'Plans';
  static const String plansNoEvents = 'No events for this date.';
  static const String plansAddEvent = 'Add Event';
  static const String plansEditEvent = 'Edit Event';
  static const String plansEventTitle = 'Event Title';
  static const String plansEventDate = 'Date';
  static const String plansEventTime = 'Time';
  static const String plansEventReminder = 'Set Reminder';

  // ---- Reminders ----
  static const String remindersTitle = 'Reminders';
  static const String remindersNoUpcoming = 'No upcoming reminders.';
  static const String remindersAdd = 'Add Reminder';
  static const String remindersTime = 'Time';
  static const String remindersDescription = 'Description';

  // ---- Gallery ----
  static const String galleryTitle = 'Gallery';
  static const String galleryNoPhotos = 'No photos yet!';
  static const String galleryAddPhoto = 'Add Photo';
  static const String galleryDeleteConfirmation = 'Delete selected photos?';
  static const String galleryDeleteSuccess = 'Photos deleted.';
  static const String galleryPhotoPickerError = 'Could not load photo.';

  // ---- Letters ----
  static const String lettersTitle = 'Letters';
  static const String lettersNoLetters = 'No letters written yet.';
  static const String lettersAdd = 'Write a Letter';
  static const String lettersEdit = 'Edit Letter';
  static const String lettersTitleField = 'Title';
  static const String lettersContentField = 'Dear ...';
  static const String lettersTitleValidation = 'Title cannot be empty.';

  // ---- Permissions ----
  static const String permissionCamera = 'Camera permission is required to take photos.';
  static const String permissionStorage = 'Storage permission is required to save photos.';
  static const String permissionNotifications = 'Notification permission is required for reminders.';
  static const String permissionBackground = 'Background permission is needed for the relationship counter.';
  static const String permissionDeniedPermanently = 'Permission permanently denied. Please enable it in system settings.';
}