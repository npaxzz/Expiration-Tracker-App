import 'app_language.dart';
import '../models/food_item.dart';

class AppText {
  AppText._();

  static bool get _th => AppLanguage.currentLanguageCode == 'th';

  static String get home => _th ? 'หน้าหลัก' : 'Home';

  static String get alerts => _th ? 'แจ้งเตือน' : 'Alerts';

  static String get recipes => _th ? 'สูตรอาหาร' : 'Recipes';

  static String get settings => _th ? 'ตั้งค่า' : 'Settings';

  static String get language => _th ? 'ภาษา' : 'Language';

  static String get thai => 'ไทย';

  static String get english => 'English';

  static String get profile => _th ? 'โปรไฟล์' : 'Profile';

  static String get notifications => _th ? 'การแจ้งเตือน' : 'Notifications';

  static String get alertPreferences =>
      _th ? 'การตั้งค่าการแจ้งเตือน' : 'Alert Preferences';

  static String get about => _th ? 'เกี่ยวกับแอพ' : 'About App';

  static String get save => _th ? 'บันทึก' : 'Save';

  static String get cancel => _th ? 'ยกเลิก' : 'Cancel';

  static String get delete => _th ? 'ลบ' : 'Delete';

  static String get edit => _th ? 'แก้ไข' : 'Edit';

  static String get add => _th ? 'เพิ่ม' : 'Add';

  static String get close => _th ? 'ปิด' : 'Close';

  static String get confirm => _th ? 'ยืนยัน' : 'Confirm';

  static String get yes => _th ? 'ใช่' : 'Yes';

  static String get no => _th ? 'ไม่' : 'No';

  static String get addItem => _th ? 'เพิ่มรายการ' : 'Add Item';

  static String get editItem => _th ? 'แก้ไขรายการ' : 'Edit Item';

  static String get productName => _th ? 'ชื่อสินค้า *' : 'Product Name *';

  static String get category => _th ? 'หมวดหมู่ *' : 'Category *';

  static String get expirationDate =>
      _th ? 'วันหมดอายุ *' : 'Expiration Date *';

  static String get quantity => _th ? 'จำนวน' : 'Quantity';

  static String get note => _th ? 'หมายเหตุ' : 'Note';

  static String get notes => _th ? 'หมายเหตุ' : 'Notes';

  static String get productImage => _th ? 'รูปภาพสินค้า' : 'Product Image';

  static String get scan => _th ? 'สแกน' : 'Scan';

  static String get scanProduct => _th ? 'สแกนสินค้า' : 'Scan Product';

  static String get scanWithAi => _th ? 'สแกนด้วย AI' : 'Scan with AI';

  static String get review => _th ? 'ตรวจสอบข้อมูล' : 'Review';

  static String get analyze => _th ? 'วิเคราะห์' : 'Analyze';

  static String get enableNotifications =>
      _th ? 'เปิดการแจ้งเตือน' : 'Enable Notifications';

  static String get dailyReminder =>
      _th ? 'การแจ้งเตือนประจำวัน' : 'Daily Reminder';

  static String get alertDaysBefore =>
      _th ? 'แจ้งเตือนล่วงหน้า' : 'Alert Days Before';

  static String get pleaseEnterProductName =>
      _th ? 'กรุณาใส่ชื่อสินค้า' : 'Please enter a product name';

  static String get pleaseSelectCategory =>
      _th ? 'กรุณาเลือกหมวดหมู่' : 'Please select a category';

  static String get pleaseSelectExpirationDate =>
      _th ? 'กรุณาเลือกวันหมดอายุ' : 'Please select an expiration date';

  static String get pleaseAddProductImage =>
      _th ? 'กรุณาเพิ่มรูปภาพสินค้า' : 'Please add a product image';
  static String get totalItems => _th ? 'รายการทั้งหมด' : 'Total Items';

  static String get expiringSoon => _th ? 'ใกล้หมดอายุ' : 'Expiring Soon';

  static String get noItemsHere => _th ? 'ยังไม่มีรายการ' : 'No items here';

  static String get tapToAddFirstItem =>
      _th ? 'กด + เพื่อเพิ่มรายการแรกของคุณ' : 'Tap + to add your first item';

