import 'package:flutter_tts/flutter_tts.dart';

class TranslateService {
  final FlutterTts _tts = FlutterTts();

  // Mapping from app languages to TTS locales
  static const Map<String, String> localeMap = {
    'english': 'en-IN',
    'hindi': 'hi-IN',
    'tamil': 'ta-IN',
    'telugu': 'te-IN',
    'kannada': 'kn-IN',
  };

  TranslateService() {
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setVolume(1.0);
    await _tts.setSpeechRate(0.5); // Farmer-friendly slightly slower speech rate
    await _tts.setPitch(1.0);
  }

  Future<void> speak(String text, String language) async {
    final locale = localeMap[language.toLowerCase()] ?? 'en-IN';
    await _tts.setLanguage(locale);
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }

  // Localized UI string tables for farmers
  static const Map<String, Map<String, String>> _uiTranslations = {
    'en': {
      'app_name': 'Crop Doctor 🌿',
      'tagline': 'Healthy crops, healthy future.',
      'greeting': 'Hello Farmer 👋',
      'scan_leaf': 'Scan a Leaf',
      'scan_history': 'History',
      'encyclopedia': 'Encyclopedia',
      'settings': 'Settings',
      'dashboard': 'Dashboard',
      'total_scans': 'Total Scans',
      'diseased': 'Diseased',
      'healthy': 'Healthy',
      'farm_health': 'Farm Health',
      'onboarding_title': 'Welcome to Crop Doctor',
      'onboarding_subtitle': 'AI-powered crop disease detection assistant for Indian farmers',
      'enter_name': 'Enter your name',
      'enter_phone': 'Phone number',
      'get_started': 'Get Started',
      'select_language': 'Select Language',
      'camera_permission': 'Allow Camera Access',
      'location_permission': 'Allow Location Access',
      'saving': 'Saving scan details...',
      'confidence': 'AI Confidence',
      'severity': 'Severity',
      'affected_area': 'Affected Area',
      'symptoms': 'Symptoms',
      'treatment': 'Treatment Instructions',
      'prevention': 'Prevention Tips',
      'pesticide': 'Recommended Pesticide',
      'cost': 'Estimated Cost',
      'share_whatsapp': 'Share Report via WhatsApp',
      'read_treatment': 'Hear Treatment',
      'search_placeholder': 'Search crop or disease...',
      'filter_all': 'All Crops',
      'filter_severe': 'Severe Only',
      'filter_healthy': 'Healthy Only',
    },
    'hi': {
      'app_name': 'क्रॉप डॉक्टर 🌿',
      'tagline': 'स्वस्थ फसल, खुशहाल भविष्य।',
      'greeting': 'नमस्ते किसान भाई 👋',
      'scan_leaf': 'पत्ता स्कैन करें',
      'scan_history': 'इतिहास',
      'encyclopedia': 'फसल ज्ञानकोश',
      'settings': 'सेटिंग्स',
      'dashboard': 'डैशबोर्ड',
      'total_scans': 'कुल स्कैन',
      'diseased': 'बीमार',
      'healthy': 'स्वस्थ',
      'farm_health': 'खेत का स्वास्थ्य',
      'onboarding_title': 'क्रॉप डॉक्टर में आपका स्वागत है',
      'onboarding_subtitle': 'भारतीय किसानों के लिए एआई-संचालित फसल रोग पहचान सहायक',
      'enter_name': 'अपना नाम दर्ज करें',
      'enter_phone': 'फोन नंबर',
      'get_started': 'शुरू करें',
      'select_language': 'भाषा चुनें',
      'camera_permission': 'कैमरा अनुमति दें',
      'location_permission': 'स्थान अनुमति दें',
      'saving': 'स्कैन विवरण सहेज रहा है...',
      'confidence': 'एआई शुद्धता',
      'severity': 'गंभीरता',
      'affected_area': 'प्रभावित क्षेत्र',
      'symptoms': 'लक्षण',
      'treatment': 'उपचार के निर्देश',
      'prevention': 'बचाव के उपाय',
      'pesticide': 'अनुशंसित कीटनाशक',
      'cost': 'अनुमानित लागत',
      'share_whatsapp': 'व्हाट्सएप पर रिपोर्ट साझा करें',
      'read_treatment': 'उपचार सुनें',
      'search_placeholder': 'फसल या बीमारी खोजें...',
      'filter_all': 'सभी फसलें',
      'filter_severe': 'केवल गंभीर',
      'filter_healthy': 'केवल स्वस्थ',
    },
    'ta': {
      'app_name': 'பயிர் மருத்துவர் 🌿',
      'tagline': 'ஆரோக்கியமான பயிர்கள், ஆரோக்கியமான எதிர்காலம்.',
      'greeting': 'வணக்கம் விவசாயி 👋',
      'scan_leaf': 'இலையை ஸ்கேன் செய்',
      'scan_history': 'வரலாறு',
      'encyclopedia': 'பயிர் கலைக்களஞ்சியம்',
      'settings': 'அமைப்புகள்',
      'dashboard': 'டாஷ்போர்டு',
      'total_scans': 'மொத்த ஸ்கேன்கள்',
      'diseased': 'பாதிக்கப்பட்டது',
      'healthy': 'ஆரோக்கியமானது',
      'farm_health': 'பண்ணை ஆரோக்கியம்',
      'onboarding_title': 'பயிர் மருத்துவருக்கு உங்களை வரவேற்கிறோம்',
      'onboarding_subtitle': 'இந்திய விவசாயிகளுக்கான AI-மூலம் இயங்கும் பயிர் நோய் கண்டறியும் உதவியாளர்',
      'enter_name': 'உங்கள் பெயரை உள்ளிடவும்',
      'enter_phone': 'தொலைபேசி எண்',
      'get_started': 'தொடங்குங்கள்',
      'select_language': 'மொழியைத் தேர்ந்தெடுக்கவும்',
      'camera_permission': 'கேமரா அனுமதியை அனுமதிக்கவும்',
      'location_permission': 'இருப்பிட அனுமதியை அனுமதிக்கவும்',
      'saving': 'ஸ்கேன் விவரங்களைச் சேமிக்கிறது...',
      'confidence': 'AI துல்லியம்',
      'severity': 'தீவிரம்',
      'affected_area': 'பாதிக்கப்பட்ட பகுதி',
      'symptoms': 'அறிகுறிகள்',
      'treatment': 'சிகிச்சை வழிமுறைகள்',
      'prevention': 'தடுப்பு குறிப்புகள்',
      'pesticide': 'பரிந்துரைக்கப்பட்ட பூச்சிக்கொல்லி',
      'cost': 'மதிப்பிடப்பட்ட செலவு',
      'share_whatsapp': 'வாட்ஸ்அப் மூலம் அறிக்கை பகிரவும்',
      'read_treatment': 'சிகிச்சையைக் கேளுங்கள்',
      'search_placeholder': 'பயிர் அல்லது நோயைத் தேடுங்கள்...',
      'filter_all': 'அனைத்து பயிர்கள்',
      'filter_severe': 'தீவிரமானவை மட்டும்',
      'filter_healthy': 'ஆரோக்கியமானவை மட்டும்',
    },
    'te': {
      'app_name': 'క్రాప్ డాక్టర్ 🌿',
      'tagline': 'ఆరోగ్యకరమైన పంటలు, ఆరోగ్యకరమైన భవిష్యత్తు.',
      'greeting': 'నమస్కారం రైతు సోదరా 👋',
      'scan_leaf': 'ఆకును స్కాన్ చేయండి',
      'scan_history': 'చరిత్ర',
      'encyclopedia': 'పంట విజ్ఞాన సర్వస్వం',
      'settings': 'సెట్టింగులు',
      'dashboard': 'డ్యాష్‌బోర్డ్',
      'total_scans': 'మొత్తం స్కాన్‌లు',
      'diseased': 'వ్యాధి సోకినవి',
      'healthy': 'ఆరోగ్యకరమైనవి',
      'farm_health': 'పంట ఆరోగ్యం',
      'onboarding_title': 'క్రాప్ డాక్టర్‌కు స్వాగతం',
      'onboarding_subtitle': 'భారతీయ రైతుల కోసం పంట వ్యాధి గుర్తింపు AI సహాయకుడు',
      'enter_name': 'మీ పేరు నమోదు చేయండి',
      'enter_phone': 'ఫోన్ నంబర్',
      'get_started': 'ప్రారంభించండి',
      'select_language': 'భాషను ఎంచుకోండి',
      'camera_permission': 'కెమెరా అనుమతించండి',
      'location_permission': 'లొకేషన్ అనుమతించండి',
      'saving': 'వివరాలు సేవ్ అవుతున్నాయి...',
      'confidence': 'AI ఖచ్చితత్వం',
      'severity': 'తీవ్రత',
      'affected_area': 'ప్రభావిత ప్రాంతం',
      'symptoms': 'లక్షణాలు',
      'treatment': 'చికిత్స పద్ధతులు',
      'prevention': 'నివారణ చర్యలు',
      'pesticide': 'సిఫార్సు చేసిన పురుగుమందు',
      'cost': 'అంచనా వ్యయం',
      'share_whatsapp': 'వాట్సాప్ ద్వారా నివేదిక షేర్ చేయి',
      'read_treatment': 'చికిత్స వినండి',
      'search_placeholder': 'పంట లేదా వ్యాధిని వెతకండి...',
      'filter_all': 'అన్ని పంటలు',
      'filter_severe': 'తీవ్రమైనవి మాత్రమే',
      'filter_healthy': 'ఆరోగ్యకరమైనవి మాత్రమే',
    },
    'kn': {
      'app_name': 'ಕ್ರಾಪ್ ಡಾಕ್ಟರ್ 🌿',
      'tagline': 'ಆರೋಗ್ಯಕರ ಬೆಳೆ, ಉಜ್ವಲ ಭವಿಷ್ಯ.',
      'greeting': 'ನಮಸ್ಕಾರ ರೈತ ಬಾಂಧವರೇ 👋',
      'scan_leaf': 'ಎಲೆ ಸ್ಕ್ಯಾನ್ ಮಾಡಿ',
      'scan_history': 'ಇತಿಹಾಸ',
      'encyclopedia': 'ಬೆಳೆ ಮಾಹಿತಿ ಕೋಶ',
      'settings': 'ಸಂಯೋಜನೆಗಳು',
      'dashboard': 'ಡ್ಯಾಶ್‌ಬೋರ್ಡ್',
      'total_scans': 'ಒಟ್ಟು ಸ್ಕ್ಯಾನ್‌ಗಳು',
      'diseased': 'ರೋಗಗ್ರಸ್ತ',
      'healthy': 'ಆರೋಗ್ಯಕರ',
      'farm_health': 'ಬೆಳೆ ಆರೋಗ್ಯ ಸ್ಕೋರ್',
      'onboarding_title': 'ಕ್ರಾಪ್ ಡಾಕ್ಟರ್‌ಗೆ ಸ್ವಾಗತ',
      'onboarding_subtitle': 'ಭಾರತೀಯ ರೈತರಿಗಾಗಿ ಕೃತಕ ಬುದ್ಧಿಮತ್ತೆ ಆಧಾರಿತ ಬೆಳೆ ರೋಗ ಪತ್ತೆ ಸಹಾಯದ ಅಪ್ಲಿಕೇಶನ್',
      'enter_name': 'ನಿಮ್ಮ ಹೆಸರು ನಮೂದಿಸಿ',
      'enter_phone': 'ಮೊಬೈಲ್ ಸಂಖ್ಯೆ',
      'get_started': 'ಪ್ರಾರಂಭಿಸಿ',
      'select_language': 'ಭಾಷೆ ಆಯ್ಕೆಮಾಡಿ',
      'camera_permission': 'ಕ್ಯಾಮೆರಾ ಅನುಮತಿ ನೀಡಿ',
      'location_permission': 'ಸ್ಥಳದ ಅನುಮತಿ ನೀಡಿ',
      'saving': 'ಮಾಹಿತಿ ಉಳಿಸಲಾಗುತ್ತಿದೆ...',
      'confidence': 'AI ನಿಖರತೆ',
      'severity': 'ತೀವ್ರತೆ',
      'affected_area': 'ಬಾಧಿತ ಪ್ರದೇಶ',
      'symptoms': 'ಲಕ್ಷಣಗಳು',
      'treatment': 'ಚಿಕಿತ್ಸಾ ಕ್ರಮಗಳು',
      'prevention': 'ಮುನ್ನೆಚ್ಚರಿಕಾ ಕ್ರಮಗಳು',
      'pesticide': 'ಸೂಚಿಸಲಾದ ಕೀಟನಾಶಕ',
      'cost': 'ಅಂದಾಜು ವೆಚ್ಚ',
      'share_whatsapp': 'ವರದಿಯನ್ನು ವಾಟ್ಸಾಪ್‌ನಲ್ಲಿ ಹಂಚಿಕೊಳ್ಳಿ',
      'read_treatment': 'ಚಿಕಿತ್ಸೆ ಆಲಿಸಿ',
      'search_placeholder': 'ಬೆಳೆ ಅಥವಾ ರೋಗ ಹುಡುಕಿ...',
      'filter_all': 'ಎಲ್ಲಾ ಬೆಳೆಗಳು',
      'filter_severe': 'ತೀವ್ರ ರೋಗಗಳು ಮಾತ್ರ',
      'filter_healthy': 'ಆರೋಗ್ಯಕರ ಬೆಳೆಗಳು ಮಾತ್ರ',
    }
  };

  /// Returns localized string by key and target language name
  static String get(String key, String languageName) {
    String langCode = 'en';
    switch (languageName.toLowerCase()) {
      case 'hindi':
        langCode = 'hi';
        break;
      case 'tamil':
        langCode = 'ta';
        break;
      case 'telugu':
        langCode = 'te';
        break;
      case 'kannada':
        langCode = 'kn';
        break;
      default:
        langCode = 'en';
    }
    return _uiTranslations[langCode]?[key] ?? _uiTranslations['en']?[key] ?? key;
  }
}
