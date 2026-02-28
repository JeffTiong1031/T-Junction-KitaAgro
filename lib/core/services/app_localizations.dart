import 'package:flutter/material.dart';
import 'language_service.dart';

/// Central place for all translated strings in the app.
/// Usage: AppLocalizations.of(context).loginTitle
class AppLocalizations {
  final AppLanguage language;

  AppLocalizations(this.language);

  /// Convenience accessor from any widget
  static AppLocalizations of(BuildContext context) {
    final service = LanguageServiceProvider.of(context);
    return AppLocalizations(service.currentLanguage);
  }

  // ─── Mapping helper ─────────────────────────────────────────────────
  String _t(String en, String ms, String zh) {
    switch (language) {
      case AppLanguage.english:
        return en;
      case AppLanguage.malay:
        return ms;
      case AppLanguage.chinese:
        return zh;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  APP GENERAL
  // ═══════════════════════════════════════════════════════════════════════
  String get appTitle => _t('Kita Agro', 'Kita Agro', 'Kita Agro');

  // ═══════════════════════════════════════════════════════════════════════
  //  WELCOME SCREEN
  // ═══════════════════════════════════════════════════════════════════════
  String get welcomeTitle => _t(
    'Welcome to Kita Agro',
    'Selamat Datang ke Kita Agro',
    '欢迎使用 Kita Agro',
  );
  String get welcomeSubtitle => _t(
    'Empowering the next generation of farmers and agropreneurs.',
    'Memperkasakan generasi petani dan agropreneur seterusnya.',
    '赋能新一代农民和农业企业家。',
  );
  String get getStarted => _t('Get Started', 'Mula', '开始');

  // ═══════════════════════════════════════════════════════════════════════
  //  LOGIN SCREEN
  // ═══════════════════════════════════════════════════════════════════════
  String get loginTitle => _t('Kita Agro', 'Kita Agro', 'Kita Agro');
  String get email => _t('Email', 'Emel', '电子邮件');
  String get password => _t('Password', 'Kata Laluan', '密码');
  String get login => _t('Login', 'Log Masuk', '登录');
  String get signInWithGoogle =>
      _t('Sign in with Google', 'Log masuk dengan Google', '使用 Google 登录');
  String get dontHaveAccount =>
      _t("Don't have an account?", 'Belum mempunyai akaun?', '还没有账户?');
  String get register => _t('Register', 'Daftar', '注册');
  String get emailAndPasswordRequired => _t(
    'Please enter both email and password.',
    'Sila masukkan emel dan kata laluan.',
    '请输入电子邮件和密码。',
  );
  String get googleSignInFailed => _t(
    'Google Sign In failed or canceled.',
    'Log masuk Google gagal atau dibatalkan.',
    'Google 登录失败或已取消。',
  );
  String get selectLanguage => _t('Select Language', 'Pilih Bahasa', '选择语言');

  // ═══════════════════════════════════════════════════════════════════════
  //  REGISTER SCREEN
  // ═══════════════════════════════════════════════════════════════════════
  String get createAccount =>
      _t('Create your account', 'Cipta akaun anda', '创建您的账户');
  String get username => _t('Username', 'Nama Pengguna', '用户名');
  String get tellAboutYourself => _t(
    'Tell us about yourself',
    'Beritahu kami tentang diri anda',
    '告诉我们关于您自己',
  );
  String get fullName => _t('Full Name', 'Nama Penuh', '全名');
  String get age => _t('Age', 'Umur', '年龄');
  String get selectGender => _t('Select Gender', 'Pilih Jantina', '选择性别');
  String get male => _t('Male', 'Lelaki', '男');
  String get female => _t('Female', 'Perempuan', '女');
  String get preferNotToSay =>
      _t('Prefer not to say', 'Tidak mahu menyatakan', '不愿透露');
  String get whereAreYou =>
      _t('Where are you located?', 'Di mana lokasi anda?', '您在哪里?');
  String get townCity => _t('Town/City', 'Bandar/Bandaraya', '市镇/城市');
  String get state => _t('State', 'Negeri', '州');
  String get country => _t('Country', 'Negara', '国家');
  String get whatDescribesYou => _t(
    'What best describes you?',
    'Apakah yang paling menggambarkan anda?',
    '什么最能描述您?',
  );
  String get selectRole => _t('Select Role', 'Pilih Peranan', '选择角色');
  String get farmer => _t('Farmer', 'Petani', '农民');
  String get homeGrower => _t('Home Grower', 'Penanam Rumah', '家庭种植者');
  String get agronomist => _t('Agronomist', 'Ahli Agronomi', '农学家');
  String get businessCompany =>
      _t('Business Company', 'Syarikat Perniagaan', '商业公司');
  String get finish => _t('Finish', 'Selesai', '完成');
  String get next => _t('Next', 'Seterusnya', '下一步');
  String get pleaseFillAllFields =>
      _t('Please fill in all fields', 'Sila isi semua ruangan', '请填写所有字段');
  String get pleaseSelectRole =>
      _t('Please select a role', 'Sila pilih peranan', '请选择角色');
  String get pleaseEnterValidEmail => _t(
    'Please enter a valid email address',
    'Sila masukkan alamat emel yang sah',
    '请输入有效的电子邮件地址',
  );
  String get passwordMinLength => _t(
    'Password must be at least 6 characters',
    'Kata laluan mesti sekurang-kurangnya 6 aksara',
    '密码必须至少6个字符',
  );
  String get usernameTaken => _t(
    'Username is already taken. Please choose another.',
    'Nama pengguna telah diambil. Sila pilih yang lain.',
    '用户名已被使用,请选择另一个。',
  );

  // ═══════════════════════════════════════════════════════════════════════
  //  COMPLETE PROFILE SCREEN
  // ═══════════════════════════════════════════════════════════════════════
  String get completeProfile =>
      _t('Complete Profile', 'Lengkapkan Profil', '完善个人资料');
  String get completeProfileMessage => _t(
    'Please complete your profile to continue.',
    'Sila lengkapkan profil anda untuk meneruskan.',
    '请完善您的个人资料以继续。',
  );
  String get gender => _t('Gender', 'Jantina', '性别');
  String get town => _t('Town', 'Bandar', '市镇');
  String get role => _t('Role', 'Peranan', '角色');
  String get buyer => _t('Buyer', 'Pembeli', '买家');
  String get investor => _t('Investor', 'Pelabur', '投资者');
  String get researcher => _t('Researcher', 'Penyelidik', '研究员');
  String get other => _t('Other', 'Lain-lain', '其他');
  String get saveAndContinue =>
      _t('Save & Continue', 'Simpan & Teruskan', '保存并继续');
  String get pleaseEnterAge =>
      _t('Please enter your age', 'Sila masukkan umur anda', '请输入您的年龄');
  String get pleaseEnterValidNumber => _t(
    'Please enter a valid number',
    'Sila masukkan nombor yang sah',
    '请输入有效数字',
  );
  String get pleaseEnterTown =>
      _t('Please enter your town', 'Sila masukkan bandar anda', '请输入您的市镇');
  String get pleaseEnterState =>
      _t('Please enter your state', 'Sila masukkan negeri anda', '请输入您的州');
  String get pleaseEnterCountry =>
      _t('Please enter your country', 'Sila masukkan negara anda', '请输入您的国家');

  // ═══════════════════════════════════════════════════════════════════════
  //  BOTTOM NAVIGATION
  // ═══════════════════════════════════════════════════════════════════════
  String get navHome => _t('Home', 'Utama', '首页');
  String get navFarmer => _t('Farmer', 'Petani', '农民');
  String get navScan => _t('Scan', 'Imbas', '扫描');
  String get navMessage => _t('Message', 'Mesej', '消息');
  String get navProfile => _t('Profile', 'Profil', '个人资料');

  // ═══════════════════════════════════════════════════════════════════════
  //  HOME SCREEN
  // ═══════════════════════════════════════════════════════════════════════
  String get searchHint => _t(
    'Search people, crops, pests...',
    'Cari orang, tanaman, perosak...',
    '搜索人物、作物、害虫...',
  );
  String get carbonEmissionReduction =>
      _t('Carbon Emission Reduction', 'Pengurangan Pelepasan Karbon', '碳排放减少');
  String get startPlantingToEarn => _t(
    'Start planting to earn impact',
    'Mula menanam untuk kesan positif',
    '开始种植以获得影响力',
  );
  String get today => _t('Today', 'Hari Ini', '今天');
  String get loading => _t('Loading...', 'Memuatkan...', '加载中...');
  String get unavailable => _t('Unavailable', 'Tidak tersedia', '不可用');
  String get setLocation => _t('Set Location', 'Tetapkan Lokasi', '设置位置');
  String get myJourney => _t('My Journey', 'Perjalanan Saya', '我的旅程');
  String get dictionary => _t('Dictionary', 'Kamus', '字典');
  String get aiAssistant => _t('AI Assistant', 'Pembantu AI', 'AI 助手');
  String get community => _t('Community', 'Komuniti', '社区');
  String get recommend => _t('Recommend', 'Cadangan', '推荐');
  String get market => _t('Market', 'Pasaran', '市场');
  String get qAndA => _t('Q&A', 'S&J', '问答');
  String get noPostsYet => _t(
    'No posts yet. Be the first to share!',
    'Belum ada siaran. Jadilah yang pertama berkongsi!',
    '还没有帖子。成为第一个分享的人!',
  );

  // ═══════════════════════════════════════════════════════════════════════
  //  FARMER SCREEN
  // ═══════════════════════════════════════════════════════════════════════
  String get farmerHub => _t('Farmer Hub', 'Hab Petani', '农民中心');
  String get agropreneurGuideline =>
      _t('Agropreneur\nGuideline', 'Panduan\nAgropreneur', '农业企业家\n指南');
  String get farmLandRental =>
      _t('Farm Land\nRental', 'Sewa Tanah\nPertanian', '农地\n出租');
  String get marketplaceAndMap =>
      _t('Marketplace &\nMap', 'Pasaran &\nPeta', '市场 &\n地图');
  String get pestDistribution =>
      _t('Pest\nDistribution', 'Taburan\nPerosak', '害虫\n分布');

  // ═══════════════════════════════════════════════════════════════════════
  //  SCAN / DIAGNOSTIC SCREEN
  // ═══════════════════════════════════════════════════════════════════════
  String get aiDiagnostics => _t('AI Diagnostics', 'Diagnostik AI', 'AI 诊断');
  String get analyzing => _t(
    'Agro AI is analyzing...',
    'Agro AI sedang menganalisis...',
    'Agro AI 正在分析...',
  );
  String get gallery => _t('Gallery', 'Galeri', '相册');
  String get camera => _t('Camera', 'Kamera', '相机');
  String get identifyPests =>
      _t('Identify Pests 🐞', 'Kenal Pasti Perosak 🐞', '识别害虫 🐞');
  String get identifyNutrients =>
      _t('Identify Nutrients 🍃', 'Kenal Pasti Nutrien 🍃', '识别营养 🍃');

  // ═══════════════════════════════════════════════════════════════════════
  //  MESSAGE SCREEN
  // ═══════════════════════════════════════════════════════════════════════
  String get search => _t('Search', 'Cari', '搜索');
  String get chats => _t('Chats', 'Sembang', '聊天');
  String get requests => _t('Requests', 'Permintaan', '请求');
  String get errorLoadingRequests =>
      _t('Error loading requests', 'Ralat memuatkan permintaan', '加载请求出错');
  String get noFriendRequestsYet =>
      _t('No friend requests yet', 'Belum ada permintaan rakan', '还没有好友请求');
  String get sentFriendRequest => _t(
    'Sent you a friend request',
    'Menghantar permintaan rakan kepada anda',
    '向您发送了好友请求',
  );
  String get addFriendsToChat => _t(
    'Add friends to start chatting!',
    'Tambah rakan untuk mula bersembang!',
    '添加好友开始聊天!',
  );
  String get tapToChat => _t('Tap to chat', 'Ketik untuk sembang', '点击聊天');

  // ═══════════════════════════════════════════════════════════════════════
  //  PROFILE SCREEN
  // ═══════════════════════════════════════════════════════════════════════
  String get userNotFound =>
      _t('User not found', 'Pengguna tidak dijumpai', '用户未找到');
  String get settingsComingSoon => _t(
    'Settings menu coming soon!',
    'Menu tetapan akan datang!',
    '设置菜单即将推出!',
  );
  String get personalDetails =>
      _t('Personal details', 'Maklumat peribadi', '个人详情');
  String get yearsOld => _t('years old', 'tahun', '岁');
  String get friends => _t('Friends', 'Rakan', '好友');
  String get posts => _t('Posts', 'Siaran', '帖子');
  String get seeAll => _t('See all', 'Lihat semua', '查看全部');
  String get noFriendsYet =>
      _t('No friends yet.', 'Belum mempunyai rakan.', '还没有好友。');
  String get noPostsFound =>
      _t('No posts found.', 'Tiada siaran dijumpai.', '未找到帖子。');
  String get createAPost => _t('Create a post', 'Cipta siaran', '创建帖子');
  String get editProfile => _t('Edit profile', 'Sunting profil', '编辑资料');
  String get logout => _t('Logout', 'Log Keluar', '退出登录');
  String get logOut => _t('Log Out', 'Log Keluar', '退出');
  String get logoutConfirm => _t(
    'Are you sure you want to logout?',
    'Adakah anda pasti mahu log keluar?',
    '您确定要退出登录吗?',
  );
  String get cancel => _t('Cancel', 'Batal', '取消');
  String get deletePost => _t('Delete Post', 'Padam Siaran', '删除帖子');
  String get deletePostConfirm => _t(
    'Are you sure you want to delete this post?',
    'Adakah anda pasti mahu memadam siaran ini?',
    '您确定要删除此帖子吗?',
  );
  String get delete => _t('Delete', 'Padam', '删除');
  String get like => _t('Like', 'Suka', '赞');
  String get comment => _t('Comment', 'Komen', '评论');
  String get send => _t('Send', 'Hantar', '发送');
  String get justNow => _t('Just now', 'Baru sahaja', '刚刚');
  String get comments => _t('Comments', 'Komen', '评论');
  String get writeAComment =>
      _t('Write a comment...', 'Tulis komen...', '写下评论...');
  String get noCommentsYet => _t('No comments yet', 'Belum ada komen', '还没有评论');
  String get beFirstToComment => _t(
    'Be the first to comment!',
    'Jadilah yang pertama berkomen!',
    '成为第一个评论的人！',
  );
  String get deleteComment => _t('Delete Comment', 'Padam Komen', '删除评论');
  String get deleteCommentConfirm => _t(
    'Are you sure you want to delete this comment?',
    'Adakah anda pasti mahu memadam komen ini?',
    '您确定要删除此评论吗？',
  );
  String get errorPostingComment =>
      _t('Error posting comment', 'Ralat menghantar komen', '发布评论出错');
  String get viewAllComments => _t('View all', 'Lihat semua', '查看全部');

  // ═══════════════════════════════════════════════════════════════════════
  //  EDIT PROFILE SCREEN
  // ═══════════════════════════════════════════════════════════════════════
  String get editProfileTitle => _t('Edit profile', 'Sunting profil', '编辑资料');
  String get save => _t('Save', 'Simpan', '保存');
  String get changePhoto => _t('Change photo', 'Tukar foto', '更换照片');
  String get name => _t('Name', 'Nama', '名字');
  String get bio => _t('Bio', 'Bio', '简介');

  // ═══════════════════════════════════════════════════════════════════════
  //  LANGUAGE SETTINGS
  // ═══════════════════════════════════════════════════════════════════════
  String get languageSetting => _t('Language', 'Bahasa', '语言');
  String get languageSettingDesc =>
      _t('Change app language', 'Tukar bahasa aplikasi', '更改应用语言');

  // ═══════════════════════════════════════════════════════════════════════
  //  MISC / SHARED
  // ═══════════════════════════════════════════════════════════════════════
  String get errorUpdatingProfile =>
      _t('Error updating profile', 'Ralat mengemas kini profil', '更新个人资料出错');
  String get errorSavingProfile =>
      _t('Error saving profile', 'Ralat menyimpan profil', '保存个人资料出错');

  // Helper for friend count + posts format
  String friendsAndPosts(int friendCount, int postCount) => _t(
    '$friendCount friends • $postCount posts',
    '$friendCount rakan • $postCount siaran',
    '$friendCount 好友 • $postCount 帖子',
  );

  // Helper for plant count
  String plantsContributing(int count) => _t(
    '$count ${count == 1 ? 'plant' : 'plants'} contributing',
    '$count tanaman menyumbang',
    '$count 棵植物正在贡献',
  );

  // ═══════════════════════════════════════════════════════════════════════
  //  AI ASSISTANT SCREEN
  // ═══════════════════════════════════════════════════════════════════════
  String get aiAssistantTitle =>
      _t('AI Plantation Assistant', 'Pembantu Perladangan AI', 'AI 种植助理');
  String get aiWelcomeMessage => _t(
    "Hello! I'm your AI Plantation Assistant. I can help you with:\n\n• Plant care advice\n• Pest & disease diagnosis\n• Growing tips for your region\n• Watering & fertilizer guidance\n• Weather-based recommendations\n\nWhat would you like to know?",
    "Hai! Saya pembantu perladangan AI anda. Saya boleh membantu anda dengan:\n\n• Nasihat penjagaan tanaman\n• Diagnosis perosak & penyakit\n• Tips penanaman untuk kawasan anda\n• Panduan penyiraman & baja\n• Cadangan berdasarkan cuaca\n\nApa yang anda ingin tahu?",
    "你好！我是你的AI种植助手。我可以帮助你：\n\n• 植物护理建议\n• 害虫和病害诊断\n• 适合你所在地区的种植技巧\n• 浇水和施肥指导\n• 基于天气的推荐\n\n你想了解什么？",
  );
  String get thinking => _t('Thinking...', 'Sedang berfikir...', '正在思考...');
  String get askAboutPlants => _t(
    'Ask about your plants...',
    'Tanya tentang tanaman anda...',
    '询问关于你的植物...',
  );

  // ═══════════════════════════════════════════════════════════════════════
  //  ANALYSIS RESULT SCREEN
  // ═══════════════════════════════════════════════════════════════════════
  String get pestAnalysisResult =>
      _t('Pest Analysis Result', 'Keputusan Analisis Perosak', '害虫分析结果');
  String get nutrientAnalysisResult =>
      _t('Nutrient Analysis Result', 'Keputusan Analisis Nutrien', '营养分析结果');
  String get diagnosisReport =>
      _t('Diagnosis Report:', 'Laporan Diagnosis:', '诊断报告：');
  String get pestNameLabel => _t('Pest Name', 'Nama Perosak', '害虫名称');
  String get deficiencyNameLabel =>
      _t('Deficiency Name', 'Nama Kekurangan', '缺乏症名称');
  String get threatLabel => _t('Threat', 'Ancaman', '威胁');
  String get symptomsLabel => _t('Symptoms', 'Gejala', '症状');
  String get solutionsLabel => _t('Solutions', 'Penyelesaian', '解决方案');
  String get outbreakReported => _t(
    '✅ Outbreak Reported! Alerting nearby farmers...',
    '✅ Wabak Dilaporkan! Memberi amaran kepada petani berhampiran...',
    '✅ 疫情已报告！正在通知附近的农民...',
  );
  String get reportOutbreakHelp => _t(
    'Is this a serious outbreak? Help other farmers by reporting it.',
    'Adakah ini wabak serius? Bantu petani lain dengan melaporkannya.',
    '这是严重的疫情吗？通过举报帮助其他农民。',
  );
  String get reportingLocation =>
      _t('Reporting Location...', 'Melaporkan Lokasi...', '正在报告位置...');
  String get reportOutbreak =>
      _t('REPORT OUTBREAK 🚨', 'LAPORKAN WABAK 🚨', '报告疫情 🚨');
  String get backToScan => _t('Back to Scan', 'Kembali ke Imbasan', '返回扫描');
  String get translating => _t('Translating...', 'Menterjemah...', '翻译中...');
  String get translationFailed => _t(
    'Translation failed. Please try again.',
    'Terjemahan gagal. Sila cuba lagi.',
    '翻译失败，请重试。',
  );
  String get originalEnglish =>
      _t('Original (English)', 'Asal (Inggeris)', '原文（英语）');
  String get viewingTranslation =>
      _t('Viewing translation', 'Melihat terjemahan', '正在查看翻译');

  // ═══════════════════════════════════════════════════════════════════════
  //  GRANT INTRO SCREEN
  // ═══════════════════════════════════════════════════════════════════════
  String get youngAgropreneurGrant =>
      _t('Young Agropreneur\nGrant', 'Geran Agropreneur\nMuda', '青年农业企业家\n补助金');
  String get acceleratingCareer => _t(
    'Accelerating Your Career in Agriculture',
    'Mempercepatkan Kerjaya Anda dalam Pertanian',
    '加速你的农业职业发展',
  );
  String get programOverview =>
      _t('Program Overview', 'Gambaran Program', '项目概述');
  String get programOverviewDesc => _t(
    'The Young Agropreneur Program (PAM) is designed for young individuals aged 18 to 45. It aims to support and encourage youth involvement in agri-entrepreneurship across the entire agricultural value chain.',
    'Program Agropreneur Muda (PAM) direka untuk individu muda berumur 18 hingga 45 tahun. Ia bertujuan menyokong dan menggalakkan penglibatan belia dalam keusahawanan pertanian merentasi seluruh rantaian nilai pertanian.',
    '青年农业企业家计划（PAM）专为18至45岁的年轻人设计。旨在支持和鼓励青年参与整个农业价值链的农业创业。',
  );
  String get empoweringNextGen => _t(
    'Empowering the next generation of agricultural entrepreneurs',
    'Memperkasakan generasi usahawan pertanian seterusnya',
    '赋能下一代农业企业家',
  );
  String get viewRequirements =>
      _t('VIEW REQUIREMENTS', 'LIHAT SYARAT', '查看要求');

  // ═══════════════════════════════════════════════════════════════════════
  //  GRANT REQUIREMENTS SCREEN
  // ═══════════════════════════════════════════════════════════════════════
  String get programRequirements =>
      _t('Program Requirements', 'Syarat Program', '项目要求');
  String get eligibilityRequirements =>
      _t('Eligibility & Requirements', 'Kelayakan & Syarat', '资格和要求');
  String get reviewCriteria => _t(
    'Review the criteria below to ensure you qualify',
    'Semak kriteria di bawah untuk memastikan anda layak',
    '查看以下标准以确保您符合条件',
  );
  String get programObjectives =>
      _t('Program Objectives', 'Objektif Program', '项目目标');
  String get objective1 => _t(
    'Attract youth aged 18-45 to venture into agriculture',
    'Menarik belia berumur 18-45 untuk menceburi pertanian',
    '吸引18-45岁的青年投身农业',
  );
  String get objective2 => _t(
    'Change perception of agriculture as a viable industry',
    'Mengubah persepsi pertanian sebagai industri yang berdaya maju',
    '改变对农业作为可行产业的认知',
  );
  String get objective3 => _t(
    'Increase income through technology',
    'Meningkatkan pendapatan melalui teknologi',
    '通过技术增加收入',
  );
  String get eligibilityReqs =>
      _t('Eligibility Requirements', 'Syarat Kelayakan', '资格要求');
  String get basicRequirements =>
      _t('Basic Requirements', 'Syarat Asas', '基本要求');
  String get generalEligibility =>
      _t('General eligibility criteria', 'Kriteria kelayakan am', '一般资格标准');
  String get req1 => _t('Malaysian citizen', 'Warganegara Malaysia', '马来西亚公民');
  String get req2 => _t(
    'Aged between 18 and 45 years',
    'Berumur antara 18 dan 45 tahun',
    '年龄在18至45岁之间',
  );
  String get req3 => _t(
    'Able to read, count, and write',
    'Boleh membaca, mengira, dan menulis',
    '能够阅读、计算和书写',
  );
  String get startupRequirements =>
      _t('Start-up Requirements', 'Syarat Permulaan', '启动要求');
  String get additionalCriteria => _t(
    'Additional criteria for new ventures',
    'Kriteria tambahan untuk usaha baharu',
    '新项目的附加标准',
  );
  String get startupReq1 => _t(
    'Aged between 18 and 43 years',
    'Berumur antara 18 dan 43 tahun',
    '年龄在18至43岁之间',
  );
  String get startupReq2 => _t(
    'Must attend technical training (unless exempted)',
    'Mesti menghadiri latihan teknikal (kecuali dikecualikan)',
    '必须参加技术培训（除非获得豁免）',
  );
  String get startupReq3 => _t(
    'Net income less than RM5,000 per month',
    'Pendapatan bersih kurang daripada RM5,000 sebulan',
    '每月净收入低于RM5,000',
  );
  String get startApplication =>
      _t('START APPLICATION', 'MULA PERMOHONAN', '开始申请');

  // ═══════════════════════════════════════════════════════════════════════
  //  GRANT TUTORIAL SCREEN
  // ═══════════════════════════════════════════════════════════════════════
  String get grantTutorial =>
      _t('Grant Application Tutorial', 'Tutorial Permohonan Geran', '补助金申请教程');
  String get previous => _t('Previous', 'Sebelumnya', '上一步');

  // ═══════════════════════════════════════════════════════════════════════
  //  LAND LISTING SCREEN
  // ═══════════════════════════════════════════════════════════════════════
  String get farmLandRentalTitle =>
      _t('Farm Land Rental', 'Sewa Tanah Pertanian', '农地出租');
  String get searchByTitleOrLocation => _t(
    'Search by title or location...',
    'Cari mengikut tajuk atau lokasi...',
    '按标题或位置搜索...',
  );
  String get allStates => _t('All States', 'Semua Negeri', '所有州');
  String get anyPrice => _t('Any Price', 'Mana-mana Harga', '任何价格');
  String get forRent => _t('For Rent', 'Untuk Disewa', '出租');
  String get contactOwner => _t('Contact Owner', 'Hubungi Pemilik', '联系业主');
  String get contactOwnerInfo => _t(
    'Contact owner for further information',
    'Hubungi pemilik untuk maklumat lanjut',
    '联系业主获取更多信息',
  );
  String get ownerPhoneNumber =>
      _t('Owner Phone Number:', 'Nombor Telefon Pemilik:', '业主电话号码：');
  String get close => _t('Close', 'Tutup', '关闭');
  String get noLandsFound =>
      _t('No lands found', 'Tiada tanah dijumpai', '未找到土地');

  // ═══════════════════════════════════════════════════════════════════════
  //  NOTIFICATION SCREEN
  // ═══════════════════════════════════════════════════════════════════════
  String get notifications => _t('Notifications', 'Pemberitahuan', '通知');
  String get clearAll => _t('Clear All', 'Padam Semua', '全部清除');
  String get noNewAlerts => _t(
    'No new alerts. Your crops are safe!',
    'Tiada amaran baharu. Tanaman anda selamat!',
    '没有新警报。您的作物安全！',
  );

  // ═══════════════════════════════════════════════════════════════════════
  //  MY GARDEN (HOME SCREEN)
  // ═══════════════════════════════════════════════════════════════════════
  String get myGarden => _t('My Garden', 'Kebun Saya', '我的花园');
  String get communityMember => _t('Community Member', 'Ahli Komuniti', '社区成员');
  String get home => _t('Home', 'Rumah', '首页');

  // Plant card — health labels
  String healthLabel(String status) =>
      _t('Health: $status', 'Kesihatan: $status', '健康状况: $status');
  String get healthy => _t('Healthy', 'Sihat', '健康');
  String get stable => _t('Stable', 'Stabil', '稳定');
  String get needsAttention => _t('Needs Attention', 'Perlu Perhatian', '需要关注');
  String get critical => _t('Critical', 'Kritikal', '危急');
  String get noPhotoAnalysis =>
      _t('No photo analysis yet', 'Belum ada analisis foto', '尚无照片分析');
  String get growthProgress =>
      _t('Growth Progress', 'Kemajuan Pertumbuhan', '生长进度');
  String daysToHarvest(int days) =>
      _t('$days days to harvest', '$days hari lagi untuk tuai', '$days 天收获');

  // Garden empty / error states
  String get noPlantationsYet =>
      _t('No plantations yet', 'Belum ada tanaman', '尚无种植');
  String get addFirstPlant => _t(
    'Add your first plant to start tracking growth.',
    'Tambah tanaman pertama anda untuk mula menjejak pertumbuhan.',
    '添加您的第一棵植物来开始跟踪生长。',
  );
  String get addPlantation => _t('Add Plantation', 'Tambah Tanaman', '添加种植');
  String get gardenLoadError => _t(
    'Unable to load your garden right now.',
    'Tidak dapat memuatkan kebun anda sekarang.',
    '暂时无法加载您的花园。',
  );

  // Daily Tasks / Reminder card
  String get dailyTasks => _t('Daily Tasks', 'Tugas Harian', '每日任务');
  String get reminder => _t('Reminder', 'Peringatan', '提醒');
  String get addYourFirstPlant =>
      _t('Add your first plant', 'Tambah tanaman pertama anda', '添加您的第一棵植物');
  String get allTasksDoneToday => _t(
    'All tasks done today!',
    'Semua tugas selesai hari ini!',
    '今天所有任务已完成！',
  );
  String tasksPending(int count) => _t(
    '$count task${count > 1 ? 's' : ''} pending',
    '$count tugas belum selesai',
    '$count 个任务待完成',
  );

  // Weather advice
  String get weatherSkipWatering =>
      _t('☔ Skip watering today', '☔ Langkau penyiraman hari ini', '☔ 今天跳过浇水');
  String get weatherNaturalWatering => _t(
    '🌧️ Natural watering expected',
    '🌧️ Penyiraman semula jadi dijangka',
    '🌧️ 预计自然灌溉',
  );
  String get weatherTooHot => _t(
    '🔥 Too hot, provide shade',
    '🔥 Terlalu panas, berikan tedung',
    '🔥 太热了，提供遮阳',
  );
  String get weatherHotDay => _t(
    '☀️ Hot day, check soil moisture',
    '☀️ Hari panas, periksa kelembapan tanah',
    '☀️ 天气热，检查土壤湿度',
  );
  String get weatherPerfect => _t(
    '✅ Perfect for most crops',
    '✅ Sesuai untuk kebanyakan tanaman',
    '✅ 适合大多数作物',
  );
  String get weatherGood => _t(
    '👍 Good growing conditions',
    '👍 Keadaan pertumbuhan baik',
    '👍 良好的生长条件',
  );
  String get weatherPleasant => _t(
    '🌤️ Pleasant, water normally',
    '🌤️ Menyenangkan, siram seperti biasa',
    '🌤️ 宜人，正常浇水',
  );
  String get weatherCool => _t(
    '❄️ Cool, reduce watering',
    '❄️ Sejuk, kurangkan penyiraman',
    '❄️ 凉爽，减少浇水',
  );
  String get weatherCheck =>
      _t('🌱 Check plant needs', '🌱 Semak keperluan tumbuhan', '🌱 检查植物需求');

  // My Journey — photo analysis
  String get analyzePhotoTitle =>
      _t('Analyze Plant Photo', 'Analisis Foto Tumbuhan', '分析植物照片');
  String get useCameraCapture => _t(
    'Use camera to capture plant',
    'Gunakan kamera untuk tangkap tumbuhan',
    '使用相机拍摄植物',
  );
  String get chooseFromGallery =>
      _t('Choose from Gallery', 'Pilih dari Galeri', '从相册选择');
  String get uploadExistingPhoto =>
      _t('Upload an existing photo', 'Muat naik foto sedia ada', '上传现有照片');
  String get couldNotAnalyze => _t(
    'Could not analyze photo. Try again.',
    'Tidak dapat menganalisis foto. Cuba lagi.',
    '无法分析照片，请重试。',
  );
  String get apiLimitReached => _t(
    'API limit reached. Please try again later.',
    'Had API tercapai. Sila cuba lagi nanti.',
    'API限额已达到，请稍后重试。',
  );
  String get photoAnalysis => _t('Photo Analysis', 'Analisis Foto', '照片分析');
  String get noPhotoYet => _t('No photo yet', 'Belum ada foto', '暂无照片');
  String get progress => _t('Progress', 'Kemajuan', '进度');
  String get days => _t('days', 'hari', '天');
  String daysUntilHarvest(int days) => _t(
    '$days day${days > 1 ? 's' : ''} until harvest',
    '$days hari lagi untuk tuai',
    '$days 天到收获',
  );
  String get readyToHarvest =>
      _t('Ready to harvest!', 'Sedia untuk dituai!', '准备收获！');
  String tasksCount(int completed, int total) => _t(
    '$completed/$total tasks',
    '$completed/$total tugas',
    '$completed/$total 任务',
  );
  String get sortBy => _t('Sort by', 'Susun mengikut', '排序方式');
  String get newest => _t('Newest', 'Terbaru', '最新');
  String get daysPlantedLabel => _t('Days Planted', 'Hari Ditanam', '种植天数');
  String get health => _t('Health', 'Kesihatan', '健康');
  String get errorLoadingGarden =>
      _t('Error loading your garden', 'Ralat memuatkan kebun anda', '加载花园出错');
  String get gardenEmpty =>
      _t('Your garden is empty', 'Kebun anda kosong', '您的花园是空的');
  String get addPlantsToStart => _t(
    'Add plants from the Dictionary to get started!',
    'Tambah tumbuhan dari Kamus untuk bermula!',
    '从字典中添加植物开始吧！',
  );
  String get myGardenLocation =>
      _t('My Garden Location', 'Lokasi Kebun Saya', '我的花园位置');
  String removePlantConfirmation(String plantName) => _t(
    'Are you sure you want to remove "$plantName" from your garden?',
    'Adakah anda pasti mahu memadam "$plantName" dari kebun anda?',
    '确定要从花园中移除“$plantName”吗？',
  );
  String get deletePlantTitle => _t('Delete Plant', 'Padam Tumbuhan', '删除植物');

  // Dictionary screen
  String get plantDictionary =>
      _t('Plant Dictionary', 'Kamus Tumbuhan', '植物字典');
  String get cost => _t('Cost', 'Kos', '成本');
  String get difficulty => _t('Difficulty', 'Kesukaran', '难度');
  String get all => _t('All', 'Semua', '全部');
  String get vegetables => _t('Vegetables', 'Sayuran', '蔬菜');
  String get fruits => _t('Fruits', 'Buah-buahan', '水果');
  String get herbs => _t('Herbs', 'Herba', '草药');
  String get low => _t('Low', 'Rendah', '低');
  String get medium => _t('Medium', 'Sederhana', '中等');
  String get high => _t('High', 'Tinggi', '高');
  String get easy => _t('Easy', 'Mudah', '简单');
  String get hard => _t('Hard', 'Sukar', '困难');
  String get growthTimeLabel => _t('Growth Time', 'Masa Pertumbuhan', '生长时间');
  String get sunlight => _t('Sunlight', 'Cahaya Matahari', '阳光');
  String get watering => _t('Watering', 'Penyiraman', '浇水');
  String get soil => _t('Soil', 'Tanah', '土壤');
  String get carbonReductionLabel =>
      _t('Carbon Reduction', 'Pengurangan Karbon', '碳减排');
  String get growthStages =>
      _t('Growth Stages', 'Peringkat Pertumbuhan', '生长阶段');
  String get materialsNeeded =>
      _t('Materials Needed', 'Bahan Yang Diperlukan', '所需材料');
  String get addToMyGarden =>
      _t('Add to My Garden', 'Tambah ke Kebun Saya', '添加到我的花园');
  String plantAddedToGarden(String plantName) => _t(
    '$plantName added to your garden!',
    '$plantName ditambah ke kebun anda!',
    '$plantName 已添加到您的花园！',
  );
  String get pleaseSignIn => _t(
    'Please sign in to add plants.',
    'Sila log masuk untuk menambah tumbuhan.',
    '请登录以添加植物。',
  );
  String get aboutLabel => _t('About', 'Mengenai', '关于');
  String get growingGuide => _t('Growing Guide', 'Panduan Menanam', '种植指南');
  String get localClimateMatch =>
      _t('Local Climate Match', 'Padanan Iklim Tempatan', '当地气候匹配度');
  String forLocation(String location) =>
      _t('for $location', 'untuk $location', '$location的');
  String get carbonImpact => _t('Carbon Impact', 'Kesan Karbon', '碳影响');
  String get saveLocationForAdvice => _t(
    'Save your garden location in My Journey for personalized local advice!',
    'Simpan lokasi kebun anda di Perjalanan Saya untuk nasihat tempatan peribadi!',
    '在“我的旅程”中保存您的花园位置以获取个性化的本地建议！',
  );
  String get excellentMatch =>
      _t('Excellent Match', 'Padanan Cemerlang', '极佳匹配');
  String get goodMatch => _t('Good Match', 'Padanan Baik', '良好匹配');
  String get challengingMatch => _t('Challenging', 'Mencabar', '具挑战性');
  String get aiAnalyzingLocalConditions => _t(
    '🤖 AI is analyzing local conditions...',
    '🤖 AI sedang menganalisis keadaan...',
    '🤖 AI 正在分析当地情况...',
  );

  // Dictionary AI Fallback Advice Translations
  String get fallbackVegetableCarbon => _t(
    'About 2-3 kg CO₂/year reduction',
    'Sekitar 2-3 kg pengurangan CO₂/tahun',
    '大约减少 2-3 公斤二氧化碳/年',
  );
  String get fallbackHerbCarbon => _t(
    'About 1-2 kg CO₂/year reduction',
    'Sekitar 1-2 kg pengurangan CO₂/tahun',
    '大约减少 1-2 公斤二氧化碳/年',
  );
  String get fallbackFruitCarbon => _t(
    'About 5-12 kg CO₂/year reduction',
    'Sekitar 5-12 kg pengurangan CO₂/tahun',
    '大约减少 5-12 公斤二氧化碳/年',
  );
  String get fallbackDefaultCarbon => _t(
    'About 3-5 kg CO₂/year reduction',
    'Sekitar 3-5 kg pengurangan CO₂/tahun',
    '大约减少 3-5 公斤二氧化碳/年',
  );
  String fallbackGrowingContext(String plant, String location) => _t(
    '$plant is suitable in $location conditions.',
    '$plant sesuai dalam keadaan $location.',
    '$plant 适合 $location 的环境。',
  );
  String get fallbackDifficulty => _t(
    'Moderate - monitor weather and pests',
    'Sederhana - pantau cuaca dan perosak',
    '中等 - 注意天气和害虫',
  );
  String get fallbackSunlight => _t(
    '4-6 hours sunlight daily',
    '4-6 jam cahaya matahari setiap hari',
    '每天 4-6 小时日照',
  );
  String get fallbackWateringHot => _t(
    'Water morning and late afternoon',
    'Siram pagi dan lewat petang',
    '早晚浇水',
  );
  String get fallbackWateringNormal =>
      _t('Water once daily', 'Siram sekali sehari', '每天浇水一次');
  String get fallbackSoil => _t(
    'Well-drained soil with compost',
    'Tanah bersaliran baik dengan kompos',
    '排水良好的堆肥土壤',
  );
  String get fallbackCompost => _t('Organic compost', 'Kompos organik', '有机堆肥');
  String get fallbackCompostPurpose =>
      _t('Improve soil fertility', 'Meningkatkan kesuburan tanah', '提高土壤肥力');
  String get fallbackMulch => _t('Mulch', 'Sungupan (Mulch)', '覆盖物');
  String get fallbackMulchPurpose =>
      _t('Keep moisture stable', 'Kekalkan kelembapan', '保持水分稳定');
  String get fallbackWateringCan => _t('Watering can', 'Penyiram', '浇水壶');
  String get fallbackWateringCanPurpose =>
      _t('Gentle root watering', 'Siraman lembut ke akar', '温和浇水');
  String get fallbackNeemSpray => _t('Neem spray', 'Semburan Neem', '苦楝油喷雾');
  String get fallbackNeemSprayPurpose =>
      _t('Prevent pests naturally', 'Cegah perosak secara semula jadi', '自然防虫');
  String get fallbackStageSeedling => _t('Seedling', 'Anak benih', '幼苗');
  String get fallbackStageSeedlingDesc =>
      _t('Establish roots', 'Membina akar', '扎根');
  String get fallbackStageVegetative => _t('Vegetative', 'Tumbesaran', '生长期');
  String get fallbackStageVegetativeDesc =>
      _t('Leaf and stem growth', 'Pertumbuhan daun dan batang', '长叶和茎');
  String get fallbackStageFlowering => _t('Flowering', 'Berbunga', '开花期');
  String get fallbackStageFloweringDesc =>
      _t('Flower formation', 'Pembentukan bunga', '形成花朵');
  String get fallbackStageMaturity => _t('Maturity', 'Kematangan', '成熟期');
  String get fallbackStageMaturityDesc =>
      _t('Harvest ready', 'Sedia untuk dituai', '可以收获');

  // Detailed Info (Dictionary)
  String growthTimeDetail(String location, String temp, String plantName) => _t(
    'Growth time varies based on your local climate conditions in $location. Factors like temperature ($temp°C), daylight hours, and seasonal patterns all affect how quickly $plantName matures.',
    'Masa tumbesaran bergantung pada keadaan iklim tempatan anda di $location. Faktor-faktor seperti suhu ($temp°C), tempoh cahaya siang, dan corak bermusim menjejaskan tempoh matang $plantName.',
    '$location 的当地气候会影响 $plantName 的生长周期。温度 ($temp°C)、日照时长以及季节性变化都会影响其成熟的速度。',
  );

  String difficultyDetail(String plantName, String location) => _t(
    'Difficulty rating considers climate compatibility, maintenance requirements, pest resistance, and how well $plantName adapts to $location conditions. Beginners should start with "Easy" rated plants.',
    'Tahap kesukaran mengambil kira kesesuaian iklim, keperluan penyelenggaraan, daya tahan perosak, dan kemampuan $plantName menyesuaikan diri di $location. Penanam baru disyorkan bermula dengan tanaman "Mudah".',
    '程度评级考虑了气候适应性、养护要求、病虫害抗性以及 $plantName 对 $location 环境的适应能力。初学者建议从“容易”等级的植物开始。',
  );

  String sunlightDetail(String location) => _t(
    'Sunlight requirements are crucial for photosynthesis and healthy growth. In $location, consider seasonal variations and provide shade during extremely hot periods. Morning sun is generally gentler than harsh afternoon sun.',
    'Keperluan cahaya matahari penting untuk fotosintesis dan pertumbuhan sihat. Di $location, beri perhatian pada perubahan musim dan sediakan tempat berteduh pada cuaca terlampau panas. Cahaya matahari pagi lebih lembut berbanding cahaya terik petang.',
    '日照要求对于光合作用和健康生长至关重要。在 $location，需考虑季节性变化，并在极端炎热时提供遮阴。早上的阳光通常比下午的烈日更温和。',
  );

  String wateringDetail(String condition, String temp) => _t(
    'Current weather: $condition at $temp°C. Adjust watering frequency based on rainfall, humidity, and soil moisture. Overwatering is a common mistake - check soil before watering.',
    'Cuaca semasa: $condition pada $temp°C. Selaraskan kekerapan penyiraman berdasarkan hujan, kelembapan, dan keadaan tanah. Penyiraman berlebihan adalah kesilapan biasa - periksa tanah sebelum menyiram.',
    '当前天气：$condition，气温 $temp°C。根据降雨量、湿度和土壤水分调整浇水频率。过度浇水是常见的错误 - 请在浇水前检查土壤。',
  );

  String soilDetail(String location) => _t(
    'Soil quality directly impacts nutrient availability and root health. In $location, amend soil based on local conditions. Good drainage prevents root rot, while organic matter improves fertility and water retention.',
    'Kualiti tanah memberi kesan terus kepada zat makanan dan kesihatan akar. Di $location, baiki kualiti tanah mengikut keadaan tempatan. Saliran yang baik mengelakkan reput akar, sementara bahan organik meningkatkan kesuburan.',
    '土壤质量直接影响养分的获取和根系的健康。在 $location，请根据当地情况调整土壤。良好的排水性能防止根腐病，而有机质则能提高肥力和保水性。',
  );

  String get localGrowingContext =>
      _t('Local Growing Context', 'Konteks Penanaman Tempatan', '当地种植环境');
  String currentTempWeather(String temp, String weather) => _t(
    '🌡️ Current: $temp°C, $weather',
    '🌡️ Semasa: $temp°C, $weather',
    '🌡️ 当前: $temp°C, $weather',
  );

  String getLocalizedPlantName(String englishName) {
    final lowerName = englishName.toLowerCase();
    if (lowerName == 'tomato') return _t('Tomato', 'Tomato', '番茄');
    if (lowerName == 'chili') return _t('Chili', 'Cili', '辣椒');
    if (lowerName == 'papaya') return _t('Papaya', 'Betik', '木瓜');
    if (lowerName == 'banana') return _t('Banana', 'Pisang', '香蕉');
    if (lowerName == 'strawberry') return _t('Strawberry', 'Strawberi', '草莓');
    if (lowerName == 'apple') return _t('Apple', 'Epal', '苹果');
    if (lowerName == 'pandan') return _t('Pandan', 'Pandan', '斑兰');
    return englishName;
  }

  String getLocalizedPlantDescription(String englishName) {
    final lowerName = englishName.toLowerCase();
    if (lowerName == 'tomato') {
      return _t(
        'A popular garden vegetable rich in vitamins A and C. Tomatoes are used in salads, sauces, and many cuisines worldwide.',
        'Sayuran popular yang kaya dengan vitamin A dan C. Tomato digunakan dalam salad, sos, dan pelbagai masakan di seluruh dunia.',
        '一种富含维生素 A 和 C 的流行园林蔬菜。番茄被广泛用于沙拉、酱汁和世界各地的许多菜肴中。',
      );
    }
    if (lowerName == 'chili') {
      return _t(
        'Spicy fruit used in many cuisines worldwide. Contains capsaicin which gives the heat.',
        'Buah pedas yang digunakan dalam banyak masakan. Mengandungi capsaicin yang memberikan rasa pedas.',
        '在世界许多菜肴中使用的辛辣果实。含有带来辣味的辣椒素。',
      );
    }
    if (lowerName == 'papaya') {
      return _t(
        'Tropical fruit with sweet orange flesh. Rich in enzymes and vitamins.',
        'Buah tropika dengan isi oren manis. Kaya dengan enzim dan vitamin.',
        '带有甜美橙色果肉的热带水果。富含酶和维生素。',
      );
    }
    if (lowerName == 'banana') {
      return _t(
        'Tropical fruit rich in potassium. Requires warm frost-free climate (above 10°C year-round). Dies at 0°C. NOT suitable for temperate zones with winter frost.',
        'Buah tropika yang kaya dengan kalium. Memerlukan iklim hangat bebas fros (melebihi 10°C sepanjang tahun). Mati pada 0°C. TIDAK sesuai untuk zon beriklim sederhana.',
        '富含钾的热带水果。需要温暖无霜的气候（全年 10°C 以上）。0°C 时会死亡。不适合有冬季霜冻的温带地区。',
      );
    }
    if (lowerName == 'strawberry') {
      return _t(
        'Sweet red fruit rich in vitamin C and antioxidants. Best with good drainage and regular care.',
        'Buah merah manis yang kaya dengan vitamin C dan antioksidan. Paling baik dengan saliran baik dan penjagaan tetap.',
        '富含维生素 C 和抗氧化剂的甜红果实。最好有良好的排水和定期的护理。',
      );
    }
    if (lowerName == 'apple') {
      return _t(
        'Temperate fruit tree requiring 800-1000 chill hours (below 7°C). NOT suitable for tropical lowlands. Best in highland areas above 1000m elevation.',
        'Pokok buah beriklim sederhana yang memerlukan 800-1000 jam sejuk (bawah 7°C). TIDAK sesuai untuk dataran rendah tropika. Terbaik di tanah tinggi melebihi 1000m.',
        '需要 800-1000 寒冷小时（低于 7°C）的温带果树。不适合热带低地。最适合海拔 1000 米以上的高地。',
      );
    }
    if (lowerName == 'pandan') {
      return _t(
        'Fragrant leaves used in Southeast Asian desserts and rice dishes.',
        'Daun wangi yang digunakan dalam pencuci mulut dan hidangan nasi Asia Tenggara.',
        '用于东南亚甜点和米饭菜肴的芬芳叶子。',
      );
    }
    return '';
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  COMMUNITY / CREATE POST SCREEN
  // ═══════════════════════════════════════════════════════════════════════
  String get createPostTitle => _t('Create Post', 'Cipta Siaran', '创建帖子');
  String get whatsOnYourMind =>
      _t("What's on your mind?", 'Apa yang ada di fikiran anda?', '你在想什么？');
  String get post => _t('Post', 'Siaran', '发布');
  String get writeACaption =>
      _t('Write a caption...', 'Tulis kapsyen...', '写下标题...');
  String get errorCreatingPost =>
      _t('Error creating post', 'Ralat mencipta siaran', '创建帖子出错');
  String get newPostTitle => _t('New Post', 'Siaran Baharu', '新帖子');
  String get sharePost => _t('Share', 'Kongsi', '分享');
  String get addPhoto => _t('Add Photo', 'Tambah Foto', '添加照片');

  // Step indicator
  String stepOf(int current, int total) => _t(
    'Step $current of $total',
    'Langkah $current daripada $total',
    '第 $current 步，共 $total 步',
  );

  // Navigation
  String get nextButton => _t('Next', 'Seterusnya', '下一步');
  String get finishButton => _t('Finish', 'Selesai', '完成');

  // ── Home Screen (additional) ──
  String kgToNextLevel(String kg, int level) =>
      _t('$kg kg to L$level', '$kg kg ke L$level', '$kg 千克到 L$level');
  String daysLabel(int days) => _t('$days days', '$days hari', '$days 天');
  String get setInMyJourney =>
      _t('Set in My Journey', 'Tetapkan di Perjalanan Saya', '在我的旅途中设置');
  String get errorLoadingPosts =>
      _t('Error loading posts', 'Ralat memuatkan siaran', '加载帖子出错');

  // Weather conditions
  String get clearSky => _t('Clear sky', 'Langit cerah', '晴天');
  String get partlyCloudy => _t('Partly cloudy', 'Separa berawan', '多云');
  String get cloudy => _t('Cloudy', 'Berawan', '阴天');
  String get fog => _t('Fog', 'Kabus', '雾');
  String get drizzle => _t('Drizzle', 'Renyai', '毛毛雨');
  String get freezingDrizzle => _t('Freezing drizzle', 'Renyai beku', '冻毛毛雨');
  String get rain => _t('Rain', 'Hujan', '雨');
  String get freezingRain => _t('Freezing rain', 'Hujan beku', '冻雨');
  String get snow => _t('Snow', 'Salji', '雪');
  String get rainShowers => _t('Rain showers', 'Hujan lebat', '阵雨');
  String get snowShowers => _t('Snow showers', 'Hujan salji', '阵雪');
  String get thunderstorm => _t('Thunderstorm', 'Ribut petir', '雷暴');
  String get unknownWeather => _t('Unknown', 'Tidak diketahui', '未知');

  // ── Pest Distribution Map ──
  String get pestDistributionMap =>
      _t('Pest Distribution Map', 'Peta Taburan Perosak', '害虫分布地图');
  String get myReportsTitle => _t('My Reports', 'Laporan Saya', '我的报告');
  String get recentPestAlerts => _t(
    'Recent Pest Alerts in Malaysia',
    'Amaran Perosak Terkini di Malaysia',
    '马来西亚最新害虫警报',
  );
  String get errorLoadingAlerts =>
      _t('Error loading alerts.', 'Ralat memuatkan amaran.', '加载警报出错。');
  String get noRecentAlerts =>
      _t('No recent alerts.', 'Tiada amaran terkini.', '没有最新警报。');
  String get locationUnknown =>
      _t('Location unknown', 'Lokasi tidak diketahui', '位置未知');
  String get clearOutbreakTitle =>
      _t('Clear Outbreak?', 'Hapuskan Wabak?', '清除疫情？');
  String get clearOutbreakContent => _t(
    'Has this pest outbreak been resolved? This will permanently remove the danger zone from the map for all farmers.',
    'Adakah wabak perosak ini telah diselesaikan? Ini akan membuang zon bahaya dari peta untuk semua petani.',
    '此害虫疫情已解决吗？这将永久从地图上移除所有农民的危险区域。',
  );
  String get yesClearIt => _t('Yes, Clear It', 'Ya, Hapuskan', '是的，清除');
  String get outbreakCleared => _t(
    'Outbreak cleared! Map updated.',
    'Wabak dihapuskan! Peta dikemaskini.',
    '疫情已清除！地图已更新。',
  );
  String get tapToClear => _t(
    'Tap here to mark as CLEARED ✅',
    'Ketik di sini untuk tanda SELESAI ✅',
    '点击此处标记为已清除 ✅',
  );
  String get reportedOutbreakCenter =>
      _t('Reported Outbreak Center', 'Pusat Wabak Dilaporkan', '报告的疫情中心');
  String get networkError => _t('Network error.', 'Ralat rangkaian.', '网络错误。');
  String get cleared => _t('CLEARED', 'SELESAI', '已清除');

  // ── My Reports Screen ──
  String get myOutbreakReports =>
      _t('My Outbreak Reports', 'Laporan Wabak Saya', '我的疫情报告');
  String get outbreakMarkedCleared => _t(
    'Outbreak marked as cleared!',
    'Wabak ditandakan sebagai selesai!',
    '疫情已标记为已清除！',
  );
  String get pleaseLoginReports => _t(
    'Please log in to view your reports.',
    'Sila log masuk untuk melihat laporan anda.',
    '请登录查看您的报告。',
  );
  String get errorLoadingReports =>
      _t('Error loading reports.', 'Ralat memuatkan laporan.', '加载报告出错。');
  String get noOutbreaksYet => _t(
    "You haven't reported any outbreaks yet.",
    'Anda belum melaporkan sebarang wabak.',
    '您尚未报告任何疫情。',
  );
  String get active => _t('ACTIVE', 'AKTIF', '活跃');
  String get markAsCleared => _t(
    'Mark Outbreak as Cleared',
    'Tandakan Wabak Sebagai Selesai',
    '标记疫情为已清除',
  );

  // ── Marketplace Screen ──
  String get marketplace => _t('Marketplace', 'Pasaran', '市场');
  String get searchByCropOrLocation => _t(
    'Search by crop or location',
    'Cari mengikut tanaman atau lokasi',
    '按作物或地点搜索',
  );
  String get noProductsYet => _t(
    'No products yet. Check back soon!',
    'Belum ada produk. Semak semula nanti!',
    '暂无产品，请稍后再来！',
  );
  String noResultsFor(String query) => _t(
    'No results for "$query"',
    'Tiada keputusan untuk "$query"',
    '没有"$query"的结果',
  );
  String weightKg(String weight) =>
      _t('Weight: $weight kg', 'Berat: $weight kg', '重量：$weight 千克');
  String harvestDateLabel(String date) =>
      _t('Harvest Date: $date', 'Tarikh Tuai: $date', '收获日期：$date');
  String contactLabel(String contact) =>
      _t('Contact: $contact', 'Hubungi: $contact', '联系方式：$contact');

  // ── My Product Screen ──
  String get myProducts => _t('My Products', 'Produk Saya', '我的产品');
  String get addProduct => _t('Add Product', 'Tambah Produk', '添加产品');
  String get editProduct => _t('Edit Product', 'Edit Produk', '编辑产品');
  String get pleaseLoginProducts => _t(
    'Please log in to view your products.',
    'Sila log masuk untuk melihat produk anda.',
    '请登录查看您的产品。',
  );
  String get noProductsAddOne => _t(
    'No products yet. Tap "+" to add one.',
    'Belum ada produk. Ketik "+" untuk tambah.',
    '暂无产品。点击"+"添加。',
  );
  String get deleteProductTitle =>
      _t('Delete product?', 'Padam produk?', '删除产品？');
  String get actionCannotBeUndone => _t(
    'This action cannot be undone.',
    'Tindakan ini tidak boleh dibatalkan.',
    '此操作无法撤消。',
  );
  String get productDeleted =>
      _t('Product deleted', 'Produk dipadamkan', '产品已删除');
  String get productSaved => _t('Product saved', 'Produk disimpan', '产品已保存');
  String get selectCrop => _t('Select a crop', 'Pilih tanaman', '选择作物');
  String get crop => _t('Crop', 'Tanaman', '作物');
  String get weightKgLabel => _t('Weight (kg)', 'Berat (kg)', '重量（千克）');
  String get enterValidWeight =>
      _t('Enter a valid weight', 'Masukkan berat yang sah', '请输入有效重量');
  String get harvestDate => _t('Harvest Date', 'Tarikh Tuai', '收获日期');
  String get contactNumber => _t('Contact Number', 'Nombor Telefon', '联系电话');
  String get enterContactNumber =>
      _t('Enter a contact number', 'Masukkan nombor telefon', '请输入联系电话');
  String get address => _t('Address', 'Alamat', '地址');
  String get useCurrent => _t('Use Current', 'Guna Semasa', '使用当前位置');
  String get tapToAddPhoto =>
      _t('Tap to add photo', 'Ketik untuk tambah foto', '点击添加照片');
  String get takePhoto => _t('Take Photo', 'Ambil Foto', '拍照');
  String get pickFromGallery =>
      _t('Pick from Gallery', 'Pilih dari Galeri', '从相册选择');
  String get harvested => _t('Harvested', 'Dituai', '已收获');
  String get edit => _t('Edit', 'Edit', '编辑');

  // ── Map Screen ──
  String get map => _t('Map', 'Peta', '地图');
  String get myProduct => _t('My Product', 'Produk Saya', '我的产品');
  String get phone => _t('Phone', 'Telefon', '电话');
  String get removeProfileTitle =>
      _t('Remove profile?', 'Buang profil?', '删除个人资料？');
  String get removeProfileContent => _t(
    'This will remove your public profile from the map. You can publish it again later if needed.',
    'Ini akan membuang profil awam anda dari peta. Anda boleh menerbitkannya semula kemudian jika perlu.',
    '这将从地图中删除您的公开个人资料。如需要，您可以稍后重新发布。',
  );
  String get profileRemoved =>
      _t('Profile removed', 'Profil dibuang', '个人资料已删除');
  String get updateProfile =>
      _t('Update your profile', 'Kemaskini profil anda', '更新您的个人资料');
  String get nameLabel => _t('Name', 'Nama', '姓名');
  String get enterYourName =>
      _t('Enter your name', 'Masukkan nama anda', '请输入您的姓名');
  String get description => _t('Description', 'Penerangan', '描述');
  String get streetCityState =>
      _t('Street, city, state', 'Jalan, bandar, negeri', '街道、城市、州');
  String get useCurrentLocation =>
      _t('Use current location', 'Guna lokasi semasa', '使用当前位置');
  String get makeProfilePublic =>
      _t('Make your profile public?', 'Jadikan profil anda awam?', '公开您的个人资料？');
  String get profilePublished =>
      _t('Profile published', 'Profil diterbitkan', '个人资料已发布');
  String get registerOnMap => _t('Register on Map', 'Daftar di Peta', '在地图上注册');

  // ── Video Call Landing Screen ──
  String get aiVideoCall => _t('AI Video Call', 'Panggilan Video AI', 'AI视频通话');
  String get talkToAiInYourLanguage => _t(
    'Talk to AI in Your Language',
    'Bercakap dengan AI dalam Bahasa Anda',
    '用您的语言与AI对话',
  );
  String get videoCallDescription => _t(
    'Show your crops through the camera and speak in your preferred language. The AI will understand and respond in the same language.',
    'Tunjukkan tanaman anda melalui kamera dan bercakap dalam bahasa pilihan anda. AI akan memahami dan menjawab dalam bahasa yang sama.',
    '通过摄像头展示您的作物，用您喜欢的语言交流。AI将理解并以同样的语言回应。',
  );
  String get selectYourLanguage =>
      _t('Select your language', 'Pilih bahasa anda', '选择您的语言');
  String get showCrops => _t('Show Crops', 'Tunjuk Tanaman', '展示作物');
  String get showCropsDesc => _t(
    'Point your camera at leaves, pests, or soil',
    'Halakan kamera anda ke daun, perosak, atau tanah',
    '将摄像头对准叶子、害虫或土壤',
  );
  String get speakNaturally =>
      _t('Speak Naturally', 'Bercakap Secara Semula Jadi', '自然对话');
  String get speakNaturallyDesc => _t(
    'Describe problems in your own language',
    'Huraikan masalah dalam bahasa anda sendiri',
    '用您自己的语言描述问题',
  );
  String get aiAnalysis => _t('AI Analysis', 'Analisis AI', 'AI分析');
  String get aiAnalysisDesc => _t(
    'Get instant diagnosis and treatment advice',
    'Dapatkan diagnosis segera dan nasihat rawatan',
    '获取即时诊断和治疗建议',
  );
  String get voiceResponse => _t('Voice Response', 'Respons Suara', '语音回复');
  String get voiceResponseDesc => _t(
    'AI speaks back to you in your language',
    'AI bercakap kembali kepada anda dalam bahasa anda',
    'AI用您的语言回复您',
  );
  String get startVideoCall =>
      _t('Start Video Call', 'Mulakan Panggilan Video', '开始视频通话');
  String get requiresCameraMic => _t(
    'Requires camera and microphone access',
    'Memerlukan akses kamera dan mikrofon',
    '需要摄像头和麦克风权限',
  );

  // ── Search Users Screen ──
  String get searchPeople => _t('Search people...', 'Cari orang...', '搜索用户...');
  String get typeToSearch => _t(
    'Type to search for users.',
    'Taip untuk mencari pengguna.',
    '输入以搜索用户。',
  );
  String get noUsersFound =>
      _t('No users found.', 'Tiada pengguna ditemui.', '未找到用户。');

  // ── Create Post Screen ──
  String get newPost => _t('New Post', 'Siaran Baru', '新帖子');
  String get share => _t('Share', 'Kongsi', '分享');
  String get writeCaption =>
      _t('Write a caption...', 'Tulis kapsyen...', '写标题...');
  String get tagPeople => _t('Tag people', 'Tag orang', '标记用户');
  String get tagPeopleComingSoon => _t(
    'Tag people feature coming soon!',
    'Ciri tag orang akan datang!',
    '标记用户功能即将推出！',
  );
  String get addLocation => _t('Add location', 'Tambah lokasi', '添加位置');
  String get addLocationComingSoon => _t(
    'Add location feature coming soon!',
    'Ciri tambah lokasi akan datang!',
    '添加位置功能即将推出！',
  );
  String get addAudio => _t('Add audio', 'Tambah audio', '添加音频');
  String get addAudioComingSoon => _t(
    'Add audio feature coming soon!',
    'Ciri tambah audio akan datang!',
    '添加音频功能即将推出！',
  );

  // ── AI Scan / Diagnostics ──
  String get aiDiagnosticsOld => _t('AI Diagnostics', 'Diagnostik AI', 'AI诊断');
  String get scanLeafToDetect => _t(
    'Scan a leaf to detect diseases',
    'Imbas daun untuk mengesan penyakit',
    '扫描叶子以检测疾病',
  );
  String get aiCropDiagnostics =>
      _t('AI Crop Diagnostics', 'Diagnostik Tanaman AI', 'AI 作物诊断');
  String get aiDiagnosticsSubtitle => _t(
    'Instantly scan your plants to identify pest infestations, diseases, or nutritional deficiencies.',
    'Imbas tanaman anda dengan segera untuk mengenal pasti serangan perosak, penyakit, atau kekurangan nutrisi.',
    '即时扫描您的植物，识别害虫侵扰、疾病或营养缺乏。',
  );
  String get scanZoneHelper => _t(
    'Take a photo or upload from gallery',
    'Ambil foto atau muat naik dari galeri',
    '拍照或从相册上传',
  );
  String get readyToScan => _t(
    'Your image is ready! Choose an analysis type below.',
    'Imej anda sudah sedia! Pilih jenis analisis di bawah.',
    '您的图片已准备好！请在下方选择分析类型。',
  );

  String get imageReady => _t('Image Ready', 'Imej Sedia', '图片已就绪');
  String get editLocation => _t('Edit Location', 'Edit Lokasi', '修改位置');

  // ── Agropreneur Tutorial ──
  String tutorialStepTitle(int index) {
    switch (index) {
      case 0:
        return _t('Create e-GAN Account', 'Cipta Akaun e-GAN', '创建 e-GAN 账户');
      case 1:
        return _t('Verify Your Email', 'Sahkan Emel Anda', '验证您的电子邮件');
      case 2:
        return _t('Login to Portal', 'Log Masuk ke Portal', '登录门户网站');
      case 3:
        return _t('Select The Grant', 'Pilih Geran', '选择补助金');
      case 4:
        return _t('Confirm Eligibility', 'Sahkan Kelayakan', '确认资格');
      case 5:
        return _t(
          'Step 1: Personal Details',
          'Langkah 1: Butiran Peribadi',
          '步骤 1：个人详情',
        );
      case 6:
        return _t(
          'Step 2: Project Information',
          'Langkah 2: Maklumat Projek',
          '步骤 2：项目信息',
        );
      case 7:
        return _t(
          'Step 3: Request for Aid',
          'Langkah 3: Memohon Bantuan',
          '步骤 3：申请援助',
        );
      case 8:
        return _t(
          'Step 4: Business Plan',
          'Langkah 4: Rancangan Perniagaan',
          '步骤 4：商业计划',
        );
      case 9:
        return _t(
          'Step 5: Financial Plan',
          'Langkah 5: Rancangan Kewangan',
          '步骤 5：财务计划',
        );
      case 10:
        return _t(
          'Step 6: Final Declaration',
          'Langkah 6: Pengisytiharan Akhir',
          '步骤 6：最终声明',
        );
      case 11:
        return _t(
          'Save, Review & Submit',
          'Simpan, Semak & Hantar',
          '保存、审核并提交',
        );
      default:
        return '';
    }
  }

  String tutorialStepDescription(int index) {
    switch (index) {
      case 0:
        return _t(
          'First, register on the official e-GAN portal. Fill in your Full Name (as per MyKad), IC Number, Email, and create a Password.\n\n💡 Pro Tip: Use an active email address as you need to verify it immediately.',
          'Pertama, daftar di portal rasmi e-GAN. Isi Nama Penuh anda (seperti dalam MyKad), No. Kad Pengenalan, Emel, dan cipta Kata Laluan.\n\n💡 Petua Pro: Gunakan alamat emel yang aktif kerana anda perlu mengesahkannya dengan segera.',
          '首先，在官方 e-GAN 门户网站注册。填写您的全名（按 MyKad）、身份证号码、电子邮件，并创建密码。\n\n💡 专业建议：使用有效的电子邮件地址，因为您需要立即进行验证。',
        );
      case 1:
        return _t(
          'Check your inbox for a verification link. Click the blue button \'Pengesahan Akaun\' to activate.\n\n⚠️ Important: Link expires in 60 minutes. Check Spam folder if missing.',
          'Semak peti masuk anda untuk pautan pengesahan. Klik butang biru \'Pengesahan Akaun\' untuk mengaktifkan.\n\n⚠️ Penting: Pautan tamat tempoh dalam masa 60 minit. Semak folder Spam jika gagal diterima.',
          '检查您的收件箱是否有验证链接。点击蓝色按钮“Pengesahan Akaun”以激活。\n\n⚠️ 重要提示：链接将在 60 分钟内失效。如果没有收到，请检查垃圾邮件文件夹。',
        );
      case 2:
        return _t(
          'Once verified, return to the portal. Enter your IC Number and the Password you just created to log in for the first time.',
          'Setelah disahkan, kembali ke portal. Masukkan No. Kad Pengenalan dan Kata Laluan yang anda baru cipta untuk log masuk buat kali pertama.',
          '验证后，返回门户网站。输入您的身份证号码和刚刚创建的密码以进行首次登录。',
        );
      case 3:
        return _t(
          'On the sidebar menu, click \'Permohonan Geran Agropreneur NextGen\'. Then, click \'Mohon Sekarang\' (Apply Now) to open the form.',
          'Pada menu bar sisi, klik \'Permohonan Geran Agropreneur NextGen\'. Kemudian, klik \'Mohon Sekarang\' untuk membuka borang.',
          '在侧边栏菜单中，点击“Permohonan Geran Agropreneur NextGen”。然后，点击“Mohon Sekarang”（立即申请）打开表格。',
        );
      case 4:
        return _t(
          'You must tick the boxes to declare your eligibility:\n\n1. Malaysian Citizen (18-45 years old).\n2. Can read, count, and write.\n3. Have attended training OR have a relevant Diploma/Degree OR have experience.\n\nAction: Click \'Lengkapkan Permohonan\' to proceed to the main form.',
          'Anda mesti menanda kotak untuk menyatakan kelayakan anda:\n\n1. Warganegara Malaysia (18-45 tahun).\n2. Boleh membaca, mengira, dan menulis.\n3. Telah mengikuti latihan ATAU mempunyai Diploma/Ijazah berkaitan ATAU mempunyai pengalaman.\n\nTindakan: Klik \'Lengkapkan Permohonan\' untuk meneruskan ke borang utama.',
          '您必须勾选这些框以声明您的资格：\n\n1. 马来西亚公民（18-45 岁）。\n2. 能够读、算、写。\n3. 参加过培训或具有相关文凭/学位或具有经验。\n\n操作：点击“Lengkapkan Permohonan”继续填写主表。',
        );
      case 5:
        return _t(
          'Fill in your personal information (Marital Status, Phone, Address, etc).\n\n📄 Documents Required:\n• Passport-sized Photo of applicant.\n• Copy of MyKad (IC) - Must be Certified.\n• SSM Registration or Business License - Must be Certified.',
          'Isi maklumat peribadi anda (Status Perkahwinan, Telefon, Alamat, dll).\n\n📄 Dokumen Diperlukan:\n• Gambar bersaiz pasport pemohon.\n• Salinan MyKad (IC) - Mesti disahkan.\n• Pendaftaran SSM atau Lesen Perniagaan - Mesti disahkan.',
          '填写您的个人信息（婚姻状况、电话、地址等）。\n\n📄 所需文件：\n• 申请人的护照尺寸照片。\n• MyKad (IC) 副本 - 必须经过认证。\n• SSM 注册或营业执照 - 必须经过认证。',
        );
      case 6:
        return _t(
          'Select your project project type and the Supervising Agency (Agensi Pembimbing), e.g., DOA for Crops.\n\n📄 Documents Required:\n• Proof of Land Ownership (Certified).\n• Stamped Tenancy Agreement (if renting).\n• Consent Letter (if using parents\' land).',
          'Pilih jenis projek anda dan Agensi Pembimbing, cth., DOA untuk Tanaman.\n\n📄 Dokumen Diperlukan:\n• Bukti Pemilikan Tanah (Disahkan).\n• Perjanjian Sewaan Bersetem (jika menyewa).\n• Surat Kebenaran (jika menggunakan tanah ibu bapa).',
          '选择您的项目类型和监督机构（Agensi Pembimbing），例如：作物的 DOA。\n\n📄 所需文件：\n• 土地所有权证明（经过认证）。\n• 盖章的租约（如果租用）。\n• 同意书（如果使用父母的土地）。',
        );
      case 7:
        return _t(
          'List the specific items or machinery you need to buy.\n\n💰 Maximum Limit: RM30,000 (for Crops, Livestock, Fisheries).\n\n⚠️ Important: You MUST upload current price quotations from three (3) different suppliers for the items you are requesting.',
          'Senaraikan item spesifik atau jentera yang anda perlu beli.\n\n💰 Had Maksimum: RM30,000 (untuk Tanaman, Ternakan, Perikanan).\n\n⚠️ Penting: Anda MESTI memuat naik sebut harga semasa daripada tiga (3) pembekal berbeza bagi item yang anda mohon.',
          '列出您需要购买的具体物品或机械。\n\n💰 最高限额：30,000 令吉（用于作物、畜牧业、渔业）。\n\n⚠️ 重要提示：您必须上传针对您所申请项目的三个（3）个不同供应商的当前价格报价。',
        );
      case 8:
        return _t(
          'This is the most critical section. Describe your business vision.\n\nKey Details to Fill:\n• Introduction: Purpose, Mission, and Vision.\n• Management: Employee roles.\n• Marketing: Sales channels (Online/Wholesalers).\n• Operations: Daily farm activities.\n\n📸 Requirement: You MUST upload at least 3 photos of your project site.',
          'Ini adalah bahagian yang paling kritikal. Terangkan visi perniagaan anda.\n\nButiran Utama untuk Diisi:\n• Pengenalan: Matlamat, Misi, dan Visi.\n• Pengurusan: Peranan pekerja.\n• Pemasaran: Saluran jualan (Atas Talian/Pemborong).\n• Operasi: Aktiviti ladang harian.\n\n📸 Keperluan: Anda MESTI memuat naik sekurang-kurangnya 3 keping foto tapak projek anda.',
          '这是最关键的部分。描述您的业务愿景。\n\n要填写的关键详情：\n• 简介：目的、使命和愿景。\n• 管理：员工角色。\n• 营销：销售渠道（在线/批发商）。\n• 运营：日常农场活动。\n\n📸 要求：您必须上传至少 3 张项目现场照片。',
        );
      case 9:
        return _t(
          'Calculate your project\'s profitability. Provide realistic estimates.\n\nCash Inflow:\n• Capital (Grant vs Own Money)\n• Sales Projection (Year 1, 2, 3)\n\nCash Outflow:\n• Development Costs (Machinery)\n• Operational Costs (Fertilizer, Feed, Labor)\n\n💡 Pro Tip: Ensure Sales Projection is higher than Operational Costs.',
          'Kira keuntungan projek anda. Berikan anggaran yang realistik.\n\nAliran Masuk Tunai:\n• Modal (Geran vs Wang Sendiri)\n• Juran Jualan (Tahun 1, 2, 3)\n\nAliran Keluar Tunai:\n• Kos Pembangunan (Jentera)\n• Kos Operasi (Baja, Makanan, Buruh)\n\n💡 Petua Pro: Pastikan Juruan Jualan lebih tinggi daripada Kos Operasi.',
          '计算您的项目盈利能力。提供现实的估计。\n\n现金流入：\n• 资本（补助金对比自有资金）\n• 销售额预测（第 1、2、3 年）\n\n现金流出：\n• 开发成本（机械）\n• 运营成本（肥料、饲料、劳动力）\n\n💡 专业建议：确保销售预测高于运营成本。',
        );
      case 10:
        return _t(
          'You must agree to the terms before submitting:\n\n✅ Acknowledge that the application will be rejected if you do not respond to queries within 3 months.\n✅ Declare that all information provided is TRUE.\n\n⚠️ Warning: Providing false information is a serious offense under Clause 463 of the Penal Code.',
          'Anda mesti bersetuju dengan syarat sebelum menghantar:\n\n✅ Akui bahawa permohonan akan ditolak jika anda tidak menjawab pertanyaan dalam tempoh 3 bulan.\n✅ Isytihar bahawa semua maklumat yang diberikan adalah BENAR.\n\n⚠️ Amaran: Memberi maklumat palsu adalah kesalahan serius di bawah Seksyen 463 Kanun Keseksaan.',
          '提交前您必须同意条款：\n\n✅ 承认如果您在 3 个月内未回复查询，申请将被拒绝。\n✅ 声明所提供的所有信息均为真实信息。\n\n⚠️ 警告：根据《刑法》第 463 条，提供虚假信息是一项严重罪行。',
        );
      case 11:
        return _t(
          'Do not submit immediately! Follow this safe process:\n\n1. Click \'Simpan Draf\' (Save Draft) to save your progress.\n2. Check your Dashboard. You can click the Green Pencil Icon to edit if needed.\n3. Once you are 100% satisfied, click the green \'Hantar\' (Submit) button.\n\n✅ Success: Your application is now sent to the Ministry for processing. Good luck!',
          'Jangan hantar dengan segera! Ikuti proses selamat ini:\n\n1. Klik \'Simpan Draf\' untuk menyimpan kemajuan anda.\n2. Semak Papan Pemuka anda. Anda boleh klik Ikon Pensel Hijau untuk mengedit jika perlu.\n3. Setelah anda 100% berpuas hati, klik butang hijau \'Hantar\'.\n\n✅ Berjaya: Permohonan anda kini dihantar ke Kementerian untuk diproses. Semoga berjaya!',
          '不要立即提交！遵循此安全流程：\n\n1. 点击“Simpan Draf”（保存草稿）以保存进度。\n2. 检查您的仪表板。如果需要，您可以点击绿色铅笔图标进行编辑。\n3. 在 100% 满意后，点击绿色的“Hantar”（提交）按钮。\n\n✅ 成功：您的申请现已发送至该部进行处理。祝你好运！',
        );
      default:
        return '';
    }
  }

  String get openPortal => _t(
    'Open e-GAN Registration Portal',
    'Buka Portal Pendaftaran e-GAN',
    '打开 e-GAN 注册门户',
  );

  // ── Land Rent Filters ──

  String get allSize => _t('All', 'Semua', '全部');
  String get budgetPrice =>
      _t('Budget (< RM 1,000)', 'Bajet (< RM 1,000)', '经济 (< RM 1,000)');
  String get standardPrice => _t(
    'Standard (RM 1,000 - 3,000)',
    'Standard (RM 1,000 - 3,000)',
    '标准 (RM 1,000 - 3,000)',
  );
  String get premiumPrice =>
      _t('Premium (> RM 3,000)', 'Premium (> RM 3,000)', '优质 (> RM 3,000)');
  String get budgetPriceShort =>
      _t('Budget (< RM1k)', 'Bajet (< RM1k)', '经济 (< RM1k)');
  String get standardPriceShort =>
      _t('Standard (RM1k-3k)', 'Standard (RM1k-3k)', '标准 (RM1k-3k)');
  String get premiumPriceShort =>
      _t('Premium (> RM3k)', 'Premium (> RM3k)', '优质 (> RM3k)');
  String get smallSize =>
      _t('Small (< 1 Acre)', 'Kecil (< 1 Ekar)', '小型 (< 1 英亩)');
  String get mediumSize =>
      _t('Medium (1-5 Acres)', 'Sederhana (1-5 Ekar)', '中型 (1-5 英亩)');
  String get largeSize =>
      _t('Large (> 5 Acres)', 'Besar (> 5 Ekar)', '大型 (> 5 英亩)');

  // ── Marketplace Map ──
  String get business => _t('Business', 'Perniagaan', '业务');
  String get product => _t('Product', 'Produk', '产品');

  // ── AI Diagnostic ──
  String get chooseAnalysisType =>
      _t('Choose Analysis Type', 'Pilih Jenis Analisis', '选择分析类型');
  String get detectPestsDesc => _t(
    'Detect pest infestations & diseases',
    'Kesan serangan perosak & penyakit',
    '检测害虫侵袭和疾病',
  );
  String get checkNutrientsDesc => _t(
    'Check for nutritional deficiencies',
    'Periksa kekurangan nutrisi',
    '检查营养缺乏',
  );

  // ── Common ──
  String get pending => _t('Pending...', 'Menunggu...', '待处理...');
  String get errorClearingOutbreak =>
      _t('Error clearing outbreak', 'Ralat menghapuskan wabak', '清除疫情出错');
  String get somethingWentWrong =>
      _t('Something went wrong', 'Sesuatu telah berlaku', '出了点问题');
  String get fetchLocation =>
      _t('Fetch location.', 'Dapatkan lokasi.', '获取位置。');
  String get selectACrop => _t('Select a crop.', 'Pilih tanaman.', '请选择作物。');
  String get pickHarvestDate =>
      _t('Pick harvest date.', 'Pilih tarikh tuai.', '请选择收获日期。');
  String get enableLocationServices =>
      _t('Enable location services', 'Hidupkan perkhidmatan lokasi', '启用位置服务');
  String get locationPermissionDenied =>
      _t('Location permission denied', 'Kebenaran lokasi ditolak', '位置权限被拒绝');

  // ── Feedback ──
  String get sendFeedback => _t('Send Feedback', 'Hantar Maklum Balas', '发送反馈');
  String get feedbackTitle =>
      _t('We would love to hear from you!', 'Kami ingin mendengar daripada anda!', '我们很乐意听取您的意见！');
  String get feedbackSubtitle => _t(
    'Tell us what you like or any issues you have faced while using Kita Agro.',
    'Beritahu kami perkara yang anda suka atau sebarang isu yang anda hadapi semasa menggunakan Kita Agro.',
    '告诉我们您喜欢什么，或在使用 Kita Agro 时遇到的任何问题。'
  );
  String get typeFeedbackHint =>
      _t('Type your feedback here...', 'Taip maklum balas anda di sini...', '在此处输入您的反馈...');
  String get submitFeedback =>
      _t('Submit Feedback', 'Hantar Maklum Balas', '提交反馈');
  String get thankYouFeedback =>
      _t('Thank you for your feedback!', 'Terima kasih atas maklum balas anda!', '感谢您的反馈！');
  String get failedToSubmit => _t('Failed to submit', 'Gagal dihantar', '提交失败');
}

/// An InheritedWidget that provides LanguageService down the tree
class LanguageServiceProvider extends InheritedNotifier<LanguageService> {
  const LanguageServiceProvider({
    super.key,
    required LanguageService service,
    required super.child,
  }) : super(notifier: service);

  static LanguageService of(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<LanguageServiceProvider>();
    return provider!.notifier!;
  }
}