  static String get deleteItemQuestion => _th ? 'ลบรายการนี้?' : 'Delete Item?';

  static String removeItemMessage(String name) =>
      _th ? 'นำ "$name" ออกจากตู้เย็น?' : 'Remove "$name" from your fridge?';

  static String itemRemoved(String name) =>
      _th ? 'นำ $name ออกแล้ว' : '$name removed';

  static String get addedToFridge =>
      _th ? 'เพิ่มลงในตู้เย็นแล้ว!' : 'Added to fridge!';

  static String get couldNotSaveProductImage =>
      _th ? 'ไม่สามารถบันทึกรูปภาพสินค้าได้' : 'Could not save product image';
  static String get all => _th ? 'ทั้งหมด' : 'All';

  static String categoryName(FoodCategory category) {
    if (!_th) {
      return category.displayName;
    }

    switch (category) {
      case FoodCategory.fruitsVegetables:
        return 'ผักและผลไม้';

      case FoodCategory.eggsDairy:
        return 'ไข่และผลิตภัณฑ์จากนม';

      case FoodCategory.meatFrozen:
        return 'เนื้อสัตว์และอาหารแช่แข็ง';

      case FoodCategory.dryFood:
        return 'อาหารแห้ง';

      case FoodCategory.cannedBottled:
        return 'อาหารกระป๋อง เครื่องดื่ม และเครื่องปรุง';

      case FoodCategory.bakerySnacks:
        return 'เบเกอรี่และขนมขบเคี้ยว';
    }
  }

  static String get addNewItem => _th ? 'เพิ่มรายการใหม่' : 'Add New Item';

  static String get addPhoto => _th ? 'เพิ่มรูปภาพ' : 'Add Photo';

  static String get camera => _th ? 'กล้อง' : 'Camera';

  static String get gallery => _th ? 'แกลเลอรี' : 'Gallery';

  static String get removePhoto => _th ? 'ลบรูปภาพ' : 'Remove Photo';

  static String get photoAdded => _th ? 'เพิ่มรูปภาพแล้ว' : 'Photo added';

  static String get change => _th ? 'เปลี่ยน' : 'Change';

  static String get chooseFromGallery =>
      _th ? 'เลือกจากแกลเลอรี' : 'Choose from gallery';

  static String get takePhotoOrChooseFromGallery => _th
      ? 'ถ่ายรูปหรือเลือกจากแกลเลอรี'
      : 'Take a photo or choose from gallery';

  static String get itemName => _th ? 'ชื่อรายการ *' : 'Item Name *';

  static String get itemNameHint =>
      _th ? 'เช่น นมออร์แกนิก' : 'e.g. Organic Milk';

  static String get pleaseEnterName =>
      _th ? 'กรุณาใส่ชื่อสินค้า' : 'Please enter a name';

  static String get expirationDateRequired =>
      _th ? 'วันหมดอายุ *' : 'Expiration Date *';

  static String get selectCategoryFirst =>
      _th ? 'กรุณาเลือกหมวดหมู่ก่อน' : 'Select category first';

  static String get selectExpirationDate =>
      _th ? 'กรุณาเลือกวันหมดอายุ' : 'Select expiration date';

  static String get alreadyExpired => _th ? 'หมดอายุแล้ว!' : 'Already expired!';

  static String get expiresToday => _th ? 'หมดอายุวันนี้' : 'Expires today';

  static String expiresInDays(int days) =>
      _th ? 'หมดอายุใน $days วัน' : 'Expires in $days days';

  static String get notesOptional =>
      _th ? 'หมายเหตุ (ไม่บังคับ)' : 'Notes (optional)';

  static String get addAnyNotes =>
      _th ? 'เพิ่มหมายเหตุ...' : 'Add any notes...';

  static String get saveChanges =>
      _th ? 'บันทึกการเปลี่ยนแปลง' : 'Save Changes';

  static String get addToFridge => _th ? 'เพิ่มลงในตู้เย็น' : 'Add to Fridge';

  static String get couldNotOpenCameraGallery => _th
      ? 'ไม่สามารถเปิดกล้องหรือแกลเลอรีได้'
      : 'Could not open camera/gallery';

