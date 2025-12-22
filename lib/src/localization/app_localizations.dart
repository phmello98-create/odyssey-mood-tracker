import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'localization/app_localizations.dart';
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
    Locale('en'),
    Locale('pt'),
  ];

  /// No description provided for @abandoned.
  ///
  /// In en, this message translates to:
  /// **'Abandoned'**
  String get abandoned;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @abrir.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get abrir;

  /// No description provided for @abrirConfiguracoes.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get abrirConfiguracoes;

  /// No description provided for @accumulatedFocusTime.
  ///
  /// In en, this message translates to:
  /// **'You\'ve already accumulated {hours}h {mins}m of focus today. Impressive!'**
  String accumulatedFocusTime(Object hours, Object mins);

  /// No description provided for @acertei.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get acertei;

  /// No description provided for @achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// No description provided for @activeDays.
  ///
  /// In en, this message translates to:
  /// **'Active Days'**
  String get activeDays;

  /// No description provided for @activeWidgets.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE ({count})'**
  String activeWidgets(Object count);

  /// No description provided for @activities.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get activities;

  /// No description provided for @activityBadSleep.
  ///
  /// In en, this message translates to:
  /// **'bad sleep'**
  String get activityBadSleep;

  /// No description provided for @activityCategoryBetterMe.
  ///
  /// In en, this message translates to:
  /// **'Better Me'**
  String get activityCategoryBetterMe;

  /// No description provided for @activityCategoryChores.
  ///
  /// In en, this message translates to:
  /// **'Chores'**
  String get activityCategoryChores;

  /// No description provided for @activityCategoryHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get activityCategoryHealth;

  /// No description provided for @activityCategoryHobbies.
  ///
  /// In en, this message translates to:
  /// **'Hobbies'**
  String get activityCategoryHobbies;

  /// No description provided for @activityCategorySleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get activityCategorySleep;

  /// No description provided for @activityCategorySocial.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get activityCategorySocial;

  /// No description provided for @activityCleaning.
  ///
  /// In en, this message translates to:
  /// **'cleaning'**
  String get activityCleaning;

  /// No description provided for @activityCoding.
  ///
  /// In en, this message translates to:
  /// **'Coding'**
  String get activityCoding;

  /// No description provided for @activityCooking.
  ///
  /// In en, this message translates to:
  /// **'cooking'**
  String get activityCooking;

  /// No description provided for @activityCreative.
  ///
  /// In en, this message translates to:
  /// **'Creative'**
  String get activityCreative;

  /// No description provided for @activityDate.
  ///
  /// In en, this message translates to:
  /// **'date'**
  String get activityDate;

  /// No description provided for @activityDonate.
  ///
  /// In en, this message translates to:
  /// **'donate'**
  String get activityDonate;

  /// No description provided for @activityDrinkWater.
  ///
  /// In en, this message translates to:
  /// **'drink water'**
  String get activityDrinkWater;

  /// No description provided for @activityExercise.
  ///
  /// In en, this message translates to:
  /// **'exercise'**
  String get activityExercise;

  /// No description provided for @activityFamily.
  ///
  /// In en, this message translates to:
  /// **'family'**
  String get activityFamily;

  /// No description provided for @activityFriends.
  ///
  /// In en, this message translates to:
  /// **'friends'**
  String get activityFriends;

  /// No description provided for @activityGaming.
  ///
  /// In en, this message translates to:
  /// **'gaming'**
  String get activityGaming;

  /// No description provided for @activityGiveGift.
  ///
  /// In en, this message translates to:
  /// **'give gift'**
  String get activityGiveGift;

  /// No description provided for @activityGoodSleep.
  ///
  /// In en, this message translates to:
  /// **'good sleep'**
  String get activityGoodSleep;

  /// No description provided for @activityKindness.
  ///
  /// In en, this message translates to:
  /// **'kindness'**
  String get activityKindness;

  /// No description provided for @activityLaundry.
  ///
  /// In en, this message translates to:
  /// **'laundry'**
  String get activityLaundry;

  /// No description provided for @activityListen.
  ///
  /// In en, this message translates to:
  /// **'listen'**
  String get activityListen;

  /// No description provided for @activityMeditation.
  ///
  /// In en, this message translates to:
  /// **'meditation'**
  String get activityMeditation;

  /// No description provided for @activityMediumSleep.
  ///
  /// In en, this message translates to:
  /// **'medium sleep'**
  String get activityMediumSleep;

  /// No description provided for @activityMeeting.
  ///
  /// In en, this message translates to:
  /// **'Meeting'**
  String get activityMeeting;

  /// No description provided for @activityMoviesTv.
  ///
  /// In en, this message translates to:
  /// **'movies & tv'**
  String get activityMoviesTv;

  /// No description provided for @activityOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get activityOther;

  /// No description provided for @activityParty.
  ///
  /// In en, this message translates to:
  /// **'party'**
  String get activityParty;

  /// No description provided for @activityPlanning.
  ///
  /// In en, this message translates to:
  /// **'Planning'**
  String get activityPlanning;

  /// No description provided for @activityReading.
  ///
  /// In en, this message translates to:
  /// **'reading'**
  String get activityReading;

  /// No description provided for @activityRelax.
  ///
  /// In en, this message translates to:
  /// **'relax'**
  String get activityRelax;

  /// No description provided for @activityShopping.
  ///
  /// In en, this message translates to:
  /// **'shopping'**
  String get activityShopping;

  /// No description provided for @activitySleepEarly.
  ///
  /// In en, this message translates to:
  /// **'sleep early'**
  String get activitySleepEarly;

  /// No description provided for @activityStudy.
  ///
  /// In en, this message translates to:
  /// **'Study'**
  String get activityStudy;

  /// No description provided for @activityWalk.
  ///
  /// In en, this message translates to:
  /// **'walk'**
  String get activityWalk;

  /// No description provided for @activityWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get activityWork;

  /// No description provided for @activityWriting.
  ///
  /// In en, this message translates to:
  /// **'Writing'**
  String get activityWriting;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @addBook.
  ///
  /// In en, this message translates to:
  /// **'Add Book'**
  String get addBook;

  /// No description provided for @addBookToStart.
  ///
  /// In en, this message translates to:
  /// **'Add a book to get started'**
  String get addBookToStart;

  /// No description provided for @addCover.
  ///
  /// In en, this message translates to:
  /// **'Add Cover'**
  String get addCover;

  /// No description provided for @addHabitToStart.
  ///
  /// In en, this message translates to:
  /// **'Add a habit to get started'**
  String get addHabitToStart;

  /// No description provided for @addMood.
  ///
  /// In en, this message translates to:
  /// **'Add Mood'**
  String get addMood;

  /// No description provided for @addNote.
  ///
  /// In en, this message translates to:
  /// **'Add Note'**
  String get addNote;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get addPhoto;

  /// No description provided for @addPhrase.
  ///
  /// In en, this message translates to:
  /// **'Add Phrase'**
  String get addPhrase;

  /// No description provided for @addTag.
  ///
  /// In en, this message translates to:
  /// **'Add tag'**
  String get addTag;

  /// No description provided for @addTaskToStart.
  ///
  /// In en, this message translates to:
  /// **'Add a new task to get started'**
  String get addTaskToStart;

  /// No description provided for @addToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Add to Favorites'**
  String get addToFavorites;

  /// No description provided for @addToFavoritesDiary.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get addToFavoritesDiary;

  /// No description provided for @addToFavourites.
  ///
  /// In en, this message translates to:
  /// **'Add to Favourites'**
  String get addToFavourites;

  /// No description provided for @additionalNotes.
  ///
  /// In en, this message translates to:
  /// **'Additional notes (optional)'**
  String get additionalNotes;

  /// No description provided for @adicionarArtigo.
  ///
  /// In en, this message translates to:
  /// **'Add Article'**
  String get adicionarArtigo;

  /// No description provided for @adicionarIdioma.
  ///
  /// In en, this message translates to:
  /// **'Add Language'**
  String get adicionarIdioma;

  /// No description provided for @adicionarTarefa.
  ///
  /// In en, this message translates to:
  /// **'Add Task'**
  String get adicionarTarefa;

  /// No description provided for @adjustFilters.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting the filters'**
  String get adjustFilters;

  /// No description provided for @adjustments.
  ///
  /// In en, this message translates to:
  /// **'Adjustments'**
  String get adjustments;

  /// No description provided for @agenda.
  ///
  /// In en, this message translates to:
  /// **'Agenda'**
  String get agenda;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @all1.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all1;

  /// No description provided for @allUpToDate.
  ///
  /// In en, this message translates to:
  /// **'All up to date! 🎉'**
  String get allUpToDate;

  /// No description provided for @alphabetical.
  ///
  /// In en, this message translates to:
  /// **'Alphabetical order'**
  String get alphabetical;

  /// No description provided for @analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// No description provided for @apagar.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get apagar;

  /// No description provided for @apagarCategoria.
  ///
  /// In en, this message translates to:
  /// **'Delete Category?'**
  String get apagarCategoria;

  /// No description provided for @apagarProjeto.
  ///
  /// In en, this message translates to:
  /// **'Delete Project?'**
  String get apagarProjeto;

  /// No description provided for @aplicar.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get aplicar;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Odyssey'**
  String get appTitle;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @applyTemplate.
  ///
  /// In en, this message translates to:
  /// **'Apply template'**
  String get applyTemplate;

  /// No description provided for @aprendendo.
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get aprendendo;

  /// No description provided for @areasDeDesenvolvimento.
  ///
  /// In en, this message translates to:
  /// **'Development Areas'**
  String get areasDeDesenvolvimento;

  /// No description provided for @articleRemoved.
  ///
  /// In en, this message translates to:
  /// **'Article removed'**
  String get articleRemoved;

  /// No description provided for @articlesAndNews.
  ///
  /// In en, this message translates to:
  /// **'Articles and news'**
  String get articlesAndNews;

  /// No description provided for @assinaturaProMensal.
  ///
  /// In en, this message translates to:
  /// **'Monthly PRO Subscription'**
  String get assinaturaProMensal;

  /// No description provided for @ativar.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get ativar;

  /// No description provided for @ativarTeste.
  ///
  /// In en, this message translates to:
  /// **'Activate Test'**
  String get ativarTeste;

  /// No description provided for @atividadeSemanal.
  ///
  /// In en, this message translates to:
  /// **'Weekly Activity'**
  String get atividadeSemanal;

  /// No description provided for @atualizarProgresso.
  ///
  /// In en, this message translates to:
  /// **'Update Progress'**
  String get atualizarProgresso;

  /// No description provided for @audiobook.
  ///
  /// In en, this message translates to:
  /// **'Audiobook'**
  String get audiobook;

  /// No description provided for @author.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get author;

  /// No description provided for @autoBackup.
  ///
  /// In en, this message translates to:
  /// **'Auto Backup'**
  String get autoBackup;

  /// No description provided for @autoSave.
  ///
  /// In en, this message translates to:
  /// **'Auto-save'**
  String get autoSave;

  /// No description provided for @availableWidgets.
  ///
  /// In en, this message translates to:
  /// **'AVAILABLE ({count})'**
  String availableWidgets(Object count);

  /// No description provided for @average.
  ///
  /// In en, this message translates to:
  /// **'Average: {value}'**
  String average(Object value);

  /// No description provided for @avgPerDay.
  ///
  /// In en, this message translates to:
  /// **'Avg/Day'**
  String get avgPerDay;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @backToFocus.
  ///
  /// In en, this message translates to:
  /// **'Back to focus!'**
  String get backToFocus;

  /// No description provided for @backToPending.
  ///
  /// In en, this message translates to:
  /// **'Back to pending'**
  String get backToPending;

  /// No description provided for @backToTimer.
  ///
  /// In en, this message translates to:
  /// **'Back to timer'**
  String get backToTimer;

  /// No description provided for @backgroundColor.
  ///
  /// In en, this message translates to:
  /// **'Background color'**
  String get backgroundColor;

  /// No description provided for @backup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backup;

  /// No description provided for @backupAndRestore.
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get backupAndRestore;

  /// No description provided for @backupError.
  ///
  /// In en, this message translates to:
  /// **'Backup error'**
  String get backupError;

  /// No description provided for @backupSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup created successfully!'**
  String get backupSuccess;

  /// No description provided for @bestDay.
  ///
  /// In en, this message translates to:
  /// **'Best Day'**
  String get bestDay;

  /// No description provided for @bestExcerpts.
  ///
  /// In en, this message translates to:
  /// **'Best Excerpts'**
  String get bestExcerpts;

  /// No description provided for @bestStreak.
  ///
  /// In en, this message translates to:
  /// **'Best Streak'**
  String get bestStreak;

  /// No description provided for @bestStreakDiary.
  ///
  /// In en, this message translates to:
  /// **'Best Streak'**
  String get bestStreakDiary;

  /// No description provided for @blue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get blue;

  /// No description provided for @bold.
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get bold;

  /// No description provided for @bookAdded.
  ///
  /// In en, this message translates to:
  /// **'Book added!'**
  String get bookAdded;

  /// No description provided for @bookRemoved.
  ///
  /// In en, this message translates to:
  /// **'Book removed'**
  String get bookRemoved;

  /// No description provided for @bookRestored.
  ///
  /// In en, this message translates to:
  /// **'Book restored'**
  String get bookRestored;

  /// No description provided for @bookUpdated.
  ///
  /// In en, this message translates to:
  /// **'Book updated!'**
  String get bookUpdated;

  /// No description provided for @booksAndReading.
  ///
  /// In en, this message translates to:
  /// **'Books and reading'**
  String get booksAndReading;

  /// No description provided for @booksReading.
  ///
  /// In en, this message translates to:
  /// **'{count} reading'**
  String booksReading(Object count);

  /// No description provided for @botao.
  ///
  /// In en, this message translates to:
  /// **'Button'**
  String get botao;

  /// No description provided for @breakTime.
  ///
  /// In en, this message translates to:
  /// **'Break time!'**
  String get breakTime;

  /// No description provided for @breatheDeepDoingWell.
  ///
  /// In en, this message translates to:
  /// **'Breathe deep. You\'re doing well.'**
  String get breatheDeepDoingWell;

  /// No description provided for @bulletJournal.
  ///
  /// In en, this message translates to:
  /// **'Bullet Journal'**
  String get bulletJournal;

  /// No description provided for @buscaEmDesenvolvimento.
  ///
  /// In en, this message translates to:
  /// **'Search in development'**
  String get buscaEmDesenvolvimento;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @calendarView.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendarView;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @cancelar.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelar;

  /// No description provided for @cannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get cannotBeUndone;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @categoryCreated.
  ///
  /// In en, this message translates to:
  /// **'Category \"{name}\" created'**
  String categoryCreated(Object name);

  /// No description provided for @categoryDeleted.
  ///
  /// In en, this message translates to:
  /// **'Category deleted'**
  String get categoryDeleted;

  /// No description provided for @categoryHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get categoryHealth;

  /// No description provided for @categoryHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get categoryHome;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category: {category}'**
  String categoryLabel(Object category);

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Category name...'**
  String get categoryName;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// No description provided for @categoryPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get categoryPersonal;

  /// No description provided for @categoryRenamed.
  ///
  /// In en, this message translates to:
  /// **'Category renamed'**
  String get categoryRenamed;

  /// No description provided for @categoryStudies.
  ///
  /// In en, this message translates to:
  /// **'Studies'**
  String get categoryStudies;

  /// No description provided for @categoryWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get categoryWork;

  /// No description provided for @chartComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get chartComplete;

  /// No description provided for @chartGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get chartGood;

  /// No description provided for @chartMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get chartMissed;

  /// No description provided for @chartPartial.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get chartPartial;

  /// No description provided for @chavePix.
  ///
  /// In en, this message translates to:
  /// **'PIX Key'**
  String get chavePix;

  /// No description provided for @chavePixCopiada.
  ///
  /// In en, this message translates to:
  /// **'✅ PIX Key copied!'**
  String get chavePixCopiada;

  /// No description provided for @checklist.
  ///
  /// In en, this message translates to:
  /// **'Checklist'**
  String get checklist;

  /// No description provided for @chooseCover.
  ///
  /// In en, this message translates to:
  /// **'Choose Cover'**
  String get chooseCover;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @chooseTemplate.
  ///
  /// In en, this message translates to:
  /// **'Choose a template'**
  String get chooseTemplate;

  /// No description provided for @chooseTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a title'**
  String get chooseTitle;

  /// No description provided for @chooseYourMood.
  ///
  /// In en, this message translates to:
  /// **'Choose your current mood'**
  String get chooseYourMood;

  /// No description provided for @citacaoDoDia.
  ///
  /// In en, this message translates to:
  /// **'Quote of the Day'**
  String get citacaoDoDia;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @closeKeyboard.
  ///
  /// In en, this message translates to:
  /// **'Close keyboard'**
  String get closeKeyboard;

  /// No description provided for @code.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get code;

  /// No description provided for @compartilhar.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get compartilhar;

  /// No description provided for @completeAction.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get completeAction;

  /// No description provided for @completeEsteDesafioNaTelaCorrespondente.
  ///
  /// In en, this message translates to:
  /// **'Complete this challenge on the corresponding screen!'**
  String get completeEsteDesafioNaTelaCorrespondente;

  /// No description provided for @completeTasksToSee.
  ///
  /// In en, this message translates to:
  /// **'Complete your tasks to see them here'**
  String get completeTasksToSee;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @completedItems.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedItems;

  /// No description provided for @completionRate.
  ///
  /// In en, this message translates to:
  /// **'Completion\nRate'**
  String get completionRate;

  /// No description provided for @compraProVitalicio.
  ///
  /// In en, this message translates to:
  /// **'Lifetime PRO Purchase'**
  String get compraProVitalicio;

  /// No description provided for @concentrationSounds.
  ///
  /// In en, this message translates to:
  /// **'Concentration Sounds'**
  String get concentrationSounds;

  /// No description provided for @configurar.
  ///
  /// In en, this message translates to:
  /// **'Configure'**
  String get configurar;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @confirmDeleteBook.
  ///
  /// In en, this message translates to:
  /// **'Do you want to delete \"{title}\" from your library?'**
  String confirmDeleteBook(Object title);

  /// No description provided for @confirmDeleteCategory.
  ///
  /// In en, this message translates to:
  /// **'Do you want to delete the category \"{name}\"?'**
  String confirmDeleteCategory(Object name);

  /// No description provided for @confirmDeleteHabit.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String confirmDeleteHabit(Object name);

  /// No description provided for @confirmDeleteItem.
  ///
  /// In en, this message translates to:
  /// **'Do you want to delete'**
  String get confirmDeleteItem;

  /// No description provided for @confirmDeleteSure.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete'**
  String get confirmDeleteSure;

  /// No description provided for @confirmDeleteTask.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{title}\"?'**
  String confirmDeleteTask(Object title);

  /// No description provided for @congratulations.
  ///
  /// In en, this message translates to:
  /// **'Congratulations!'**
  String get congratulations;

  /// No description provided for @conquistasDesbloqueadas.
  ///
  /// In en, this message translates to:
  /// **'achievements unlocked'**
  String get conquistasDesbloqueadas;

  /// No description provided for @consecutiveDays.
  ///
  /// In en, this message translates to:
  /// **'Consecutive days'**
  String get consecutiveDays;

  /// No description provided for @considerLongerBreak.
  ///
  /// In en, this message translates to:
  /// **'Consider taking a longer break to recharge'**
  String get considerLongerBreak;

  /// No description provided for @consistent.
  ///
  /// In en, this message translates to:
  /// **'Consistent'**
  String get consistent;

  /// No description provided for @continuar.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continuar;

  /// No description provided for @continueEditing.
  ///
  /// In en, this message translates to:
  /// **'Continue editing'**
  String get continueEditing;

  /// No description provided for @continueInBackground.
  ///
  /// In en, this message translates to:
  /// **'Continue in background'**
  String get continueInBackground;

  /// No description provided for @continue_.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continue_;

  /// No description provided for @copiarToken.
  ///
  /// In en, this message translates to:
  /// **'Copy Token'**
  String get copiarToken;

  /// No description provided for @copieAChaveAbaixoParaFazerATransferencia.
  ///
  /// In en, this message translates to:
  /// **'Copy the key below to make the transfer'**
  String get copieAChaveAbaixoParaFazerATransferencia;

  /// No description provided for @cor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get cor;

  /// No description provided for @couldNotConnect.
  ///
  /// In en, this message translates to:
  /// **'Could not connect'**
  String get couldNotConnect;

  /// No description provided for @createBackup.
  ///
  /// In en, this message translates to:
  /// **'Create Backup'**
  String get createBackup;

  /// No description provided for @createFirstEntry.
  ///
  /// In en, this message translates to:
  /// **'Create first entry'**
  String get createFirstEntry;

  /// No description provided for @createHabit.
  ///
  /// In en, this message translates to:
  /// **'Create Habit'**
  String get createHabit;

  /// No description provided for @createTask.
  ///
  /// In en, this message translates to:
  /// **'Create Task'**
  String get createTask;

  /// No description provided for @createdOn.
  ///
  /// In en, this message translates to:
  /// **'Created on'**
  String get createdOn;

  /// No description provided for @criar.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get criar;

  /// No description provided for @currentPage.
  ///
  /// In en, this message translates to:
  /// **'Current Page'**
  String get currentPage;

  /// No description provided for @currentStreakDiary.
  ///
  /// In en, this message translates to:
  /// **'Current Streak'**
  String get currentStreakDiary;

  /// No description provided for @customize.
  ///
  /// In en, this message translates to:
  /// **'Customize'**
  String get customize;

  /// No description provided for @dadosBaixadosComSucesso.
  ///
  /// In en, this message translates to:
  /// **'Data downloaded successfully!'**
  String get dadosBaixadosComSucesso;

  /// No description provided for @dadosDaNuvemRemovidos.
  ///
  /// In en, this message translates to:
  /// **'Cloud data removed!'**
  String get dadosDaNuvemRemovidos;

  /// No description provided for @dadosEnviadosComSucesso.
  ///
  /// In en, this message translates to:
  /// **'Data sent successfully!'**
  String get dadosEnviadosComSucesso;

  /// No description provided for @dadosLimposComSucesso.
  ///
  /// In en, this message translates to:
  /// **'Data cleared successfully'**
  String get dadosLimposComSucesso;

  /// No description provided for @dailyGoal.
  ///
  /// In en, this message translates to:
  /// **'Daily Goal'**
  String get dailyGoal;

  /// No description provided for @dailyGoals.
  ///
  /// In en, this message translates to:
  /// **'Daily Goals'**
  String get dailyGoals;

  /// No description provided for @dailyRecords.
  ///
  /// In en, this message translates to:
  /// **'Daily records'**
  String get dailyRecords;

  /// No description provided for @dailyReminders.
  ///
  /// In en, this message translates to:
  /// **'Daily Reminders'**
  String get dailyReminders;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @dayBeforeShort.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get dayBeforeShort;

  /// No description provided for @daySummary.
  ///
  /// In en, this message translates to:
  /// **'Day Summary'**
  String get daySummary;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @daysAnalyzed.
  ///
  /// In en, this message translates to:
  /// **'{days} days analyzed'**
  String daysAnalyzed(Object days);

  /// No description provided for @daysUnit.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get daysUnit;

  /// No description provided for @dedicatedMoreTimeTo.
  ///
  /// In en, this message translates to:
  /// **'You\'ve been dedicating more time to \"{activity}\" with {count} sessions.'**
  String dedicatedMoreTimeTo(Object activity, Object count);

  /// No description provided for @defaultColor.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultColor;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteEntry.
  ///
  /// In en, this message translates to:
  /// **'Delete entry'**
  String get deleteEntry;

  /// No description provided for @deleteEntryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this entry?'**
  String get deleteEntryConfirm;

  /// No description provided for @deleteNote.
  ///
  /// In en, this message translates to:
  /// **'Delete note?'**
  String get deleteNote;

  /// No description provided for @deleteNoteMessage.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get deleteNoteMessage;

  /// No description provided for @desconectar.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get desconectar;

  /// No description provided for @desejaApagarACategoria.
  ///
  /// In en, this message translates to:
  /// **'Do you want to delete the category '**
  String get desejaApagarACategoria;

  /// No description provided for @desejaContinuar.
  ///
  /// In en, this message translates to:
  /// **'Do you want to continue?'**
  String get desejaContinuar;

  /// No description provided for @desejaExcluir.
  ///
  /// In en, this message translates to:
  /// **'Do you want to delete '**
  String get desejaExcluir;

  /// No description provided for @desejaSairDaContaGoogle.
  ///
  /// In en, this message translates to:
  /// **'Do you want to sign out of Google?'**
  String get desejaSairDaContaGoogle;

  /// No description provided for @detailedStatistics.
  ///
  /// In en, this message translates to:
  /// **'Detailed statistics'**
  String get detailedStatistics;

  /// No description provided for @detalhes.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get detalhes;

  /// No description provided for @development.
  ///
  /// In en, this message translates to:
  /// **'Development'**
  String get development;

  /// No description provided for @diary.
  ///
  /// In en, this message translates to:
  /// **'Diary'**
  String get diary;

  /// No description provided for @diaryAchievementDedicatedWriter.
  ///
  /// In en, this message translates to:
  /// **'Dedicated Writer'**
  String get diaryAchievementDedicatedWriter;

  /// No description provided for @diaryAchievementFirstEntry.
  ///
  /// In en, this message translates to:
  /// **'First Diary'**
  String get diaryAchievementFirstEntry;

  /// No description provided for @diaryAchievementHistorian.
  ///
  /// In en, this message translates to:
  /// **'Historian'**
  String get diaryAchievementHistorian;

  /// No description provided for @diaryAchievementMarathon.
  ///
  /// In en, this message translates to:
  /// **'Marathon Writer'**
  String get diaryAchievementMarathon;

  /// No description provided for @diaryAchievementMonthStreak.
  ///
  /// In en, this message translates to:
  /// **'Monthly Commitment'**
  String get diaryAchievementMonthStreak;

  /// No description provided for @diaryAchievementPhotographer.
  ///
  /// In en, this message translates to:
  /// **'Photographer'**
  String get diaryAchievementPhotographer;

  /// No description provided for @diaryAchievementReflective.
  ///
  /// In en, this message translates to:
  /// **'Reflective'**
  String get diaryAchievementReflective;

  /// No description provided for @diaryAchievementVividMemories.
  ///
  /// In en, this message translates to:
  /// **'Vivid Memories'**
  String get diaryAchievementVividMemories;

  /// No description provided for @diaryAchievementWordMaster.
  ///
  /// In en, this message translates to:
  /// **'Word Master'**
  String get diaryAchievementWordMaster;

  /// No description provided for @diaryAchievementYearWriter.
  ///
  /// In en, this message translates to:
  /// **'A Year of Memories'**
  String get diaryAchievementYearWriter;

  /// No description provided for @diaryAverageWords.
  ///
  /// In en, this message translates to:
  /// **'Average Words'**
  String get diaryAverageWords;

  /// No description provided for @diaryConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get diaryConfiguration;

  /// No description provided for @diaryConfirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this entry?'**
  String get diaryConfirmDelete;

  /// No description provided for @diaryDeleteCannotUndo.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get diaryDeleteCannotUndo;

  /// No description provided for @diaryDiscardChanges.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get diaryDiscardChanges;

  /// No description provided for @diaryDiscardChangesMessage.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Do you want to discard them?'**
  String get diaryDiscardChangesMessage;

  /// No description provided for @diaryEditorContentPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Write your thoughts...'**
  String get diaryEditorContentPlaceholder;

  /// No description provided for @diaryEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'Title (optional)'**
  String get diaryEditorTitle;

  /// No description provided for @diaryEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Start writing your first entry!'**
  String get diaryEmptyMessage;

  /// No description provided for @diaryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your diary is empty'**
  String get diaryEmptyTitle;

  /// No description provided for @diaryEntry.
  ///
  /// In en, this message translates to:
  /// **'Diary Entry'**
  String get diaryEntry;

  /// No description provided for @diaryEntryDeleted.
  ///
  /// In en, this message translates to:
  /// **'Entry deleted'**
  String get diaryEntryDeleted;

  /// No description provided for @diaryEntrySaved.
  ///
  /// In en, this message translates to:
  /// **'Entry saved!'**
  String get diaryEntrySaved;

  /// No description provided for @diaryExport.
  ///
  /// In en, this message translates to:
  /// **'Export Diary'**
  String get diaryExport;

  /// No description provided for @diaryExportReadableFormat.
  ///
  /// In en, this message translates to:
  /// **'Readable format for text'**
  String get diaryExportReadableFormat;

  /// No description provided for @diaryFeelingDistribution.
  ///
  /// In en, this message translates to:
  /// **'Feeling Distribution'**
  String get diaryFeelingDistribution;

  /// No description provided for @diaryHowAreYouFeeling.
  ///
  /// In en, this message translates to:
  /// **'How are you feeling?'**
  String get diaryHowAreYouFeeling;

  /// No description provided for @diaryInsights.
  ///
  /// In en, this message translates to:
  /// **'Diary Insights'**
  String get diaryInsights;

  /// No description provided for @diaryInsightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get diaryInsightsTitle;

  /// No description provided for @diaryLock.
  ///
  /// In en, this message translates to:
  /// **'Lock Diary'**
  String get diaryLock;

  /// No description provided for @diaryMyDiary.
  ///
  /// In en, this message translates to:
  /// **'My Diary'**
  String get diaryMyDiary;

  /// No description provided for @diaryOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get diaryOverview;

  /// No description provided for @diaryReminder.
  ///
  /// In en, this message translates to:
  /// **'Diary Reminder'**
  String get diaryReminder;

  /// No description provided for @diarySearchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search in Diary'**
  String get diarySearchPlaceholder;

  /// No description provided for @diarySelectFeeling.
  ///
  /// In en, this message translates to:
  /// **'Select your feeling'**
  String get diarySelectFeeling;

  /// No description provided for @diarySettings.
  ///
  /// In en, this message translates to:
  /// **'Diary Settings'**
  String get diarySettings;

  /// No description provided for @diarySortAlphabetical.
  ///
  /// In en, this message translates to:
  /// **'Alphabetical order'**
  String get diarySortAlphabetical;

  /// No description provided for @diarySortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get diarySortNewest;

  /// No description provided for @diarySortOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest first'**
  String get diarySortOldest;

  /// No description provided for @diaryStartWriting.
  ///
  /// In en, this message translates to:
  /// **'Tap to start writing'**
  String get diaryStartWriting;

  /// No description provided for @diaryStatistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get diaryStatistics;

  /// No description provided for @diaryStats.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get diaryStats;

  /// No description provided for @diaryTips.
  ///
  /// In en, this message translates to:
  /// **'Tips to get started'**
  String get diaryTips;

  /// No description provided for @diaryTipsToStart.
  ///
  /// In en, this message translates to:
  /// **'💡 Tips to get started'**
  String get diaryTipsToStart;

  /// No description provided for @diaryViewCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get diaryViewCalendar;

  /// No description provided for @diaryViewGrid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get diaryViewGrid;

  /// No description provided for @diaryViewList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get diaryViewList;

  /// No description provided for @diaryWritingFrequency.
  ///
  /// In en, this message translates to:
  /// **'Writing Frequency'**
  String get diaryWritingFrequency;

  /// No description provided for @difficultDays.
  ///
  /// In en, this message translates to:
  /// **'Difficult days'**
  String get difficultDays;

  /// No description provided for @dificil.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get dificil;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @discardChanges.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get discardChanges;

  /// No description provided for @discardChangesMessage.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Do you want to discard them?'**
  String get discardChangesMessage;

  /// No description provided for @discoverArticles.
  ///
  /// In en, this message translates to:
  /// **'Discover articles'**
  String get discoverArticles;

  /// No description provided for @diversifyActivities.
  ///
  /// In en, this message translates to:
  /// **'Diversify your activities for balanced development'**
  String get diversifyActivities;

  /// No description provided for @dominadas.
  ///
  /// In en, this message translates to:
  /// **'Mastered'**
  String get dominadas;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @dragToReorder.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder. Activate or deactivate widgets.'**
  String get dragToReorder;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get dueDate;

  /// No description provided for @dueTime.
  ///
  /// In en, this message translates to:
  /// **'Due Time'**
  String get dueTime;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration: {duration}'**
  String duration(Object duration);

  /// No description provided for @durationLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration:'**
  String get durationLabel;

  /// No description provided for @e.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get e;

  /// No description provided for @ebook.
  ///
  /// In en, this message translates to:
  /// **'E-book'**
  String get ebook;

  /// No description provided for @edicaoEmBreve.
  ///
  /// In en, this message translates to:
  /// **'Editing coming soon!'**
  String get edicaoEmBreve;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @edit1.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit1;

  /// No description provided for @editBook.
  ///
  /// In en, this message translates to:
  /// **'Edit Book'**
  String get editBook;

  /// No description provided for @editEntry.
  ///
  /// In en, this message translates to:
  /// **'Edit entry'**
  String get editEntry;

  /// No description provided for @editHabit.
  ///
  /// In en, this message translates to:
  /// **'Edit Habit'**
  String get editHabit;

  /// No description provided for @editNote.
  ///
  /// In en, this message translates to:
  /// **'Edit Note'**
  String get editNote;

  /// No description provided for @editTask.
  ///
  /// In en, this message translates to:
  /// **'Edit Task'**
  String get editTask;

  /// No description provided for @editar.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editar;

  /// No description provided for @editarCategoria.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get editarCategoria;

  /// No description provided for @editarPerfil.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editarPerfil;

  /// No description provided for @editarPerfil1.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editarPerfil1;

  /// No description provided for @editarProjeto.
  ///
  /// In en, this message translates to:
  /// **'Edit Project'**
  String get editarProjeto;

  /// No description provided for @editarRegistro.
  ///
  /// In en, this message translates to:
  /// **'Edit record'**
  String get editarRegistro;

  /// No description provided for @elapsed.
  ///
  /// In en, this message translates to:
  /// **'elapsed'**
  String get elapsed;

  /// No description provided for @emailReenviado.
  ///
  /// In en, this message translates to:
  /// **'Email resent!'**
  String get emailReenviado;

  /// No description provided for @emailReenviadoComSucesso.
  ///
  /// In en, this message translates to:
  /// **'Email resent successfully!'**
  String get emailReenviadoComSucesso;

  /// No description provided for @emotionalJourney.
  ///
  /// In en, this message translates to:
  /// **'Your emotional journey'**
  String get emotionalJourney;

  /// No description provided for @encerrar.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get encerrar;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// No description provided for @endDayReview.
  ///
  /// In en, this message translates to:
  /// **'End of day! Review your achievements.'**
  String get endDayReview;

  /// No description provided for @endSession.
  ///
  /// In en, this message translates to:
  /// **'End session'**
  String get endSession;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @enterAuthorName.
  ///
  /// In en, this message translates to:
  /// **'Enter author name'**
  String get enterAuthorName;

  /// No description provided for @enterBookTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter book title'**
  String get enterBookTitle;

  /// No description provided for @enterTaskName.
  ///
  /// In en, this message translates to:
  /// **'Enter a task name'**
  String get enterTaskName;

  /// No description provided for @enterTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter a title'**
  String get enterTitle;

  /// No description provided for @entrar.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get entrar;

  /// No description provided for @entriesFromPreviousYears.
  ///
  /// In en, this message translates to:
  /// **'Entries from previous years'**
  String get entriesFromPreviousYears;

  /// No description provided for @entriesThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Entries this month'**
  String get entriesThisMonth;

  /// No description provided for @entriesThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get entriesThisWeek;

  /// No description provided for @entryDate.
  ///
  /// In en, this message translates to:
  /// **'Entry Date'**
  String get entryDate;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Error:'**
  String get errorGeneric;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get errorOccurred;

  /// No description provided for @errorSaving.
  ///
  /// In en, this message translates to:
  /// **'Error saving: {error}'**
  String errorSaving(Object error);

  /// No description provided for @escolherTema.
  ///
  /// In en, this message translates to:
  /// **'Choose Theme'**
  String get escolherTema;

  /// No description provided for @estaAcaoIraApagarTodosOsSeusRegistrosPer.
  ///
  /// In en, this message translates to:
  /// **'This action will permanently delete all your records.'**
  String get estaAcaoIraApagarTodosOsSeusRegistrosPer;

  /// No description provided for @estaFuncionalidadeSeraIntegradaComALojaD.
  ///
  /// In en, this message translates to:
  /// **'This feature will be integrated with the app store. For now, you can activate test mode.'**
  String get estaFuncionalidadeSeraIntegradaComALojaD;

  /// No description provided for @estatisticasDeLeitura.
  ///
  /// In en, this message translates to:
  /// **'Reading Statistics'**
  String get estatisticasDeLeitura;

  /// No description provided for @estudar.
  ///
  /// In en, this message translates to:
  /// **'Estudar'**
  String get estudar;

  /// No description provided for @everyDay.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get everyDay;

  /// No description provided for @everyMinuteCloserToGoals.
  ///
  /// In en, this message translates to:
  /// **'Every minute of focus brings you closer to your goals.'**
  String get everyMinuteCloserToGoals;

  /// No description provided for @excluirFrase.
  ///
  /// In en, this message translates to:
  /// **'Delete quote?'**
  String get excluirFrase;

  /// No description provided for @excluirHabito.
  ///
  /// In en, this message translates to:
  /// **'Delete habit?'**
  String get excluirHabito;

  /// No description provided for @excluirLivro.
  ///
  /// In en, this message translates to:
  /// **'Delete Book?'**
  String get excluirLivro;

  /// No description provided for @excluirProjeto.
  ///
  /// In en, this message translates to:
  /// **'Delete project'**
  String get excluirProjeto;

  /// No description provided for @excluirTarefa.
  ///
  /// In en, this message translates to:
  /// **'Delete task?'**
  String get excluirTarefa;

  /// No description provided for @experience.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get experience;

  /// No description provided for @explorarSugestoes.
  ///
  /// In en, this message translates to:
  /// **'Explore Suggestions'**
  String get explorarSugestoes;

  /// No description provided for @explorer.
  ///
  /// In en, this message translates to:
  /// **'Explorer'**
  String get explorer;

  /// No description provided for @exportAsJson.
  ///
  /// In en, this message translates to:
  /// **'Export as JSON'**
  String get exportAsJson;

  /// No description provided for @exportAsMarkdown.
  ///
  /// In en, this message translates to:
  /// **'Export as Markdown'**
  String get exportAsMarkdown;

  /// No description provided for @exportAsText.
  ///
  /// In en, this message translates to:
  /// **'Export as Text'**
  String get exportAsText;

  /// No description provided for @exportDiary.
  ///
  /// In en, this message translates to:
  /// **'Export diary'**
  String get exportDiary;

  /// No description provided for @exportJson.
  ///
  /// In en, this message translates to:
  /// **'Export JSON'**
  String get exportJson;

  /// No description provided for @exportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Exported successfully!'**
  String get exportSuccess;

  /// No description provided for @facebookLoginSoon.
  ///
  /// In en, this message translates to:
  /// **'Facebook login coming soon! Use Google or enter as guest.'**
  String get facebookLoginSoon;

  /// No description provided for @facil.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get facil;

  /// No description provided for @falling.
  ///
  /// In en, this message translates to:
  /// **'Falling'**
  String get falling;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @fcmTokenDebug.
  ///
  /// In en, this message translates to:
  /// **'FCM Token Debug'**
  String get fcmTokenDebug;

  /// No description provided for @feeling.
  ///
  /// In en, this message translates to:
  /// **'Feeling'**
  String get feeling;

  /// No description provided for @feelingDistribution.
  ///
  /// In en, this message translates to:
  /// **'Feeling Distribution'**
  String get feelingDistribution;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @filterByDate.
  ///
  /// In en, this message translates to:
  /// **'Filter by date'**
  String get filterByDate;

  /// No description provided for @filterByFeeling.
  ///
  /// In en, this message translates to:
  /// **'Filter by feeling'**
  String get filterByFeeling;

  /// No description provided for @filterByTag.
  ///
  /// In en, this message translates to:
  /// **'Filter by tag'**
  String get filterByTag;

  /// No description provided for @filtrarPorEsteProjeto.
  ///
  /// In en, this message translates to:
  /// **'Filter by this project'**
  String get filtrarPorEsteProjeto;

  /// No description provided for @findOnOpenLibrary.
  ///
  /// In en, this message translates to:
  /// **'Find cover on Open Library'**
  String get findOnOpenLibrary;

  /// No description provided for @focus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get focus;

  /// No description provided for @focusGoal.
  ///
  /// In en, this message translates to:
  /// **'Focus Goal'**
  String get focusGoal;

  /// No description provided for @focusMaster.
  ///
  /// In en, this message translates to:
  /// **'Focus Master'**
  String get focusMaster;

  /// No description provided for @focusSession.
  ///
  /// In en, this message translates to:
  /// **'Focus Session'**
  String get focusSession;

  /// No description provided for @focusSessions.
  ///
  /// In en, this message translates to:
  /// **'Focus Sessions'**
  String get focusSessions;

  /// No description provided for @focusTime.
  ///
  /// In en, this message translates to:
  /// **'Focus Time'**
  String get focusTime;

  /// No description provided for @focusTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Focus Time'**
  String get focusTimeLabel;

  /// No description provided for @followSystemLanguage.
  ///
  /// In en, this message translates to:
  /// **'Follow system language'**
  String get followSystemLanguage;

  /// No description provided for @format.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get format;

  /// No description provided for @fraseDoDia.
  ///
  /// In en, this message translates to:
  /// **'Quote of the Day'**
  String get fraseDoDia;

  /// No description provided for @fraseSalvaComSucesso.
  ///
  /// In en, this message translates to:
  /// **'Quote saved successfully!'**
  String get fraseSalvaComSucesso;

  /// No description provided for @freeJournal.
  ///
  /// In en, this message translates to:
  /// **'Free Journal'**
  String get freeJournal;

  /// No description provided for @freeTimer.
  ///
  /// In en, this message translates to:
  /// **'Free Timer'**
  String get freeTimer;

  /// No description provided for @fridayFull.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get fridayFull;

  /// No description provided for @fridayShort.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get fridayShort;

  /// No description provided for @galeria.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get galeria;

  /// No description provided for @gamification.
  ///
  /// In en, this message translates to:
  /// **'Gamification'**
  String get gamification;

  /// No description provided for @generoPersonalizado.
  ///
  /// In en, this message translates to:
  /// **'Custom Genre'**
  String get generoPersonalizado;

  /// No description provided for @genre.
  ///
  /// In en, this message translates to:
  /// **'Genre'**
  String get genre;

  /// No description provided for @genreArt.
  ///
  /// In en, this message translates to:
  /// **'Art'**
  String get genreArt;

  /// No description provided for @genreBiography.
  ///
  /// In en, this message translates to:
  /// **'Biography'**
  String get genreBiography;

  /// No description provided for @genreBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get genreBusiness;

  /// No description provided for @genreChildren.
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get genreChildren;

  /// No description provided for @genreComics.
  ///
  /// In en, this message translates to:
  /// **'Comics/Manga'**
  String get genreComics;

  /// No description provided for @genreCooking.
  ///
  /// In en, this message translates to:
  /// **'Cooking'**
  String get genreCooking;

  /// No description provided for @genreFantasy.
  ///
  /// In en, this message translates to:
  /// **'Fantasy'**
  String get genreFantasy;

  /// No description provided for @genreFiction.
  ///
  /// In en, this message translates to:
  /// **'Fiction'**
  String get genreFiction;

  /// No description provided for @genreHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get genreHistory;

  /// No description provided for @genreHorror.
  ///
  /// In en, this message translates to:
  /// **'Horror'**
  String get genreHorror;

  /// No description provided for @genreMystery.
  ///
  /// In en, this message translates to:
  /// **'Mystery'**
  String get genreMystery;

  /// No description provided for @genreNonFiction.
  ///
  /// In en, this message translates to:
  /// **'Non-Fiction'**
  String get genreNonFiction;

  /// No description provided for @genreOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get genreOther;

  /// No description provided for @genrePhilosophy.
  ///
  /// In en, this message translates to:
  /// **'Philosophy'**
  String get genrePhilosophy;

  /// No description provided for @genrePoetry.
  ///
  /// In en, this message translates to:
  /// **'Poetry'**
  String get genrePoetry;

  /// No description provided for @genrePsychology.
  ///
  /// In en, this message translates to:
  /// **'Psychology'**
  String get genrePsychology;

  /// No description provided for @genreReligion.
  ///
  /// In en, this message translates to:
  /// **'Religion'**
  String get genreReligion;

  /// No description provided for @genreRomance.
  ///
  /// In en, this message translates to:
  /// **'Romance'**
  String get genreRomance;

  /// No description provided for @genreSciFi.
  ///
  /// In en, this message translates to:
  /// **'Science Fiction'**
  String get genreSciFi;

  /// No description provided for @genreScience.
  ///
  /// In en, this message translates to:
  /// **'Science'**
  String get genreScience;

  /// No description provided for @genreSelfHelp.
  ///
  /// In en, this message translates to:
  /// **'Self-Help'**
  String get genreSelfHelp;

  /// No description provided for @genreTechnology.
  ///
  /// In en, this message translates to:
  /// **'Technology'**
  String get genreTechnology;

  /// No description provided for @genreThriller.
  ///
  /// In en, this message translates to:
  /// **'Thriller'**
  String get genreThriller;

  /// No description provided for @genreTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get genreTravel;

  /// No description provided for @genreYoungAdult.
  ///
  /// In en, this message translates to:
  /// **'Young Adult'**
  String get genreYoungAdult;

  /// No description provided for @goPro.
  ///
  /// In en, this message translates to:
  /// **'Go PRO'**
  String get goPro;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEvening;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorning;

  /// No description provided for @goodMorningEnergy.
  ///
  /// In en, this message translates to:
  /// **'Good morning! Start with energy 💪'**
  String get goodMorningEnergy;

  /// No description provided for @goodProgress.
  ///
  /// In en, this message translates to:
  /// **'Good progress'**
  String get goodProgress;

  /// No description provided for @googleDriveBackup.
  ///
  /// In en, this message translates to:
  /// **'Google Drive Backup'**
  String get googleDriveBackup;

  /// No description provided for @gratitudeJournal.
  ///
  /// In en, this message translates to:
  /// **'Gratitude'**
  String get gratitudeJournal;

  /// No description provided for @gray.
  ///
  /// In en, this message translates to:
  /// **'Gray'**
  String get gray;

  /// No description provided for @greatJob.
  ///
  /// In en, this message translates to:
  /// **'Great job!'**
  String get greatJob;

  /// No description provided for @green.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get green;

  /// No description provided for @gridView.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get gridView;

  /// No description provided for @habilidades.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get habilidades;

  /// No description provided for @habitCreated.
  ///
  /// In en, this message translates to:
  /// **'Habit \"{name}\" created!'**
  String habitCreated(Object name);

  /// No description provided for @habitDeleted.
  ///
  /// In en, this message translates to:
  /// **'Habit deleted'**
  String get habitDeleted;

  /// No description provided for @habitLabel.
  ///
  /// In en, this message translates to:
  /// **'Habit'**
  String get habitLabel;

  /// No description provided for @habitNameExample.
  ///
  /// In en, this message translates to:
  /// **'E.g.: Read a book'**
  String get habitNameExample;

  /// No description provided for @habitOptions.
  ///
  /// In en, this message translates to:
  /// **'Habit options'**
  String get habitOptions;

  /// No description provided for @habitRemoved.
  ///
  /// In en, this message translates to:
  /// **'Habit removed'**
  String get habitRemoved;

  /// No description provided for @habitSkipped.
  ///
  /// In en, this message translates to:
  /// **'Habit skipped for today'**
  String get habitSkipped;

  /// No description provided for @habitos.
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get habitos;

  /// No description provided for @habitosDoDia.
  ///
  /// In en, this message translates to:
  /// **'Daily Habits'**
  String get habitosDoDia;

  /// No description provided for @habits.
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get habits;

  /// No description provided for @habitsPending.
  ///
  /// In en, this message translates to:
  /// **'habits pending'**
  String get habitsPending;

  /// No description provided for @happyDays.
  ///
  /// In en, this message translates to:
  /// **'Happy days'**
  String get happyDays;

  /// No description provided for @haptics.
  ///
  /// In en, this message translates to:
  /// **'Haptics'**
  String get haptics;

  /// No description provided for @hardcover.
  ///
  /// In en, this message translates to:
  /// **'Hardcover'**
  String get hardcover;

  /// No description provided for @hideCompleted.
  ///
  /// In en, this message translates to:
  /// **'Hide completed'**
  String get hideCompleted;

  /// No description provided for @hideCompletedHabits.
  ///
  /// In en, this message translates to:
  /// **'Hide completed'**
  String get hideCompletedHabits;

  /// No description provided for @hideCompletedTasks.
  ///
  /// In en, this message translates to:
  /// **'Hide completed'**
  String get hideCompletedTasks;

  /// No description provided for @hierarquiaDeMaslow.
  ///
  /// In en, this message translates to:
  /// **'Maslow\'s Hierarchy'**
  String get hierarquiaDeMaslow;

  /// No description provided for @highlight.
  ///
  /// In en, this message translates to:
  /// **'Highlight'**
  String get highlight;

  /// No description provided for @highlightColor.
  ///
  /// In en, this message translates to:
  /// **'Highlight color'**
  String get highlightColor;

  /// No description provided for @highlightHabit.
  ///
  /// In en, this message translates to:
  /// **'Highlight: {name}'**
  String highlightHabit(Object name);

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @horarioOpcional.
  ///
  /// In en, this message translates to:
  /// **'Time (optional)'**
  String get horarioOpcional;

  /// No description provided for @horarios.
  ///
  /// In en, this message translates to:
  /// **'Schedules'**
  String get horarios;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get hours;

  /// No description provided for @howAboutQuickWalk.
  ///
  /// In en, this message translates to:
  /// **'How about a quick walk?'**
  String get howAboutQuickWalk;

  /// No description provided for @howAreYouFeeling.
  ///
  /// In en, this message translates to:
  /// **'How are you feeling?'**
  String get howAreYouFeeling;

  /// No description provided for @howAreYouFeelingToday.
  ///
  /// In en, this message translates to:
  /// **'How are you feeling?'**
  String get howAreYouFeelingToday;

  /// No description provided for @howWasYourDay.
  ///
  /// In en, this message translates to:
  /// **'How was your day? Record your thoughts.'**
  String get howWasYourDay;

  /// No description provided for @icone.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get icone;

  /// No description provided for @idiomaNaoEncontrado.
  ///
  /// In en, this message translates to:
  /// **'Language not found'**
  String get idiomaNaoEncontrado;

  /// No description provided for @importError.
  ///
  /// In en, this message translates to:
  /// **'Error importing backup'**
  String get importError;

  /// No description provided for @importJson.
  ///
  /// In en, this message translates to:
  /// **'Import JSON'**
  String get importJson;

  /// No description provided for @importar.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importar;

  /// No description provided for @importarBackup.
  ///
  /// In en, this message translates to:
  /// **'Import Backup'**
  String get importarBackup;

  /// No description provided for @inBackground.
  ///
  /// In en, this message translates to:
  /// **'in background'**
  String get inBackground;

  /// No description provided for @inDays.
  ///
  /// In en, this message translates to:
  /// **'In {days} days'**
  String inDays(Object days);

  /// No description provided for @iniciarTimer.
  ///
  /// In en, this message translates to:
  /// **'Start Timer'**
  String get iniciarTimer;

  /// No description provided for @insightAmazingStreak.
  ///
  /// In en, this message translates to:
  /// **'Amazing! {habitName} is on a {days}-day streak!'**
  String insightAmazingStreak(Object days, Object habitName);

  /// No description provided for @insightExcellentConsistency.
  ///
  /// In en, this message translates to:
  /// **'You were consistent on {days} of the last 7 days. Excellent!'**
  String insightExcellentConsistency(Object days);

  /// No description provided for @insightGoodConsistency.
  ///
  /// In en, this message translates to:
  /// **'Good consistency! Active on {days} days this week.'**
  String insightGoodConsistency(Object days);

  /// No description provided for @insightKeepGoing.
  ///
  /// In en, this message translates to:
  /// **'Keep going! Every small step counts on your journey.'**
  String get insightKeepGoing;

  /// No description provided for @insightMorningHabits.
  ///
  /// In en, this message translates to:
  /// **'You have {count} morning habit(s). Great for productivity!'**
  String insightMorningHabits(Object count);

  /// No description provided for @insightOfDay.
  ///
  /// In en, this message translates to:
  /// **'Insight of the Day'**
  String get insightOfDay;

  /// No description provided for @insightOnFire.
  ///
  /// In en, this message translates to:
  /// **'{habitName} is on fire with {days} consecutive days!'**
  String insightOnFire(Object days, Object habitName);

  /// No description provided for @insightStartSmall.
  ///
  /// In en, this message translates to:
  /// **'Tip: Start with just 1 habit per day to build momentum.'**
  String get insightStartSmall;

  /// No description provided for @insights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get insights;

  /// No description provided for @inspiradoEmMaslow.
  ///
  /// In en, this message translates to:
  /// **'— Inspired by Maslow'**
  String get inspiradoEmMaslow;

  /// No description provided for @isbn.
  ///
  /// In en, this message translates to:
  /// **'ISBN'**
  String get isbn;

  /// No description provided for @italic.
  ///
  /// In en, this message translates to:
  /// **'Italic'**
  String get italic;

  /// No description provided for @jaTemUmaConta.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get jaTemUmaConta;

  /// No description provided for @keepItUp.
  ///
  /// In en, this message translates to:
  /// **'Keep it up!'**
  String get keepItUp;

  /// No description provided for @keepRhythmTakeBrakes.
  ///
  /// In en, this message translates to:
  /// **'Keep the rhythm, but remember to take breaks'**
  String get keepRhythmTakeBrakes;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageLearning.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get languageLearning;

  /// No description provided for @last7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get last7Days;

  /// No description provided for @lastBackup.
  ///
  /// In en, this message translates to:
  /// **'Last backup'**
  String get lastBackup;

  /// No description provided for @leituraAtual.
  ///
  /// In en, this message translates to:
  /// **'Current Reading'**
  String get leituraAtual;

  /// No description provided for @lendoAgora.
  ///
  /// In en, this message translates to:
  /// **'Reading Now'**
  String get lendoAgora;

  /// No description provided for @level.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get level;

  /// No description provided for @levelAbbrev.
  ///
  /// In en, this message translates to:
  /// **'Lv. {level}'**
  String levelAbbrev(Object level);

  /// No description provided for @liEConcordoComOs.
  ///
  /// In en, this message translates to:
  /// **'I have read and agree to the '**
  String get liEConcordoComOs;

  /// No description provided for @library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// No description provided for @lifetimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Lifetime'**
  String get lifetimeLabel;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @limpar.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get limpar;

  /// No description provided for @limparDados.
  ///
  /// In en, this message translates to:
  /// **'Clear data?'**
  String get limparDados;

  /// No description provided for @limparDadosDaNuvem.
  ///
  /// In en, this message translates to:
  /// **'Clear Cloud Data?'**
  String get limparDadosDaNuvem;

  /// No description provided for @limparFiltros.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get limparFiltros;

  /// No description provided for @list.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get list;

  /// No description provided for @listening.
  ///
  /// In en, this message translates to:
  /// **'Listening...'**
  String get listening;

  /// No description provided for @livroNaoEncontrado.
  ///
  /// In en, this message translates to:
  /// **'Book not found'**
  String get livroNaoEncontrado;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @locked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get locked;

  /// No description provided for @log.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get log;

  /// No description provided for @loginComFacebookEmBreveUseGoogleOuEntreC.
  ///
  /// In en, this message translates to:
  /// **'Facebook login coming soon! Use Google or enter as guest.'**
  String get loginComFacebookEmBreveUseGoogleOuEntreC;

  /// No description provided for @loginError.
  ///
  /// In en, this message translates to:
  /// **'Login error:'**
  String get loginError;

  /// No description provided for @logoutError.
  ///
  /// In en, this message translates to:
  /// **'Logout error:'**
  String get logoutError;

  /// No description provided for @longBreak.
  ///
  /// In en, this message translates to:
  /// **'Long Break'**
  String get longBreak;

  /// No description provided for @longestStreak.
  ///
  /// In en, this message translates to:
  /// **'Longest streak'**
  String get longestStreak;

  /// No description provided for @lunchTimeBreak.
  ///
  /// In en, this message translates to:
  /// **'Lunch time! Take a break.'**
  String get lunchTimeBreak;

  /// No description provided for @maisTarde.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get maisTarde;

  /// No description provided for @markAsComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark as complete'**
  String get markAsComplete;

  /// No description provided for @markAsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Mark as completed'**
  String get markAsCompleted;

  /// No description provided for @markAsCompletedBtn.
  ///
  /// In en, this message translates to:
  /// **'Mark as Completed'**
  String get markAsCompletedBtn;

  /// No description provided for @markAsFavorite.
  ///
  /// In en, this message translates to:
  /// **'Mark this book as favorite'**
  String get markAsFavorite;

  /// No description provided for @markAsPending.
  ///
  /// In en, this message translates to:
  /// **'Mark as pending'**
  String get markAsPending;

  /// No description provided for @markTaskAsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Mark as completed'**
  String get markTaskAsCompleted;

  /// No description provided for @markTaskAsPending.
  ///
  /// In en, this message translates to:
  /// **'Mark as pending'**
  String get markTaskAsPending;

  /// No description provided for @medio.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medio;

  /// No description provided for @min.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get min;

  /// No description provided for @minimizar.
  ///
  /// In en, this message translates to:
  /// **'Minimize'**
  String get minimizar;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutes;

  /// No description provided for @minutesRead.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String minutesRead(Object count);

  /// No description provided for @missoesDiarias.
  ///
  /// In en, this message translates to:
  /// **'Daily Missions'**
  String get missoesDiarias;

  /// No description provided for @mondayFull.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get mondayFull;

  /// No description provided for @mondayShort.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get mondayShort;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @monthlySummaryOf.
  ///
  /// In en, this message translates to:
  /// **'Summary of {month}'**
  String monthlySummaryOf(Object month);

  /// No description provided for @mood.
  ///
  /// In en, this message translates to:
  /// **'Mood'**
  String get mood;

  /// No description provided for @moodAdviceBad.
  ///
  /// In en, this message translates to:
  /// **'Bad days happen. Be kind to yourself.'**
  String get moodAdviceBad;

  /// No description provided for @moodAdviceGood.
  ///
  /// In en, this message translates to:
  /// **'Positive energy! Keep it up, you\'re doing well.'**
  String get moodAdviceGood;

  /// No description provided for @moodAdviceGreat.
  ///
  /// In en, this message translates to:
  /// **'What a joy! Enjoy this special moment! 🎉'**
  String get moodAdviceGreat;

  /// No description provided for @moodAdviceOkay.
  ///
  /// In en, this message translates to:
  /// **'A neutral day. Sometimes it\'s just going with the flow.'**
  String get moodAdviceOkay;

  /// No description provided for @moodAdviceTerrible.
  ///
  /// In en, this message translates to:
  /// **'It\'s tough today, but this will pass. How about doing something relaxing?'**
  String get moodAdviceTerrible;

  /// No description provided for @moodBad.
  ///
  /// In en, this message translates to:
  /// **'Bad'**
  String get moodBad;

  /// No description provided for @moodDiary.
  ///
  /// In en, this message translates to:
  /// **'Mood Diary'**
  String get moodDiary;

  /// No description provided for @moodDistribution.
  ///
  /// In en, this message translates to:
  /// **'Mood Distribution'**
  String get moodDistribution;

  /// No description provided for @moodGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get moodGood;

  /// No description provided for @moodGreat.
  ///
  /// In en, this message translates to:
  /// **'Great'**
  String get moodGreat;

  /// No description provided for @moodHistory.
  ///
  /// In en, this message translates to:
  /// **'Mood History'**
  String get moodHistory;

  /// No description provided for @moodJournal.
  ///
  /// In en, this message translates to:
  /// **'Mood Journal'**
  String get moodJournal;

  /// No description provided for @moodLabel.
  ///
  /// In en, this message translates to:
  /// **'Mood'**
  String get moodLabel;

  /// No description provided for @moodNotRecorded.
  ///
  /// In en, this message translates to:
  /// **'Mood not recorded'**
  String get moodNotRecorded;

  /// No description provided for @moodOkay.
  ///
  /// In en, this message translates to:
  /// **'Okay'**
  String get moodOkay;

  /// No description provided for @moodRecord.
  ///
  /// In en, this message translates to:
  /// **'Mood Record'**
  String get moodRecord;

  /// No description provided for @moodRecords.
  ///
  /// In en, this message translates to:
  /// **'Mood Records'**
  String get moodRecords;

  /// No description provided for @moodRegistered.
  ///
  /// In en, this message translates to:
  /// **'😊 Mood Registered'**
  String get moodRegistered;

  /// No description provided for @moodRegisteredSuccess.
  ///
  /// In en, this message translates to:
  /// **'😊 {mood} registered!'**
  String moodRegisteredSuccess(Object mood);

  /// No description provided for @moodTerrible.
  ///
  /// In en, this message translates to:
  /// **'Terrible'**
  String get moodTerrible;

  /// No description provided for @moodUpdated.
  ///
  /// In en, this message translates to:
  /// **'Mood updated!'**
  String get moodUpdated;

  /// No description provided for @moodVsProductivity.
  ///
  /// In en, this message translates to:
  /// **'Mood vs Productivity'**
  String get moodVsProductivity;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @moreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get moreOptions;

  /// No description provided for @moreProductiveOnGoodDays.
  ///
  /// In en, this message translates to:
  /// **'You are {percent}% more productive on good mood days'**
  String moreProductiveOnGoodDays(Object percent);

  /// No description provided for @moveToDayAfterTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Move to day after tomorrow'**
  String get moveToDayAfterTomorrow;

  /// No description provided for @moveToToday.
  ///
  /// In en, this message translates to:
  /// **'Move to today'**
  String get moveToToday;

  /// No description provided for @moveToTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Move to tomorrow'**
  String get moveToTomorrow;

  /// No description provided for @multipleReminders.
  ///
  /// In en, this message translates to:
  /// **'{count} times'**
  String multipleReminders(Object count);

  /// No description provided for @myBooks.
  ///
  /// In en, this message translates to:
  /// **'My Books'**
  String get myBooks;

  /// No description provided for @myDiary.
  ///
  /// In en, this message translates to:
  /// **'My Diary'**
  String get myDiary;

  /// No description provided for @myHabits.
  ///
  /// In en, this message translates to:
  /// **'My Habits'**
  String get myHabits;

  /// No description provided for @myReview.
  ///
  /// In en, this message translates to:
  /// **'My Review'**
  String get myReview;

  /// No description provided for @myTasks.
  ///
  /// In en, this message translates to:
  /// **'My Tasks'**
  String get myTasks;

  /// No description provided for @naoHaPalavrasParaRevisarAgora.
  ///
  /// In en, this message translates to:
  /// **'No words to review right now!'**
  String get naoHaPalavrasParaRevisarAgora;

  /// No description provided for @naoRecebeuReenviar.
  ///
  /// In en, this message translates to:
  /// **'Did not receive? Resend'**
  String get naoRecebeuReenviar;

  /// No description provided for @nenhum.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get nenhum;

  /// No description provided for @nenhumLivroEmLeitura.
  ///
  /// In en, this message translates to:
  /// **'No book being read'**
  String get nenhumLivroEmLeitura;

  /// No description provided for @nenhumaNotaAinda.
  ///
  /// In en, this message translates to:
  /// **'No notes yet'**
  String get nenhumaNotaAinda;

  /// No description provided for @nenhumaTarefaParaHoje.
  ///
  /// In en, this message translates to:
  /// **'No tasks for today!'**
  String get nenhumaTarefaParaHoje;

  /// No description provided for @neutralDays.
  ///
  /// In en, this message translates to:
  /// **'Neutral days'**
  String get neutralDays;

  /// No description provided for @never.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get never;

  /// No description provided for @newAchievement.
  ///
  /// In en, this message translates to:
  /// **'New Achievement!'**
  String get newAchievement;

  /// No description provided for @newArticle.
  ///
  /// In en, this message translates to:
  /// **'New Article'**
  String get newArticle;

  /// No description provided for @newEntry.
  ///
  /// In en, this message translates to:
  /// **'New Entry'**
  String get newEntry;

  /// No description provided for @newHabit.
  ///
  /// In en, this message translates to:
  /// **'New Habit'**
  String get newHabit;

  /// No description provided for @newNote.
  ///
  /// In en, this message translates to:
  /// **'New Note'**
  String get newNote;

  /// No description provided for @newTask.
  ///
  /// In en, this message translates to:
  /// **'New Task'**
  String get newTask;

  /// No description provided for @newestFirst.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get newestFirst;

  /// No description provided for @news.
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get news;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @nextAchievement.
  ///
  /// In en, this message translates to:
  /// **'Next achievement'**
  String get nextAchievement;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @noActivityToday.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t logged any activity today. How about starting with a focus session?'**
  String get noActivityToday;

  /// No description provided for @noBooks.
  ///
  /// In en, this message translates to:
  /// **'No books'**
  String get noBooks;

  /// No description provided for @noBooksFound.
  ///
  /// In en, this message translates to:
  /// **'No books found'**
  String get noBooksFound;

  /// No description provided for @noCategory.
  ///
  /// In en, this message translates to:
  /// **'No category'**
  String get noCategory;

  /// No description provided for @noCoversFound.
  ///
  /// In en, this message translates to:
  /// **'No covers found'**
  String get noCoversFound;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @noDiaryEntries.
  ///
  /// In en, this message translates to:
  /// **'No entries yet'**
  String get noDiaryEntries;

  /// No description provided for @noEntriesFound.
  ///
  /// In en, this message translates to:
  /// **'No entries found'**
  String get noEntriesFound;

  /// No description provided for @noHabits.
  ///
  /// In en, this message translates to:
  /// **'No habits'**
  String get noHabits;

  /// No description provided for @noMoodRecords.
  ///
  /// In en, this message translates to:
  /// **'No mood records'**
  String get noMoodRecords;

  /// No description provided for @noRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'No recent activity'**
  String get noRecentActivity;

  /// No description provided for @noRecords.
  ///
  /// In en, this message translates to:
  /// **'No records'**
  String get noRecords;

  /// No description provided for @noReminders.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get noReminders;

  /// No description provided for @noTaskSelected.
  ///
  /// In en, this message translates to:
  /// **'No task selected'**
  String get noTaskSelected;

  /// No description provided for @noTasksCompleted.
  ///
  /// In en, this message translates to:
  /// **'No completed tasks'**
  String get noTasksCompleted;

  /// No description provided for @noTasksPending.
  ///
  /// In en, this message translates to:
  /// **'No pending tasks'**
  String get noTasksPending;

  /// No description provided for @noTitle.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get noTitle;

  /// No description provided for @nome.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nome;

  /// No description provided for @notEnoughData.
  ///
  /// In en, this message translates to:
  /// **'Not enough data...'**
  String get notEnoughData;

  /// No description provided for @notaSalva.
  ///
  /// In en, this message translates to:
  /// **'✅ Note saved!'**
  String get notaSalva;

  /// No description provided for @notaSalvaComSucesso.
  ///
  /// In en, this message translates to:
  /// **'Note saved successfully!'**
  String get notaSalvaComSucesso;

  /// No description provided for @notasRapidas.
  ///
  /// In en, this message translates to:
  /// **'Quick Notes'**
  String get notasRapidas;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note: '**
  String get note;

  /// No description provided for @noteDeleted.
  ///
  /// In en, this message translates to:
  /// **'Note deleted'**
  String get noteDeleted;

  /// No description provided for @noteEmpty.
  ///
  /// In en, this message translates to:
  /// **'Note is empty'**
  String get noteEmpty;

  /// No description provided for @noteIsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Note is empty'**
  String get noteIsEmpty;

  /// No description provided for @noteSaved.
  ///
  /// In en, this message translates to:
  /// **'Note saved!'**
  String get noteSaved;

  /// No description provided for @noteUpdated.
  ///
  /// In en, this message translates to:
  /// **'Note updated!'**
  String get noteUpdated;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @notesAndIdeas.
  ///
  /// In en, this message translates to:
  /// **'Notes and ideas'**
  String get notesAndIdeas;

  /// No description provided for @notesCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} notes'**
  String notesCountLabel(Object count);

  /// No description provided for @notesField.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesField;

  /// No description provided for @notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes: {notes}'**
  String notesLabel(Object notes);

  /// No description provided for @notifBreakOverBody.
  ///
  /// In en, this message translates to:
  /// **'Time to get back to focus! Let\'s go?'**
  String get notifBreakOverBody;

  /// No description provided for @notifBreakOverTitle.
  ///
  /// In en, this message translates to:
  /// **'Break Over!'**
  String get notifBreakOverTitle;

  /// No description provided for @notifHabitsPendingBody.
  ///
  /// In en, this message translates to:
  /// **'{names} have not been completed yet today.'**
  String notifHabitsPendingBody(Object names);

  /// No description provided for @notifHabitsPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'{count} pending habits'**
  String notifHabitsPendingTitle(Object count);

  /// No description provided for @notifMoodEveningBody.
  ///
  /// In en, this message translates to:
  /// **'How was your day? Record your mood before bed.'**
  String get notifMoodEveningBody;

  /// No description provided for @notifMoodEveningTitle.
  ///
  /// In en, this message translates to:
  /// **'Time to reflect!'**
  String get notifMoodEveningTitle;

  /// No description provided for @notifMoodMorningBody.
  ///
  /// In en, this message translates to:
  /// **'Record your mood to start the day with self-awareness.'**
  String get notifMoodMorningBody;

  /// No description provided for @notifMoodMorningTitle.
  ///
  /// In en, this message translates to:
  /// **'Good morning! How are you?'**
  String get notifMoodMorningTitle;

  /// No description provided for @notifPomodoroCompleteBody.
  ///
  /// In en, this message translates to:
  /// **'You focused {minutes} minutes on \"{task}\". Great job!'**
  String notifPomodoroCompleteBody(Object minutes, Object task);

  /// No description provided for @notifPomodoroCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Pomodoro Complete!'**
  String get notifPomodoroCompleteTitle;

  /// No description provided for @notifStreakAlertBody.
  ///
  /// In en, this message translates to:
  /// **'Your {days}-day streak is in danger. Record something today!'**
  String notifStreakAlertBody(Object days);

  /// No description provided for @notifStreakAlertTitle.
  ///
  /// In en, this message translates to:
  /// **'Streak at risk!'**
  String get notifStreakAlertTitle;

  /// No description provided for @notifTaskReminderBody.
  ///
  /// In en, this message translates to:
  /// **'Scheduled task reminder'**
  String get notifTaskReminderBody;

  /// No description provided for @notifTasksOverdueTitle.
  ///
  /// In en, this message translates to:
  /// **'{count} overdue tasks!'**
  String notifTasksOverdueTitle(Object count);

  /// No description provided for @notifTasksPendingBody.
  ///
  /// In en, this message translates to:
  /// **'{names} for today.'**
  String notifTasksPendingBody(Object names);

  /// No description provided for @notifTasksPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'{count} pending tasks'**
  String notifTasksPendingTitle(Object count);

  /// No description provided for @notificacaoDeTesteEnviada.
  ///
  /// In en, this message translates to:
  /// **'Test notification sent!'**
  String get notificacaoDeTesteEnviada;

  /// No description provided for @notificacaoEnviada.
  ///
  /// In en, this message translates to:
  /// **'Notification sent!'**
  String get notificacaoEnviada;

  /// No description provided for @notificacoes.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificacoes;

  /// No description provided for @notificationTypesTimesFrequency.
  ///
  /// In en, this message translates to:
  /// **'Types, times, frequency'**
  String get notificationTypesTimesFrequency;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @novaCategoria.
  ///
  /// In en, this message translates to:
  /// **'New Category'**
  String get novaCategoria;

  /// No description provided for @novoProjeto.
  ///
  /// In en, this message translates to:
  /// **'New Project'**
  String get novoProjeto;

  /// No description provided for @num0h.
  ///
  /// In en, this message translates to:
  /// **'0h'**
  String get num0h;

  /// No description provided for @nuncaSincronizado.
  ///
  /// In en, this message translates to:
  /// **'Never synchronized'**
  String get nuncaSincronizado;

  /// No description provided for @oTimerSeraPausadoMasSeuProgressoSeraMant.
  ///
  /// In en, this message translates to:
  /// **'The timer will be paused, but your progress will be kept.'**
  String get oTimerSeraPausadoMasSeuProgressoSeraMant;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @oldestFirst.
  ///
  /// In en, this message translates to:
  /// **'Oldest first'**
  String get oldestFirst;

  /// No description provided for @on.
  ///
  /// In en, this message translates to:
  /// **'on'**
  String get on;

  /// No description provided for @onThisDay.
  ///
  /// In en, this message translates to:
  /// **'On This Day'**
  String get onThisDay;

  /// No description provided for @openAlexDescription.
  ///
  /// In en, this message translates to:
  /// **'OpenAlex · Millions of academic articles'**
  String get openAlexDescription;

  /// No description provided for @openingArticle.
  ///
  /// In en, this message translates to:
  /// **'Opening article...'**
  String get openingArticle;

  /// No description provided for @options.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get options;

  /// No description provided for @orange.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get orange;

  /// No description provided for @ordenarPor.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get ordenarPor;

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// No description provided for @overdueLate.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get overdueLate;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @pages.
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get pages;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @pauseTimer.
  ///
  /// In en, this message translates to:
  /// **'Pause timer'**
  String get pauseTimer;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @pendingHabit.
  ///
  /// In en, this message translates to:
  /// **'1 pending habit'**
  String get pendingHabit;

  /// No description provided for @pendingHabitsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} pending habits'**
  String pendingHabitsCount(Object count);

  /// No description provided for @perfectDays.
  ///
  /// In en, this message translates to:
  /// **'Perfect days'**
  String get perfectDays;

  /// No description provided for @periodMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get periodMonth;

  /// No description provided for @periodWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get periodWeek;

  /// No description provided for @periodYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get periodYear;

  /// No description provided for @personalJourneyCompanion.
  ///
  /// In en, this message translates to:
  /// **'Your personal journey companion.'**
  String get personalJourneyCompanion;

  /// No description provided for @personalizeAAparenciaDoApp.
  ///
  /// In en, this message translates to:
  /// **'Customize the app appearance'**
  String get personalizeAAparenciaDoApp;

  /// No description provided for @photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos;

  /// No description provided for @phraseSaved.
  ///
  /// In en, this message translates to:
  /// **'Phrase saved!'**
  String get phraseSaved;

  /// No description provided for @phraseUpdated.
  ///
  /// In en, this message translates to:
  /// **'Phrase updated!'**
  String get phraseUpdated;

  /// No description provided for @physical.
  ///
  /// In en, this message translates to:
  /// **'Physical'**
  String get physical;

  /// No description provided for @pink.
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get pink;

  /// No description provided for @politicaDePrivacidade.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get politicaDePrivacidade;

  /// No description provided for @pomodoro.
  ///
  /// In en, this message translates to:
  /// **'Pomodoro'**
  String get pomodoro;

  /// No description provided for @pomodoroInProgress.
  ///
  /// In en, this message translates to:
  /// **'Pomodoro in Progress'**
  String get pomodoroInProgress;

  /// No description provided for @pomodoroPaused.
  ///
  /// In en, this message translates to:
  /// **'Pomodoro Paused'**
  String get pomodoroPaused;

  /// No description provided for @pomodoroTimer.
  ///
  /// In en, this message translates to:
  /// **'Pomodoro Timer'**
  String get pomodoroTimer;

  /// No description provided for @popular.
  ///
  /// In en, this message translates to:
  /// **'POPULAR'**
  String get popular;

  /// No description provided for @portuguese.
  ///
  /// In en, this message translates to:
  /// **'Portuguese'**
  String get portuguese;

  /// No description provided for @postponeToTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Postpone to tomorrow'**
  String get postponeToTomorrow;

  /// No description provided for @precisaDePeloMenos2Registros.
  ///
  /// In en, this message translates to:
  /// **'Need at least 2 records...'**
  String get precisaDePeloMenos2Registros;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// No description provided for @priorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get priorityHigh;

  /// No description provided for @priorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get priorityLow;

  /// No description provided for @priorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get priorityMedium;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @proActive.
  ///
  /// In en, this message translates to:
  /// **'PRO Active'**
  String get proActive;

  /// No description provided for @proAtivo.
  ///
  /// In en, this message translates to:
  /// **'PRO ACTIVE'**
  String get proAtivo;

  /// No description provided for @proMensalAtivadoModoTeste30Dias.
  ///
  /// In en, this message translates to:
  /// **'🎉 Monthly PRO activated! (test mode - 30 days)'**
  String get proMensalAtivadoModoTeste30Dias;

  /// No description provided for @proVitalicioAtivadoModoTeste.
  ///
  /// In en, this message translates to:
  /// **'🎉 Lifetime PRO activated! (test mode)'**
  String get proVitalicioAtivadoModoTeste;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @projectLabel.
  ///
  /// In en, this message translates to:
  /// **'Project: {project}'**
  String projectLabel(Object project);

  /// No description provided for @projectName.
  ///
  /// In en, this message translates to:
  /// **'Project name...'**
  String get projectName;

  /// No description provided for @projects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get projects;

  /// No description provided for @publicationYear.
  ///
  /// In en, this message translates to:
  /// **'Publication Year'**
  String get publicationYear;

  /// No description provided for @purple.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get purple;

  /// No description provided for @quickAccess.
  ///
  /// In en, this message translates to:
  /// **'Quick Access'**
  String get quickAccess;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @quickNote.
  ///
  /// In en, this message translates to:
  /// **'Quick Note'**
  String get quickNote;

  /// No description provided for @quote.
  ///
  /// In en, this message translates to:
  /// **'Quote'**
  String get quote;

  /// No description provided for @quotesEpictetus.
  ///
  /// In en, this message translates to:
  /// **'It\'s not what happens to you, but how you react to it that matters.'**
  String get quotesEpictetus;

  /// No description provided for @quotesLennon.
  ///
  /// In en, this message translates to:
  /// **'Life is what happens when you\'re busy making other plans.'**
  String get quotesLennon;

  /// No description provided for @quotesMaslow1.
  ///
  /// In en, this message translates to:
  /// **'What a man can be, he must be.'**
  String get quotesMaslow1;

  /// No description provided for @quotesMaslow2.
  ///
  /// In en, this message translates to:
  /// **'In any given moment we have two options: to step forward into growth or back into safety.'**
  String get quotesMaslow2;

  /// No description provided for @quotesSocrates.
  ///
  /// In en, this message translates to:
  /// **'Know thyself.'**
  String get quotesSocrates;

  /// No description provided for @rateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate App'**
  String get rateApp;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @read.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get read;

  /// No description provided for @reading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get reading;

  /// No description provided for @readingTime.
  ///
  /// In en, this message translates to:
  /// **'Reading time'**
  String get readingTime;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @recordDays.
  ///
  /// In en, this message translates to:
  /// **'Record: {days} days'**
  String recordDays(Object days);

  /// No description provided for @recordLabel.
  ///
  /// In en, this message translates to:
  /// **'Record:'**
  String get recordLabel;

  /// No description provided for @recordMood.
  ///
  /// In en, this message translates to:
  /// **'Record Mood'**
  String get recordMood;

  /// No description provided for @recordMoodNow.
  ///
  /// In en, this message translates to:
  /// **'Record your mood now'**
  String get recordMoodNow;

  /// No description provided for @recordNow.
  ///
  /// In en, this message translates to:
  /// **'Record Now'**
  String get recordNow;

  /// No description provided for @recordStreak.
  ///
  /// In en, this message translates to:
  /// **'Record: {days} days'**
  String recordStreak(Object days);

  /// No description provided for @recordThoughtsAndFeelings.
  ///
  /// In en, this message translates to:
  /// **'Record your thoughts and feelings'**
  String get recordThoughtsAndFeelings;

  /// No description provided for @red.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get red;

  /// No description provided for @reenviar.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get reenviar;

  /// No description provided for @reflectionJournal.
  ///
  /// In en, this message translates to:
  /// **'Guided Reflection'**
  String get reflectionJournal;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @registerMood.
  ///
  /// In en, this message translates to:
  /// **'Log mood'**
  String get registerMood;

  /// No description provided for @registrar.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registrar;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'remaining'**
  String get remaining;

  /// No description provided for @rememberDrinkWater.
  ///
  /// In en, this message translates to:
  /// **'Remember to drink water! 💧'**
  String get rememberDrinkWater;

  /// No description provided for @reminderEnabled.
  ///
  /// In en, this message translates to:
  /// **'Reminder enabled'**
  String get reminderEnabled;

  /// No description provided for @reminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get reminderTime;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @removeAds.
  ///
  /// In en, this message translates to:
  /// **'Remove ads'**
  String get removeAds;

  /// No description provided for @removeCover.
  ///
  /// In en, this message translates to:
  /// **'Remove Cover'**
  String get removeCover;

  /// No description provided for @removeFromFavoritesDiary.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get removeFromFavoritesDiary;

  /// No description provided for @removeFromFavourites.
  ///
  /// In en, this message translates to:
  /// **'Remove from Favourites'**
  String get removeFromFavourites;

  /// No description provided for @removeHabit.
  ///
  /// In en, this message translates to:
  /// **'Remove Habit'**
  String get removeHabit;

  /// No description provided for @removeTag.
  ///
  /// In en, this message translates to:
  /// **'Remove tag'**
  String get removeTag;

  /// No description provided for @renomearProjeto.
  ///
  /// In en, this message translates to:
  /// **'Rename project'**
  String get renomearProjeto;

  /// No description provided for @repetirEm.
  ///
  /// In en, this message translates to:
  /// **'Repeat on'**
  String get repetirEm;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @restaurar.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restaurar;

  /// No description provided for @restoreBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore Backup'**
  String get restoreBackup;

  /// No description provided for @restoreError.
  ///
  /// In en, this message translates to:
  /// **'Error restoring backup'**
  String get restoreError;

  /// No description provided for @restoreSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup restored successfully!'**
  String get restoreSuccess;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @rising.
  ///
  /// In en, this message translates to:
  /// **'Rising!'**
  String get rising;

  /// No description provided for @sairDoPomodoro.
  ///
  /// In en, this message translates to:
  /// **'Exit Pomodoro?'**
  String get sairDoPomodoro;

  /// No description provided for @salvarArtigo.
  ///
  /// In en, this message translates to:
  /// **'Save Article'**
  String get salvarArtigo;

  /// No description provided for @salvarFrase.
  ///
  /// In en, this message translates to:
  /// **'Save Quote'**
  String get salvarFrase;

  /// No description provided for @salvarNaBiblioteca.
  ///
  /// In en, this message translates to:
  /// **'Save to Library'**
  String get salvarNaBiblioteca;

  /// No description provided for @salvarNota.
  ///
  /// In en, this message translates to:
  /// **'Save Note'**
  String get salvarNota;

  /// No description provided for @saturdayFull.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturdayFull;

  /// No description provided for @saturdayShort.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get saturdayShort;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search in history...'**
  String get searchHint;

  /// No description provided for @searchBookOnline.
  ///
  /// In en, this message translates to:
  /// **'Search Book Online'**
  String get searchBookOnline;

  /// No description provided for @searchCoverOnline.
  ///
  /// In en, this message translates to:
  /// **'Search Cover Online'**
  String get searchCoverOnline;

  /// No description provided for @searchDiary.
  ///
  /// In en, this message translates to:
  /// **'Search in Diary'**
  String get searchDiary;

  /// No description provided for @searchHere.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get searchHere;

  /// No description provided for @searchOnline.
  ///
  /// In en, this message translates to:
  /// **'Search online'**
  String get searchOnline;

  /// No description provided for @searchOnlineCover.
  ///
  /// In en, this message translates to:
  /// **'Search Online'**
  String get searchOnlineCover;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @seeLess.
  ///
  /// In en, this message translates to:
  /// **'See less'**
  String get seeLess;

  /// No description provided for @seeMore.
  ///
  /// In en, this message translates to:
  /// **'See more'**
  String get seeMore;

  /// No description provided for @selecioneUmIdiomaPrimeiro.
  ///
  /// In en, this message translates to:
  /// **'Select a language first'**
  String get selecioneUmIdiomaPrimeiro;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @selectCoverFromOpenLibrary.
  ///
  /// In en, this message translates to:
  /// **'Select a cover from Open Library'**
  String get selectCoverFromOpenLibrary;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @selectFromDevice.
  ///
  /// In en, this message translates to:
  /// **'Select an image from your device'**
  String get selectFromDevice;

  /// No description provided for @selectTask.
  ///
  /// In en, this message translates to:
  /// **'Select Task'**
  String get selectTask;

  /// No description provided for @selectTime.
  ///
  /// In en, this message translates to:
  /// **'Select time'**
  String get selectTime;

  /// No description provided for @selectYourMood.
  ///
  /// In en, this message translates to:
  /// **'Select your mood'**
  String get selectYourMood;

  /// No description provided for @semDadosSuficientes.
  ///
  /// In en, this message translates to:
  /// **'Not enough data...'**
  String get semDadosSuficientes;

  /// No description provided for @session.
  ///
  /// In en, this message translates to:
  /// **'session'**
  String get session;

  /// No description provided for @sessionComplete.
  ///
  /// In en, this message translates to:
  /// **'Session complete!'**
  String get sessionComplete;

  /// No description provided for @sessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get sessions;

  /// No description provided for @setAsFinished.
  ///
  /// In en, this message translates to:
  /// **'Set as finished'**
  String get setAsFinished;

  /// No description provided for @setClearDailyGoals.
  ///
  /// In en, this message translates to:
  /// **'Set clear goals for the day'**
  String get setClearDailyGoals;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @seuCompanheiroDeProdutividadeEBemestarPe.
  ///
  /// In en, this message translates to:
  /// **'Your personal productivity and wellness companion.'**
  String get seuCompanheiroDeProdutividadeEBemestarPe;

  /// No description provided for @shareApp.
  ///
  /// In en, this message translates to:
  /// **'Share App'**
  String get shareApp;

  /// No description provided for @shareEntry.
  ///
  /// In en, this message translates to:
  /// **'Share entry'**
  String get shareEntry;

  /// No description provided for @shareSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon: Share'**
  String get shareSoon;

  /// No description provided for @shortBreak.
  ///
  /// In en, this message translates to:
  /// **'Short Break'**
  String get shortBreak;

  /// No description provided for @showCompleted.
  ///
  /// In en, this message translates to:
  /// **'Show completed'**
  String get showCompleted;

  /// No description provided for @showCompletedCount.
  ///
  /// In en, this message translates to:
  /// **'Show completed ({count})'**
  String showCompletedCount(Object count);

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get showLess;

  /// No description provided for @showMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get showMore;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @signOutError.
  ///
  /// In en, this message translates to:
  /// **'Sign out error: {error}'**
  String signOutError(Object error);

  /// No description provided for @sincronizacao.
  ///
  /// In en, this message translates to:
  /// **'Synchronization'**
  String get sincronizacao;

  /// No description provided for @sincronizarAgora.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get sincronizarAgora;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @skipForToday.
  ///
  /// In en, this message translates to:
  /// **'Skip for today'**
  String get skipForToday;

  /// No description provided for @skip_.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip_;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// No description provided for @sounds.
  ///
  /// In en, this message translates to:
  /// **'Sounds'**
  String get sounds;

  /// No description provided for @speechError.
  ///
  /// In en, this message translates to:
  /// **'Error recognizing speech'**
  String get speechError;

  /// No description provided for @speechNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Speech recognition not available'**
  String get speechNotAvailable;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Your focus journey starts here'**
  String get splashTagline;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @startTrackingMood.
  ///
  /// In en, this message translates to:
  /// **'Start tracking your mood'**
  String get startTrackingMood;

  /// No description provided for @startWith25minPomodoro.
  ///
  /// In en, this message translates to:
  /// **'Start with 25 minutes of focus using Pomodoro'**
  String get startWith25minPomodoro;

  /// No description provided for @startYourDiary.
  ///
  /// In en, this message translates to:
  /// **'Start your diary!'**
  String get startYourDiary;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @stopwatch.
  ///
  /// In en, this message translates to:
  /// **'Stopwatch'**
  String get stopwatch;

  /// No description provided for @laps.
  ///
  /// In en, this message translates to:
  /// **'Laps'**
  String get laps;

  /// No description provided for @lap.
  ///
  /// In en, this message translates to:
  /// **'Lap'**
  String get lap;

  /// No description provided for @startStopwatch.
  ///
  /// In en, this message translates to:
  /// **'Start Stopwatch'**
  String get startStopwatch;

  /// No description provided for @pauseStopwatch.
  ///
  /// In en, this message translates to:
  /// **'Pause Stopwatch'**
  String get pauseStopwatch;

  /// No description provided for @noLaps.
  ///
  /// In en, this message translates to:
  /// **'No laps recorded'**
  String get noLaps;

  /// No description provided for @timerComplete.
  ///
  /// In en, this message translates to:
  /// **'Timer complete!'**
  String get timerComplete;

  /// No description provided for @setTime.
  ///
  /// In en, this message translates to:
  /// **'Set time'**
  String get setTime;

  /// No description provided for @countdownTimer.
  ///
  /// In en, this message translates to:
  /// **'Timer'**
  String get countdownTimer;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @streak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get streak;

  /// No description provided for @streakDays.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String streakDays(Object days);

  /// No description provided for @subscriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscriptionLabel;

  /// No description provided for @subtitle.
  ///
  /// In en, this message translates to:
  /// **'Subtitle'**
  String get subtitle;

  /// No description provided for @summaryOf.
  ///
  /// In en, this message translates to:
  /// **'Summary of'**
  String get summaryOf;

  /// No description provided for @sundayFull.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sundayFull;

  /// No description provided for @sundayShort.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get sundayShort;

  /// No description provided for @supportTheApp.
  ///
  /// In en, this message translates to:
  /// **'Support the App'**
  String get supportTheApp;

  /// No description provided for @switchToCelestial.
  ///
  /// In en, this message translates to:
  /// **'Switch to Celestial'**
  String get switchToCelestial;

  /// No description provided for @switchToNeumorphic.
  ///
  /// In en, this message translates to:
  /// **'Switch to Neumorphic'**
  String get switchToNeumorphic;

  /// No description provided for @systemMode.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemMode;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @takeCareSelfDeserve.
  ///
  /// In en, this message translates to:
  /// **'Take care of yourself, you deserve it.'**
  String get takeCareSelfDeserve;

  /// No description provided for @takeCareToday.
  ///
  /// In en, this message translates to:
  /// **'Take care of yourself today.'**
  String get takeCareToday;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @tapToAdd.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add'**
  String get tapToAdd;

  /// No description provided for @tapToChoose.
  ///
  /// In en, this message translates to:
  /// **'Tap to choose...'**
  String get tapToChoose;

  /// No description provided for @tapToLoadNews.
  ///
  /// In en, this message translates to:
  /// **'Tap to load news'**
  String get tapToLoadNews;

  /// No description provided for @tapToRecordMood.
  ///
  /// In en, this message translates to:
  /// **'Tap the button below to\nrecord your mood'**
  String get tapToRecordMood;

  /// No description provided for @tapToSeeQuote.
  ///
  /// In en, this message translates to:
  /// **'Tap to see a quote...'**
  String get tapToSeeQuote;

  /// No description provided for @tapToSpeak.
  ///
  /// In en, this message translates to:
  /// **'Tap to speak'**
  String get tapToSpeak;

  /// No description provided for @tapToStartFocusTimer.
  ///
  /// In en, this message translates to:
  /// **'Tap to start a focus timer'**
  String get tapToStartFocusTimer;

  /// No description provided for @tarefaAdicionadaComSucesso.
  ///
  /// In en, this message translates to:
  /// **'Task added successfully!'**
  String get tarefaAdicionadaComSucesso;

  /// No description provided for @tarefas.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tarefas;

  /// No description provided for @tarefasDoDia.
  ///
  /// In en, this message translates to:
  /// **'Daily Tasks'**
  String get tarefasDoDia;

  /// No description provided for @taskCompleted.
  ///
  /// In en, this message translates to:
  /// **'Task completed!'**
  String get taskCompleted;

  /// No description provided for @taskCompletedPrefix.
  ///
  /// In en, this message translates to:
  /// **'Completed:'**
  String get taskCompletedPrefix;

  /// No description provided for @taskCreated.
  ///
  /// In en, this message translates to:
  /// **'Task \"{name}\" created!'**
  String taskCreated(Object name);

  /// No description provided for @taskDeleted.
  ///
  /// In en, this message translates to:
  /// **'Task deleted'**
  String get taskDeleted;

  /// No description provided for @taskForToday.
  ///
  /// In en, this message translates to:
  /// **'1 task for today'**
  String get taskForToday;

  /// No description provided for @taskMovedToDayAfterTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Task moved to day after tomorrow'**
  String get taskMovedToDayAfterTomorrow;

  /// No description provided for @taskMovedToToday.
  ///
  /// In en, this message translates to:
  /// **'Task moved to today'**
  String get taskMovedToToday;

  /// No description provided for @taskName.
  ///
  /// In en, this message translates to:
  /// **'Task name'**
  String get taskName;

  /// No description provided for @taskNameHint.
  ///
  /// In en, this message translates to:
  /// **'Task name...'**
  String get taskNameHint;

  /// No description provided for @taskOptions.
  ///
  /// In en, this message translates to:
  /// **'Task options'**
  String get taskOptions;

  /// No description provided for @taskPending.
  ///
  /// In en, this message translates to:
  /// **'Task marked as pending'**
  String get taskPending;

  /// No description provided for @taskPostponed.
  ///
  /// In en, this message translates to:
  /// **'Task postponed to tomorrow'**
  String get taskPostponed;

  /// No description provided for @taskRemoved.
  ///
  /// In en, this message translates to:
  /// **'Task removed'**
  String get taskRemoved;

  /// No description provided for @taskTitle.
  ///
  /// In en, this message translates to:
  /// **'What do you need to do?'**
  String get taskTitle;

  /// No description provided for @taskUpdated.
  ///
  /// In en, this message translates to:
  /// **'Task updated!'**
  String get taskUpdated;

  /// No description provided for @tasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasks;

  /// No description provided for @tasksCompleted.
  ///
  /// In en, this message translates to:
  /// **'{count} of {total} tasks completed'**
  String tasksCompleted(Object count, Object total);

  /// No description provided for @tasksForToday.
  ///
  /// In en, this message translates to:
  /// **'tasks for today'**
  String get tasksForToday;

  /// No description provided for @tasksForTodayCount.
  ///
  /// In en, this message translates to:
  /// **'{count} tasks for today'**
  String tasksForTodayCount(Object count);

  /// No description provided for @teamMeeting.
  ///
  /// In en, this message translates to:
  /// **'Team meeting'**
  String get teamMeeting;

  /// No description provided for @temCertezaQueDesejaExcluir.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete '**
  String get temCertezaQueDesejaExcluir;

  /// No description provided for @templates.
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get templates;

  /// No description provided for @tentarNovamente.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tentarNovamente;

  /// No description provided for @termosDeUso.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get termosDeUso;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @textColor.
  ///
  /// In en, this message translates to:
  /// **'Text color'**
  String get textColor;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @thisWeekLabel.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get thisWeekLabel;

  /// No description provided for @threeDaysAgoShort.
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get threeDaysAgoShort;

  /// No description provided for @thursdayFull.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursdayFull;

  /// No description provided for @thursdayShort.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get thursdayShort;

  /// No description provided for @tickSound.
  ///
  /// In en, this message translates to:
  /// **'Tick Sound'**
  String get tickSound;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @timeDistribution.
  ///
  /// In en, this message translates to:
  /// **'Time Distribution'**
  String get timeDistribution;

  /// No description provided for @timelineView.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timelineView;

  /// No description provided for @timer.
  ///
  /// In en, this message translates to:
  /// **'Timer'**
  String get timer;

  /// No description provided for @timerActive.
  ///
  /// In en, this message translates to:
  /// **'Timer Active'**
  String get timerActive;

  /// No description provided for @timerCompleted.
  ///
  /// In en, this message translates to:
  /// **'Timer Completed!'**
  String get timerCompleted;

  /// No description provided for @timerDemo.
  ///
  /// In en, this message translates to:
  /// **'Timer Demo'**
  String get timerDemo;

  /// No description provided for @timerPaused.
  ///
  /// In en, this message translates to:
  /// **'Timer Paused'**
  String get timerPaused;

  /// No description provided for @timerRunning.
  ///
  /// In en, this message translates to:
  /// **'Timer Running'**
  String get timerRunning;

  /// No description provided for @timesPerDayRandom.
  ///
  /// In en, this message translates to:
  /// **'{count}x per day at random times'**
  String timesPerDayRandom(Object count);

  /// No description provided for @tipRecordFeelings.
  ///
  /// In en, this message translates to:
  /// **'Record how you\'re feeling'**
  String get tipRecordFeelings;

  /// No description provided for @tipUseTags.
  ///
  /// In en, this message translates to:
  /// **'Use tags to organize your entries'**
  String get tipUseTags;

  /// No description provided for @tipWriteDaily.
  ///
  /// In en, this message translates to:
  /// **'Write about your day or a special moment'**
  String get tipWriteDaily;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @titleAuthorOrIsbn.
  ///
  /// In en, this message translates to:
  /// **'Title, author or ISBN'**
  String get titleAuthorOrIsbn;

  /// No description provided for @titleOptional.
  ///
  /// In en, this message translates to:
  /// **'Title (optional)'**
  String get titleOptional;

  /// No description provided for @titleOrAuthor.
  ///
  /// In en, this message translates to:
  /// **'Title or author'**
  String get titleOrAuthor;

  /// No description provided for @toRead.
  ///
  /// In en, this message translates to:
  /// **'To Read'**
  String get toRead;

  /// No description provided for @todas.
  ///
  /// In en, this message translates to:
  /// **'Todas'**
  String get todas;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @todayProgress.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Progress'**
  String get todayProgress;

  /// No description provided for @todayShort.
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get todayShort;

  /// No description provided for @todoList.
  ///
  /// In en, this message translates to:
  /// **'To-do list'**
  String get todoList;

  /// No description provided for @todos.
  ///
  /// In en, this message translates to:
  /// **'Todos'**
  String get todos;

  /// No description provided for @tokenCopiadoParaAreaDeTransferencia.
  ///
  /// In en, this message translates to:
  /// **'✅ Token copied to clipboard!'**
  String get tokenCopiadoParaAreaDeTransferencia;

  /// No description provided for @tokenCopiadoParaAreaDeTransferencia1.
  ///
  /// In en, this message translates to:
  /// **'Token copied to clipboard!'**
  String get tokenCopiadoParaAreaDeTransferencia1;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @tools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get tools;

  /// No description provided for @topActivities.
  ///
  /// In en, this message translates to:
  /// **'Top Activities'**
  String get topActivities;

  /// No description provided for @topTags.
  ///
  /// In en, this message translates to:
  /// **'Most Used Tags'**
  String get topTags;

  /// No description provided for @totalEntries.
  ///
  /// In en, this message translates to:
  /// **'Total Entries'**
  String get totalEntries;

  /// No description provided for @totalHours.
  ///
  /// In en, this message translates to:
  /// **'Total hours'**
  String get totalHours;

  /// No description provided for @totalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalLabel;

  /// No description provided for @totalPages.
  ///
  /// In en, this message translates to:
  /// **'Total Pages'**
  String get totalPages;

  /// No description provided for @totalTime.
  ///
  /// In en, this message translates to:
  /// **'Total Time'**
  String get totalTime;

  /// No description provided for @totalWordsWritten.
  ///
  /// In en, this message translates to:
  /// **'Total Words Written'**
  String get totalWordsWritten;

  /// No description provided for @totalXp.
  ///
  /// In en, this message translates to:
  /// **'Total XP'**
  String get totalXp;

  /// No description provided for @trackProgressPatterns.
  ///
  /// In en, this message translates to:
  /// **'Track your progress and patterns'**
  String get trackProgressPatterns;

  /// No description provided for @trashEmptied.
  ///
  /// In en, this message translates to:
  /// **'Trash emptied'**
  String get trashEmptied;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @tuesdayFull.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesdayFull;

  /// No description provided for @tuesdayShort.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get tuesdayShort;

  /// No description provided for @typeHere.
  ///
  /// In en, this message translates to:
  /// **'Type here...'**
  String get typeHere;

  /// No description provided for @underline.
  ///
  /// In en, this message translates to:
  /// **'Underline'**
  String get underline;

  /// No description provided for @undoAction.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undoAction;

  /// No description provided for @unlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlocked!'**
  String get unlocked;

  /// No description provided for @unlockedOf.
  ///
  /// In en, this message translates to:
  /// **'unlocked of'**
  String get unlockedOf;

  /// No description provided for @unmarkAsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Unmark as Completed'**
  String get unmarkAsCompleted;

  /// No description provided for @unsaved.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get unsaved;

  /// No description provided for @unsavedChanges.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get unsavedChanges;

  /// No description provided for @unsavedChangesMessage.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Do you want to save them?'**
  String get unsavedChangesMessage;

  /// No description provided for @useBiometrics.
  ///
  /// In en, this message translates to:
  /// **'Use biometrics'**
  String get useBiometrics;

  /// No description provided for @useCamera.
  ///
  /// In en, this message translates to:
  /// **'Use camera to photograph the cover'**
  String get useCamera;

  /// No description provided for @useDefaultPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Use default placeholder'**
  String get useDefaultPlaceholder;

  /// No description provided for @vejaSeusHabitosNoCalendario.
  ///
  /// In en, this message translates to:
  /// **'See your habits on calendar'**
  String get vejaSeusHabitosNoCalendario;

  /// No description provided for @verDetalhes.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get verDetalhes;

  /// No description provided for @verDetalhes1.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get verDetalhes1;

  /// No description provided for @verTodas.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get verTodas;

  /// No description provided for @verifiqueSeuEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify your Email'**
  String get verifiqueSeuEmail;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @viewMode.
  ///
  /// In en, this message translates to:
  /// **'View mode'**
  String get viewMode;

  /// No description provided for @voiceInput.
  ///
  /// In en, this message translates to:
  /// **'Voice Input'**
  String get voiceInput;

  /// No description provided for @voltar.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get voltar;

  /// No description provided for @wednesdayFull.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesdayFull;

  /// No description provided for @wednesdayShort.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wednesdayShort;

  /// No description provided for @week.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get week;

  /// No description provided for @weekdayFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get weekdayFri;

  /// No description provided for @weekdayMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get weekdayMon;

  /// No description provided for @weekdaySat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get weekdaySat;

  /// No description provided for @weekdaySun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get weekdaySun;

  /// No description provided for @weekdayThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get weekdayThu;

  /// No description provided for @weekdayTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get weekdayTue;

  /// No description provided for @weekdayWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get weekdayWed;

  /// No description provided for @weeklyProgress.
  ///
  /// In en, this message translates to:
  /// **'Weekly Progress'**
  String get weeklyProgress;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get welcomeBack;

  /// No description provided for @widgetsDaHome.
  ///
  /// In en, this message translates to:
  /// **'Home Widgets'**
  String get widgetsDaHome;

  /// No description provided for @widgetsRestauradosParaOPadrao.
  ///
  /// In en, this message translates to:
  /// **'Widgets restored to default'**
  String get widgetsRestauradosParaOPadrao;

  /// No description provided for @words.
  ///
  /// In en, this message translates to:
  /// **'words'**
  String get words;

  /// No description provided for @wordsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} words'**
  String wordsCount(Object count);

  /// No description provided for @workedMoreThanYesterday.
  ///
  /// In en, this message translates to:
  /// **'Today you\'ve worked {percent}% more than yesterday. Keep it up!'**
  String workedMoreThanYesterday(Object percent);

  /// No description provided for @writeHere.
  ///
  /// In en, this message translates to:
  /// **'Write here...'**
  String get writeHere;

  /// No description provided for @writeInYourDiary.
  ///
  /// In en, this message translates to:
  /// **'Time to write!'**
  String get writeInYourDiary;

  /// No description provided for @writeNoteHere.
  ///
  /// In en, this message translates to:
  /// **'Write your note here...'**
  String get writeNoteHere;

  /// No description provided for @writeYourThoughts.
  ///
  /// In en, this message translates to:
  /// **'Write your thoughts...'**
  String get writeYourThoughts;

  /// No description provided for @writingFrequency.
  ///
  /// In en, this message translates to:
  /// **'Writing Frequency'**
  String get writingFrequency;

  /// No description provided for @xpToNextLevel.
  ///
  /// In en, this message translates to:
  /// **'XP to next level'**
  String get xpToNextLevel;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// No description provided for @yellow.
  ///
  /// In en, this message translates to:
  /// **'Yellow'**
  String get yellow;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @yesterdayShort.
  ///
  /// In en, this message translates to:
  /// **'Y'**
  String get yesterdayShort;

  /// No description provided for @youAreFeeling.
  ///
  /// In en, this message translates to:
  /// **'You are feeling {mood}'**
  String youAreFeeling(Object mood);

  /// No description provided for @youWorked.
  ///
  /// In en, this message translates to:
  /// **'You worked'**
  String get youWorked;

  /// No description provided for @yourDevelopmentProgress.
  ///
  /// In en, this message translates to:
  /// **'Your Development Progress'**
  String get yourDevelopmentProgress;

  /// No description provided for @yourRecord.
  ///
  /// In en, this message translates to:
  /// **'Your record: {days} days'**
  String yourRecord(Object days);

  /// No description provided for @monthlyActivity.
  ///
  /// In en, this message translates to:
  /// **'Monthly Activity'**
  String get monthlyActivity;

  /// No description provided for @yearlyActivity.
  ///
  /// In en, this message translates to:
  /// **'Yearly Activity'**
  String get yearlyActivity;

  /// No description provided for @heatMap.
  ///
  /// In en, this message translates to:
  /// **'Heat Map'**
  String get heatMap;

  /// No description provided for @hourByDay.
  ///
  /// In en, this message translates to:
  /// **'Hour × Day'**
  String get hourByDay;

  /// No description provided for @less.
  ///
  /// In en, this message translates to:
  /// **'Less'**
  String get less;

  /// No description provided for @activityMoodCorrelation.
  ///
  /// In en, this message translates to:
  /// **'Activity-Mood Correlation'**
  String get activityMoodCorrelation;

  /// No description provided for @whichActivitiesImproveYourMood.
  ///
  /// In en, this message translates to:
  /// **'Which activities improve your mood?'**
  String get whichActivitiesImproveYourMood;

  /// No description provided for @trendAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Trend Analysis'**
  String get trendAnalysis;

  /// No description provided for @predictionBasedOnHistory.
  ///
  /// In en, this message translates to:
  /// **'Prediction based on history'**
  String get predictionBasedOnHistory;

  /// No description provided for @realData.
  ///
  /// In en, this message translates to:
  /// **'Real data'**
  String get realData;

  /// No description provided for @trend.
  ///
  /// In en, this message translates to:
  /// **'Trend'**
  String get trend;

  /// No description provided for @categoriesRadar.
  ///
  /// In en, this message translates to:
  /// **'Categories Radar'**
  String get categoriesRadar;

  /// No description provided for @categoryStudyLabel.
  ///
  /// In en, this message translates to:
  /// **'Study'**
  String get categoryStudyLabel;

  /// No description provided for @categoryWorkLabel.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get categoryWorkLabel;

  /// No description provided for @categoryExerciseLabel.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get categoryExerciseLabel;

  /// No description provided for @categoryReadingLabel.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get categoryReadingLabel;

  /// No description provided for @categoryWellnessLabel.
  ///
  /// In en, this message translates to:
  /// **'Wellness'**
  String get categoryWellnessLabel;

  /// No description provided for @categoryProgrammingLabel.
  ///
  /// In en, this message translates to:
  /// **'Programming'**
  String get categoryProgrammingLabel;

  /// No description provided for @categoryOtherLabel.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOtherLabel;

  /// No description provided for @behaviorPatterns.
  ///
  /// In en, this message translates to:
  /// **'Behavior Patterns'**
  String get behaviorPatterns;

  /// No description provided for @analysisByTimeOfDay.
  ///
  /// In en, this message translates to:
  /// **'Analysis by time of day'**
  String get analysisByTimeOfDay;

  /// No description provided for @periodMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get periodMorning;

  /// No description provided for @periodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get periodAfternoon;

  /// No description provided for @periodEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get periodEvening;

  /// No description provided for @periodNight.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get periodNight;

  /// No description provided for @mostActive.
  ///
  /// In en, this message translates to:
  /// **'Most active'**
  String get mostActive;

  /// No description provided for @moreProductiveDuringPeriod.
  ///
  /// In en, this message translates to:
  /// **'You are {percent}% more productive during the {period}'**
  String moreProductiveDuringPeriod(Object percent, Object period);

  /// No description provided for @waterTrackerTitle.
  ///
  /// In en, this message translates to:
  /// **'💧 Hydration'**
  String get waterTrackerTitle;

  /// No description provided for @waterGlasses.
  ///
  /// In en, this message translates to:
  /// **'glasses'**
  String get waterGlasses;

  /// No description provided for @waterAddGlass.
  ///
  /// In en, this message translates to:
  /// **'Drink water'**
  String get waterAddGlass;

  /// No description provided for @waterGoalReached.
  ///
  /// In en, this message translates to:
  /// **'Goal reached!'**
  String get waterGoalReached;

  /// No description provided for @waterRemaining.
  ///
  /// In en, this message translates to:
  /// **'{glasses} glasses remaining ({ml}ml)'**
  String waterRemaining(int glasses, int ml);

  /// No description provided for @waterSettings.
  ///
  /// In en, this message translates to:
  /// **'Hydration Settings'**
  String get waterSettings;

  /// No description provided for @waterGoalLabel.
  ///
  /// In en, this message translates to:
  /// **'Daily goal (glasses)'**
  String get waterGoalLabel;

  /// No description provided for @waterGlassSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Glass size'**
  String get waterGlassSizeLabel;

  /// No description provided for @waterTotalGoal.
  ///
  /// In en, this message translates to:
  /// **'Total goal: {ml}ml'**
  String waterTotalGoal(int ml);

  /// No description provided for @waterReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get waterReset;

  /// No description provided for @waterWidgetDescription.
  ///
  /// In en, this message translates to:
  /// **'Track your water intake'**
  String get waterWidgetDescription;

  /// No description provided for @preparando.
  ///
  /// In en, this message translates to:
  /// **'Preparing...'**
  String get preparando;

  /// No description provided for @errorInit.
  ///
  /// In en, this message translates to:
  /// **'Oops! Something went wrong'**
  String get errorInit;
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
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