  static String get couldNotSaveItem =>
      _th ? 'ไม่สามารถบันทึกรายการได้' : 'Could not save item';

  static String couldNotSaveItemWithError(Object error) =>
      _th ? 'ไม่สามารถบันทึกรายการได้: $error' : 'Could not save item: $error';

  static String couldNotOpenCameraGalleryWithError(Object error) => _th
      ? 'ไม่สามารถเปิดกล้องหรือแกลเลอรีได้: $error'
      : 'Could not open camera/gallery: $error';

  static String get reviewResult => _th ? 'ผลการตรวจสอบ' : 'Review Result';

  static String get defaultDate => _th ? 'วันที่เริ่มต้น' : 'Default date';

  static String get expiryDetected =>
      _th ? 'วันหมดอายุ: ตรวจพบ' : 'Expiry: detected';

  static String get expiryNotFoundDefault => _th
      ? 'วันหมดอายุ: ไม่พบ → ใช้ค่าเริ่มต้น'
      : 'Expiry: not found → default';

  static String get categoryDetected =>
      _th ? 'หมวดหมู่: ตรวจพบ' : 'Category: detected';

  static String get reviewAndEditBeforeSaving => _th
      ? 'ตรวจสอบและแก้ไขข้อมูลด้านล่างก่อนบันทึก'
      : 'Review and edit below before saving';

  static String get aiDetected => _th ? 'AI ตรวจพบ' : 'AI detected';

  static String get ocrDetected => _th ? 'ตรวจพบด้วย OCR' : 'OCR detected';

  static String get defaultNoLabel =>
      _th ? 'ค่าเริ่มต้น (ไม่พบฉลาก)' : 'Default (no label)';

  static String get saving => _th ? 'กำลังบันทึก...' : 'Saving...';

  static String get confirmAndAddToFridge =>
      _th ? 'ยืนยันและเพิ่มลงในตู้เย็น' : 'Confirm & Add to Fridge';
  static String get removeFromFridge =>
      _th ? 'นำออกจากตู้เย็น' : 'Remove from Fridge';

  static String get added => _th ? 'เพิ่มเมื่อ' : 'Added';

  static String get deleteItem => _th ? 'ลบรายการ' : 'Delete Item';

  static String expiredDaysAgo(int days) =>
      _th ? 'หมดอายุมาแล้ว $days วัน' : 'Expired $days days ago';

  static String get expiresTodayBang =>
      _th ? 'หมดอายุวันนี้!' : 'Expires today!';

  static String expiresInDaysDetail(int days) =>
      _th ? 'หมดอายุใน $days วัน' : 'Expires in $days days';

  static String get expired => _th ? 'หมดอายุแล้ว' : 'Expired';

  static String get allGood => _th ? 'ทุกอย่างเรียบร้อย! 🎉' : 'All Good! 🎉';

  static String get noExpiringItems => _th
      ? 'ยังไม่มีรายการที่ใกล้หมดอายุ\nตู้เย็นของคุณยังอยู่ในสภาพดี!'
      : 'No expiring items right now.\nYour fridge is in great shape!';

  static String quantityShort(int quantity) =>
      _th ? 'จำนวน: $quantity' : 'Qty: $quantity';

  static String itemCount(int count) =>
      _th ? '$count รายการ' : '$count item${count > 1 ? 's' : ''}';

  static String get recipeIdeas => _th ? 'ไอเดียสูตรอาหาร' : 'Recipe Ideas';

  static String get getNewSuggestions =>
      _th ? 'รับคำแนะนำใหม่' : 'Get new suggestions';

  static String get findingNewRecipes =>
      _th ? 'กำลังค้นหาสูตรอาหารใหม่...' : 'Finding new recipes...';

  static String get prioritizingExpiringIngredients => _th
      ? 'กำลังเน้นวัตถุดิบที่ใกล้หมดอายุ'
      : 'Prioritizing expiring ingredients';

  static String get couldNotGetRecipes =>
      _th ? 'ไม่สามารถรับสูตรอาหารได้' : 'Could not get recipes';

  static String get tryAgain => _th ? 'ลองอีกครั้ง' : 'Try Again';

  static String get readyToCook =>
      _th ? 'พร้อมทำอาหารหรือยัง?' : 'Ready to cook?';

  static String get findRecipeIdeas => _th
      ? 'ค้นหาไอเดียสูตรอาหารจากวัตถุดิบของคุณ'
      : 'Find recipe ideas based on your ingredients';

  static String get findRecipes => _th ? 'ค้นหาสูตรอาหาร' : 'Find Recipes';

  static String get noIngredientsYet =>
      _th ? 'ยังไม่มีวัตถุดิบ' : 'No ingredients yet';

  static String get addFoodItemsFirst => _th
      ? 'เพิ่มรายการอาหารลงในตู้เย็นก่อน'
      : 'Add food items to your fridge first';

  static String get showingSavedRecipeIdeas => _th
      ? 'กำลังแสดงไอเดียสูตรอาหารที่บันทึกไว้ กดรีเฟรชเพื่อค้นหาสูตรใหม่'
      : 'Showing saved recipe ideas. Tap refresh to find new ones.';

  static String get recipesPrioritizeExpiringIngredients => _th
      ? 'สูตรอาหารจะเน้นวัตถุดิบที่ใกล้หมดอายุ'
      : 'Recipes prioritize your expiring ingredients';

  static String usesExpiring(int count) => _th
      ? '⏰ ใช้วัตถุดิบที่ใกล้หมดอายุ $count รายการ'
      : '⏰ Uses $count expiring';

  static String buyMore(int count) =>
      _th ? '🛒 ซื้อเพิ่ม $count รายการ' : '🛒 Buy $count more';

  static String get noShoppingNeeded =>
      _th ? '✅ ไม่ต้องซื้อเพิ่ม' : '✅ No shopping needed';

  static String get ingredientsYouHave =>
      _th ? '✅ วัตถุดิบที่มี' : '✅ Ingredients you have';

  static String get needToBuy => _th ? '🛒 ต้องซื้อ' : '🛒 Need to buy';

  static String get instructions => _th ? '📋 วิธีทำ' : '📋 Instructions';

  static String get photo1 => _th ? 'รูปภาพ 1' : 'Photo 1';
  static String get photo2 => _th ? 'รูปภาพ 2' : 'Photo 2';

  static String get optional => _th ? 'ไม่บังคับ' : 'Optional';

  static String get scanProductTitle => _th ? 'สแกนสินค้า' : 'Scan Product';

  static String get scanInfo => _th
      ? 'เพิ่มรูปภาพอย่างน้อย 1 รูป — AI จะตรวจจับชื่อ หมวดหมู่ และวันหมดอายุ — หากไม่มีฉลากวันหมดอายุ ระบบจะประมาณการตามหมวดหมู่\nเพิ่มรูปที่ 2 หากฉลากและสินค้าที่ต้องการสแกนอยู่คนละรูป'
      : 'Add 1 photo minimum — AI detects name, category & expiry date — If No expiry label, will estimate based on category\nAdd a 2nd photo if label and product are in separate images';

  static String get product => _th ? 'สินค้า' : 'Product';

  static String get productImageDescription => _th
      ? 'เพิ่มรูปที่แสดงลักษณะโดยรวมของสินค้า'
      : 'Add an image showing the overall appearance of the product';

  static String get expiryDate => _th ? 'วันหมดอายุ' : 'Expiry Date';

  static String get expiryImageDescription =>
      _th ? 'เพิ่มรูปที่มีวันหมดอายุ' : 'Add images with an expiration date';

  static String get analyzeWithAi =>
      _th ? 'วิเคราะห์ด้วย AI' : 'Analyze with AI';

  static String get enterManuallyInstead =>
      _th ? 'กรอกข้อมูลด้วยตนเอง' : 'Enter manually instead';

  static String get analyzing => _th ? 'กำลังวิเคราะห์...' : 'Analyzing...';

  static String processingPhotosWithAi(int count) => _th
      ? 'กำลังประมวลผล $count รูปด้วย AI'
      : 'Processing $count photos with AI';

  static String get processingPhotoWithAi =>
      _th ? 'กำลังประมวลผลรูปด้วย AI' : 'Processing photo with AI';

  static String get recipePreferenceTitle =>
      _th ? 'วันนี้อยากทานอะไร?' : 'Do you feel like eating today?';

  static String get pickAsManyAsYouLike => _th
      ? 'เลือกได้มากเท่าที่ต้องการในแต่ละหมวดหมู่'
      : 'Pick as many as you like in each category.';

  static String get tasteYouFeelLike =>
      _th ? 'รสชาติที่อยากทาน' : 'Taste you feel like';

  static String get cuisineStyle => _th ? 'สไตล์อาหาร' : 'Cuisine style';

  static String get menuType => _th ? 'ประเภทเมนู' : 'Menu type';

  static String get spicy => _th ? 'เผ็ด' : 'Spicy';
  static String get sweet => _th ? 'หวาน' : 'Sweet';
  static String get salty => _th ? 'เค็ม' : 'Salty';
  static String get sour => _th ? 'เปรี้ยว' : 'Sour';
  static String get wellBalanced => _th ? 'รสกลมกล่อม' : 'Well-balanced';

  static String get thaiCuisine => _th ? '🇹🇭 ไทย' : '🇹🇭 Thai';
  static String get japaneseCuisine => _th ? '🇯🇵 ญี่ปุ่น' : '🇯🇵 Japanese';
  static String get koreanCuisine => _th ? '🇰🇷 เกาหลี' : '🇰🇷 Korean';
  static String get chineseCuisine => _th ? '🇨🇳 จีน' : '🇨🇳 Chinese';
  static String get westernCuisine => _th ? '🌎 ตะวันตก' : '🌎 Western';

  static String get mainDish => _th ? '🍛 อาหารจานหลัก' : '🍛 Main dish';
  static String get noodles => _th ? '🍜 ก๋วยเตี๋ยว / เส้น' : '🍜 Noodles';
  static String get soupCurry => _th ? '🥘 ซุป / แกง' : '🥘 Soup / Curry';
  static String get lightMeal => _th ? '🥗 อาหารเบา ๆ' : '🥗 Light meal';
  static String get fridgeName => _th ? 'ชื่อ' : 'Name';
  static String get getAlertsNotification => _th
      ? 'เมื่อเปิดแอปจะแจ้งเตือนวัตถุดิบที่หมดอายุวันนี้'
      : 'Alert when items expire today (When you open the app)';

  static String get getMorningAlertsNotification => _th
      ? 'ตรวจสอบและแจ้งเตือนวันหมดอายุทุกวัน'
      : 'Check expiration dates every day';

  static String get dataStorage => _th ? 'พื้นที่จัดเก็บ' : 'Data Storage';
  static String get ocrandClass =>
      _th ? 'อ่านวันหมดอายุและจำแนกประเภท' : 'OCR & Classification Scanning';
  static String get version => _th ? 'เวอร์ชั่น' : 'Version';

  static String get aiScanFailed => _th
      ? 'ไม่สามารถวิเคราะห์ข้อมูลด้วย AI ได้ กรุณากรอกข้อมูลด้วยตนเอง'
      : 'Unable to analyze the image with AI. Please enter the information manually.';

  static String get recipeErrorGeneric =>
      AppLanguage.currentLanguageCode == 'th'
          ? 'ไม่สามารถสร้างสูตรอาหารใหม่ได้ กรุณาลองอีกครั้ง'
          : 'Unable to generate new recipes. Please try again.';

  static String get recipeErrorRateLimit =>
      AppLanguage.currentLanguageCode == 'th'
          ? 'ขณะนี้มีผู้ใช้งานจำนวนมาก กรุณารอสักครู่แล้วลองใหม่'
          : 'The recipe service is busy. Please wait a moment and try again.';

  static String get recipeErrorNetwork =>
      AppLanguage.currentLanguageCode == 'th'
          ? 'ไม่สามารถเชื่อมต่อได้ กรุณาตรวจสอบอินเทอร์เน็ตแล้วลองใหม่'
          : 'Unable to connect. Check your internet connection and try again.';

  static String get recipeErrorNoCache =>
      AppLanguage.currentLanguageCode == 'th'
          ? 'ไม่มีสูตรอาหารเก่าที่บันทึกไว้ให้แสดง'
          : 'No previously saved recipes are available.';
}
