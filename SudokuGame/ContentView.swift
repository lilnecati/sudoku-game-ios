import SwiftUI

// Uygulama yaşam döngüsü olaylarını dinlemek için
class AppLifecycleManager: ObservableObject {
    @Published var isActive = true
    
    init() {
        setupNotifications()
    }
    
    private func setupNotifications() {
        // Uygulama arka plana geçtiğinde
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        // Uygulama ön plana geldiğinde
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        // Uygulama aktif olduğunda
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc private func appDidEnterBackground() {
        print("Uygulama arka plana geçti")
        isActive = false
    }
    
    @objc private func appWillEnterForeground() {
        print("Uygulama ön plana geliyor")
        isActive = true
    }
    
    @objc private func appDidBecomeActive() {
        print("Uygulama aktif oldu")
        // Uygulama aktif olduğunda yükleme ekranını göstermek için bildirim gönder
        NotificationCenter.default.post(name: NSNotification.Name("AppBecameActive"), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// Tema renkleri için enum tanımı
enum ThemeColor: String, CaseIterable, Identifiable {
    case blue = "Mavi"
    case green = "Yeşil"
    case purple = "Mor"
    case orange = "Turuncu"
    case pink = "Pembe"
    
    var id: String { self.rawValue }
    
    var mainColor: Color {
        switch self {
        case .blue: return .blue
        case .green: return .green
        case .purple: return .purple
        case .orange: return .orange
        case .pink: return .pink
        }
    }
    
    var secondaryColor: Color {
        switch self {
        case .blue: return .cyan
        case .green: return .mint
        case .purple: return Color(red: 0.5, green: 0.2, blue: 0.8)
        case .orange: return .yellow
        case .pink: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .blue: return "drop.fill"
        case .green: return "leaf.fill"
        case .purple: return "sparkles"
        case .orange: return "sun.max.fill"
        case .pink: return "heart.fill"
        }
    }
}

struct ContentView: View {
    @StateObject private var sudokuModel = SudokuModel()
    @StateObject private var lifecycleManager = AppLifecycleManager()
    @StateObject private var userModel = UserModel()
    @State private var showingHowToPlay = false
    @State private var showingSettings = false
    @State private var showingProfile = false
    @State private var selectedNumber: Int? = nil
    @State private var timer: Timer? = nil
    @State private var showingDifficultyPicker = false
    @State private var showConfetti = false
    @State private var showingStats = false
    @State private var showingHint = false
    @State private var isGameOver = false
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = "Mavi"
    @State private var noteMode = false
    @State private var showingWelcomeScreen = true // İlk açılışta hoş geldiniz ekranını göster
    @State private var isLoading = true // Başlangıçta yükleme ekranını göster
    @Environment(\.colorScheme) var colorScheme
    @State private var showingGameCompleteAlert = false
    @AppStorage("userColorScheme") private var userColorSchemeRaw: String = "system"
    @State private var completedNumbers: Set<Int> = []
    @AppStorage("firstLaunch") private var isFirstLaunch: Bool = true
    @AppStorage("showWelcomeScreen") private var shouldShowWelcomeScreen: Bool = true
    
    // Sabit değerler - performans için önceden hesaplanır
    private let buttonSize: CGFloat = UIScreen.main.bounds.width < 375 ? 40 : 45
    private let numberButtonPadding: CGFloat = UIScreen.main.bounds.width < 375 ? 4 : 6
    private let numberButtonFontSize: CGFloat = UIScreen.main.bounds.width < 375 ? 20 : 22
    private let cellSize: CGFloat = {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        let minDimension = min(screenWidth, screenHeight)
        
        if screenWidth >= 428 { // iPhone Pro Max modeller
            return minDimension / 9.5
        } else if screenWidth >= 390 { // iPhone Pro modeller
            return minDimension / 10
        } else { // iPhone mini ve standart modeller
            return minDimension / 10.5
        }
    }()
    
    private var backgroundColor: Color {
        isDarkMode ? Color.gray.opacity(0.2) : Color.white.opacity(0.9)
    }
    
    private var selectedTheme: ThemeColor {
        ThemeColor(rawValue: selectedThemeRaw) ?? .blue
    }
    
    private var userColorScheme: ColorScheme? {
        switch userColorSchemeRaw {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
    
    private var isDarkMode: Bool {
        userColorScheme == .dark || (userColorScheme == nil && colorScheme == .dark)
    }
    
    var themeColor: Color {
        selectedTheme.mainColor
    }
    
    var themeSecondaryColor: Color {
        selectedTheme.secondaryColor
    }
    
    var body: some View {
        ZStack {
            // Arka plan
            backgroundView
            
            if shouldShowWelcomeScreen {
                // Ana sayfa (karşılama ekranı)
                WelcomeView()
            } else {
                // Oyun ekranı
                ZStack {
                    // Yükleme ekranı - isLoading true olduğunda göster
                    if isLoading {
                        // Arka planı tamamen kaplayan yarı saydam overlay
                        Color.black.opacity(0.5)
                            .edgesIgnoringSafeArea(.all)
                            .transition(.opacity)
                            .zIndex(2) // Üst katmanda göster
                            
                        LoadingView(themeColor: themeColor, isDarkMode: isDarkMode)
                            .transition(.opacity)
                            .zIndex(3) // En üst katmanda göster
                    } else {
                        // Oyun görünümü - sadece yükleme ekranı gösterilmiyorsa göster
                        gameView
                            .zIndex(1)
                    }
                    
                    // Konfeti - oyun tamamlandığında göster
                    if showConfetti {
                        ConfettiView()
                            .allowsHitTesting(false)
                            .transition(.opacity)
                            .zIndex(4) // En üst katmanda göster
                    }
                }
            }
        }
        .preferredColorScheme(userColorScheme)
        .onAppear {
            // Uygulamanın ilk açılışında welcome ekranını göster
            if isFirstLaunch {
                shouldShowWelcomeScreen = true
                isFirstLaunch = false
            } else {
                // Her zaman uygulamayı açarken welcome ekranını göster
                shouldShowWelcomeScreen = true
            }
            
            // NotificationCenter dinleyicileri ekle
            setupNotificationObservers()
            
            // Welcome ekranı gösteriliyorsa timer'ı başlatma
            if !shouldShowWelcomeScreen {
                startTimer()
            }
        }
        .onChange(of: lifecycleManager.isActive) { _, newValue in
            if newValue {
                print("Uygulama aktif duruma geldi, timer'ı başlat")
                startTimer()
            } else {
                print("Uygulama arka plana geçti, timer'ı durdur")
                stopTimer()
                
                // Oyun durumunu kaydet
                sudokuModel.saveGameState()
            }
        }
    }
    
    // MARK: - Notification Observers
    
    private func setupNotificationObservers() {
        // Yeni oyun başlatma bildirimi için dinleyici ekle
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("StartNewGame"),
            object: nil,
            queue: .main
        ) { _ in
            // Yeni oyun başlat
            startNewGame()
        }
        
        // Uygulama ön plana geldiğinde yükleme ekranını göster
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("AppBecameActive"),
            object: nil,
            queue: .main
        ) { _ in
            // Yükleme ekranını göster ve yeni oyun başlat
            withAnimation(.easeIn(duration: 0.3)) {
                isLoading = true
            }
            startLoadingSequence()
        }
    }
    
    // MARK: - Loading Sequence
    
    private func startLoadingSequence() {
        // Yükleme ekranını gösterdikten sonra oyunu başlat
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            // Yeni oyun oluşturma işlemini arka planda yap
            DispatchQueue.global(qos: .userInitiated).async {
                // Sudoku çözümünü oluştur (en yoğun işlem)
                autoreleasepool {
                    self.sudokuModel.prepareNewGame()
                }
                
                // UI güncellemelerini ana thread'de yap
                DispatchQueue.main.async {
                    // Model güncellemesini tamamla
                    self.sudokuModel.finalizeNewGame()
                    
                    self.startTimer()
                    self.updateCompletedNumbers()
                    
                    // Yükleme ekranını kapat
                    withAnimation(.easeOut(duration: 0.5)) {
                        self.isLoading = false
                    }
                }
            }
        }
    }
    
    // MARK: - Alt görünümler
    
    private var gameView: some View {
        VStack(spacing: 10) {
            // Geliştirilmiş üst bilgi çubuğu
            topBarView
            
            // Geliştirilmiş oyun bilgileri
            gameInfoView
            
            // Not modu butonu
            noteModeButton
            
            Spacer()
            
            // Geliştirilmiş Sudoku ızgarası
            sudokuGridView
            
            Spacer()
            
            // Geliştirilmiş rakam seçici
            numberPickerView
        }
        .transition(.opacity)
        .sheet(isPresented: $showingHowToPlay) {
            HowToPlayView()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(themeColor: themeColor, selectedThemeRaw: $selectedThemeRaw, userColorSchemeRaw: $userColorSchemeRaw)
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView(userModel: userModel)
        }
        .sheet(isPresented: $showingDifficultyPicker) {
            DifficultyPickerView(difficulty: $sudokuModel.difficulty, themeColor: themeColor)
        }
        .sheet(isPresented: $showingStats) {
            StatsView(gameTime: sudokuModel.gameTime, mistakes: sudokuModel.mistakes, difficulty: sudokuModel.difficulty, themeColor: themeColor)
        }
        .alert(isPresented: $showingHint) {
            Alert(
                title: Text("İpucu"),
                message: Text("Bir sonraki hamle için ipucu: \(getHintText())"),
                dismissButton: .default(Text("Tamam"))
            )
        }
        .alert(isPresented: $showingGameCompleteAlert) {
            Alert(
                title: Text("Tebrikler!"),
                message: Text("Sudoku'yu \(formatTime(sudokuModel.gameTime)) sürede, \(sudokuModel.mistakes) hata ile tamamladınız!"),
                dismissButton: .default(Text("Yeni Oyun")) {
                    startNewGame()
                }
            )
        }
    }
    
    private var backgroundView: some View {
        ZStack {
            // Arka plan gradyanı
            LinearGradient(
                gradient: Gradient(colors: [
                    isDarkMode ? Color.black : Color.white,
                    isDarkMode ? themeColor.opacity(0.2) : themeColor.opacity(0.1),
                    isDarkMode ? themeSecondaryColor.opacity(0.15) : themeSecondaryColor.opacity(0.08)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)
            
            // Arka plan deseni
            ZStack {
                ForEach(0..<9) { row in
                    ForEach(0..<9) { col in
                        Rectangle()
                            .stroke(themeColor.opacity(0.05), lineWidth: 1)
                            .frame(width: UIScreen.main.bounds.width / 9, height: UIScreen.main.bounds.width / 9)
                            .offset(x: CGFloat(col - 4) * UIScreen.main.bounds.width / 9,
                                    y: CGFloat(row - 4) * UIScreen.main.bounds.width / 9)
                    }
                }
            }
            .rotationEffect(.degrees(15))
            .opacity(0.5)
        }
    }
    
    private var topBarView: some View {
        HStack {
            Button(action: {
                // Hoş geldiniz ekranını göster
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    showingHowToPlay.toggle()
                }
            }) {
                HStack(spacing: 5) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: UIScreen.main.bounds.width >= 390 ? 18 : 16))
                    Text("Nasıl Oynanır")
                        .font(.system(size: UIScreen.main.bounds.width >= 390 ? 14 : 12, weight: .medium))
                }
                .foregroundColor(isDarkMode ? .white : .black)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    Capsule()
                        .fill(isDarkMode ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1))
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                )
            }
            .padding(.leading, numberButtonPadding)
            
            Spacer()
            
            // Profil butonu
            if userModel.isLoggedIn {
                Button(action: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        showingProfile.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: userModel.profileImageName)
                            .font(.system(size: UIScreen.main.bounds.width >= 390 ? 16 : 14))
                        Text(userModel.username)
                            .font(.system(size: UIScreen.main.bounds.width >= 390 ? 12 : 10, weight: .medium))
                            .lineLimit(1)
                    }
                    .foregroundColor(themeColor)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(
                        Capsule()
                            .fill(themeColor.opacity(0.1))
                            .shadow(color: themeColor.opacity(0.2), radius: 2, x: 0, y: 1)
                    )
                }
            }
            
            Spacer()
            
            // Geliştirilmiş başlık
            VStack(spacing: 0) {
                Text("SUDOKU")
                    .font(.system(size: UIScreen.main.bounds.width < 400 ? 26 : 30, weight: .bold, design: .rounded))
                    .foregroundColor(isDarkMode ? .white : themeColor)
                
                Text(sudokuModel.difficulty.rawValue)
                    .font(.system(size: UIScreen.main.bounds.width < 400 ? 12 : 14, weight: .medium, design: .rounded))
                    .foregroundColor(isDarkMode ? themeColor.opacity(0.8) : themeColor.opacity(0.7))
            }
            
            Spacer()
            
            Button(action: {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    showingSettings.toggle()
                }
            }) {
                HStack(spacing: 5) {
                    Text("Ayarlar")
                        .font(.system(size: UIScreen.main.bounds.width >= 390 ? 14 : 12, weight: .medium))
                    Image(systemName: "gear")
                        .font(.system(size: UIScreen.main.bounds.width >= 390 ? 18 : 16))
                }
                .foregroundColor(isDarkMode ? .white : .black)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    Capsule()
                        .fill(isDarkMode ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1))
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                )
            }
            .padding(.trailing, numberButtonPadding)
        }
        .padding(.top, 10)
    }
    
    private var gameInfoView: some View {
        HStack(spacing: UIScreen.main.bounds.width >= 390 ? 15 : 8) {
            // Süre
            Button(action: {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    showingStats = true
                }
            }) {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(themeColor)
                    Text(formatTime(sudokuModel.gameTime))
                        .foregroundColor(isDarkMode ? .white : .black)
                        .font(.system(size: numberButtonFontSize, weight: .medium))
                }
                .padding(.vertical, 10)
                .padding(.horizontal, UIScreen.main.bounds.width >= 390 ? 15 : 10)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isDarkMode ? Color.black.opacity(0.3) : Color.white)
                            .shadow(color: themeColor.opacity(0.3), radius: 3, x: 0, y: 2)
                        
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(themeColor.opacity(0.3), lineWidth: 1.5)
                    }
                )
            }
            
            // Hatalar
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text("\(sudokuModel.mistakes)")
                    .foregroundColor(isDarkMode ? .white : .black)
                    .font(.system(size: numberButtonFontSize, weight: .medium))
            }
            .padding(.vertical, 10)
            .padding(.horizontal, UIScreen.main.bounds.width >= 390 ? 15 : 10)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isDarkMode ? Color.black.opacity(0.3) : Color.white)
                        .shadow(color: Color.red.opacity(0.3), radius: 3, x: 0, y: 2)
                    
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1.5)
                }
            )
        }
        .padding(.horizontal, numberButtonPadding)
        .padding(.top, 5)
    }
    
    private var noteModeButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
                noteMode.toggle()
                
                // Haptic feedback
                #if os(iOS)
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                #endif
            }
        }) {
            HStack {
                Image(systemName: noteMode ? "pencil.circle.fill" : "pencil.circle")
                    .font(.system(size: 18))
                Text(noteMode ? "Not Modu Açık" : "Not Modu")
                    .font(.system(size: 14))
            }
            .foregroundColor(noteMode ? themeColor : (isDarkMode ? .white : .black))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(noteMode ? themeColor.opacity(0.2) : (isDarkMode ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(themeColor.opacity(noteMode ? 0.5 : 0.2), lineWidth: 1)
            )
        }
        .padding(.horizontal, 5)
        .padding(.top, 5)
    }
    
    private var sudokuGridView: some View {
        VStack(spacing: 0) {
            ForEach(0..<3) { blockRow in
                HStack(spacing: 0) {
                    ForEach(0..<3) { blockCol in
                        SudokuBlock(
                            blockRow: blockRow,
                            blockCol: blockCol,
                            sudokuModel: sudokuModel,
                            selectedNumber: $selectedNumber,
                            themeColor: themeColor,
                            isDarkMode: isDarkMode
                        )
                        .id("block-\(blockRow)-\(blockCol)") // Sabit ID ile gereksiz yeniden render önlenir
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    isDarkMode ?
                    LinearGradient(
                        gradient: Gradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ) :
                    LinearGradient(
                        gradient: Gradient(colors: [Color.white, Color.gray.opacity(0.1)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: isDarkMode ? Color.black.opacity(0.5) : Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
        .cornerRadius(12)
        .padding(5)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isDarkMode ? Color.white.opacity(0.5) : Color.black.opacity(0.5), lineWidth: 3)
        )
        .scaleEffect(sudokuModel.isShaking ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: sudokuModel.isShaking)
        // Ölçeklendirme animasyonu
        .scaleEffect(sudokuModel.isGameComplete ? 1.05 : 1.0)
        
        // 3D rotasyon animasyonu
        .rotation3DEffect(
            sudokuModel.isGameComplete ? Angle(degrees: 360) : Angle(degrees: 0),
            axis: (x: 0.0, y: 1.0, z: 0.0)
        )
        .overlay(
            ZStack {
                // Parlama efekti
                RadialGradient(
                    gradient: Gradient(colors: [themeColor.opacity(0.8), themeColor.opacity(0.0)]),
                    center: .center,
                    startRadius: 5,
                    endRadius: 200
                )
                .scaleEffect(sudokuModel.isGameComplete ? 1.0 : 0.0)
                .opacity(sudokuModel.isGameComplete ? 0.8 : 0.0)
                .animation(.easeInOut(duration: 1.0), value: sudokuModel.isGameComplete)
                
                // Tebrik yazısı
                if sudokuModel.isGameComplete {
                    VStack {
                        Text("Tebrikler!")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: Color.black.opacity(0.5), radius: 3, x: 0, y: 1)
                        
                        Text("Sudoku'yu Tamamladınız")
                            .font(.system(size: 20, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(themeColor.opacity(0.8))
                            .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
                    )
                    .transition(.scale.combined(with: .opacity))
                    .onAppear {
                        // Konfeti göster
                        withAnimation {
                            showConfetti = true
                        }
                        // Haptik geri bildirim
                        #if os(iOS)
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                        #endif
                    }
                }
            }
        )
        .animation(.spring(response: 0.7, dampingFraction: 0.6), value: sudokuModel.isGameComplete)
        .drawingGroup() // Metal hızlandırma için
    }
    
    private var numberPickerView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { number in
                    numberButton(for: number)
                }
            }
            
            HStack(spacing: 12) {
                ForEach(6...9, id: \.self) { number in
                    numberButton(for: number)
                }
                
                // Silme butonu
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        if let cell = sudokuModel.selectedCell, sudokuModel.isCellEditable(at: cell.row, col: cell.col) {
                            if noteMode {
                                // Not modunda tüm notları temizle
                                sudokuModel.notes[cell.row][cell.col] = []
                            } else {
                                // Normal modda sayıyı sil
                                sudokuModel.grid[cell.row][cell.col] = nil
                            }
                            
                            // Haptic feedback
                            #if os(iOS)
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred(intensity: 0.5)
                            #endif
                        }
                    }
                }) {
                    Image(systemName: "delete.left")
                        .font(.system(size: numberButtonFontSize))
                        .foregroundColor(isDarkMode ? .white : .black)
                        .frame(width: buttonSize, height: buttonSize)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isDarkMode ? Color.red.opacity(0.2) : Color.red.opacity(0.1))
                                .shadow(color: Color.red.opacity(0.3), radius: 2, x: 0, y: 1)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                }
            }
        }
        .padding(.vertical, 10)
    }
    
    private func numberButton(for number: Int) -> some View {
        let isSelected = selectedNumber == number
        let isCompleted = completedNumbers.contains(number)
        
        return Button(action: {
            if !isCompleted {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    selectedNumber = number
                }
                
                if let selectedCell = sudokuModel.selectedCell {
                    if sudokuModel.isCellEditable(at: selectedCell.row, col: selectedCell.col) {
                        // Not modu aktifse, not ekle/çıkar
                        if noteMode {
                            sudokuModel.toggleNote(row: selectedCell.row, col: selectedCell.col, number: number)
                        } else {
                            // Sayıyı yerleştir
                            let isValid = sudokuModel.placeNumber(number, at: selectedCell)
                            
                            // Rakam girişi animasyonu
                            sudokuModel.successfulNumberEnter = isValid
                            sudokuModel.numberEnterAnimationCell = selectedCell
                            
                            // 0.3 saniye sonra animasyonu sıfırla
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                sudokuModel.numberEnterAnimationCell = nil
                            }
                            
                            // Sayı hatalıysa sallama animasyonu
                            if !isValid {
                                withAnimation(.default) {
                                    sudokuModel.isShaking = true
                                    
                                    // 0.3 saniye sonra sallama animasyonunu kapat
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        sudokuModel.isShaking = false
                                    }
                                }
                            }
                        }
                        
                        // Oyun tamamlandı mı kontrol et
                        if sudokuModel.checkGameCompletion() {
                            showConfetti = true
                            isGameOver = true
                        }
                        
                        updateCompletedNumbers()
                    }
                }
                
                // Haptic feedback - sadece iOS cihazlarda
                #if os(iOS)
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred(intensity: 0.3)
                #endif
            }
        }) {
            ZStack {
                // Arka plan
                RoundedRectangle(cornerRadius: 4)
                    .fill(backgroundColor)
                    .frame(width: cellSize, height: cellSize)
                    // Tüm hücreler için ince bir kenarlık ekle
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(isDarkMode ? Color.white.opacity(0.2) : Color.black.opacity(0.2), lineWidth: 0.5)
                    )
                    // Hücre seçildiğinde animasyon
                    .scaleEffect(isSelected ? 1.02 : 1.0)
                    .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isSelected)
                    // Hücre seçildiğinde hafif gölge efekti
                    .shadow(color: isSelected ? themeColor.opacity(0.4) : Color.clear, radius: 1.5)
                
                // Sayı
                Text("\(number)")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundColor(
                        isSelected ? 
                        (isDarkMode ? .white : themeColor) : 
                        (isDarkMode ? .white : .black)
                    )
                    .shadow(color: isSelected ? themeColor.opacity(0.5) : Color.clear, radius: isSelected ? 1 : 0)
                
                // Tamamlanmış sayılar için işaret
                if isCompleted {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red.opacity(0.4))
                            .frame(width: buttonSize, height: buttonSize)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                    }
                }
            }
            .scaleEffect(isSelected ? 1.1 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isCompleted)
    }
    
    private func updateCompletedNumbers() {
        var numberCount = Array(repeating: 0, count: 10) // 0-9 için sayaç (0 kullanılmayacak)
        
        // Izgaradaki her sayıyı say
        for row in 0..<9 {
            for col in 0..<9 {
                if let number = sudokuModel.grid[row][col] {
                    numberCount[number] += 1
                }
            }
        }
        
        // Tamamlanan sayıları belirle (9 kez kullanıldıysa)
        var completed = Set<Int>()
        for number in 1...9 {
            if numberCount[number] >= 9 {
                completed.insert(number)
            }
        }
        
        // Tamamlanan sayıları güncelle
        completedNumbers = completed
    }
    
    private func showHint() {
        showingHint = true
    }
    
    private func getHintText() -> String {
        // Optimize edilmiş ipucu sistemi
        guard let selectedCell = sudokuModel.selectedCell else {
            // Eğer seçili hücre yoksa, rastgele bir ipucu ver
            if let hint = sudokuModel.getHint() {
                return "Satır \(hint.row+1), Sütun \(hint.col+1)'e \(hint.value) sayısını yerleştirebilirsiniz."
            } else {
                return "Şu anda bir ipucu bulunamadı."
            }
        }
        
        // Seçili hücre için ipucu
        let row = selectedCell.row
        let col = selectedCell.col
        
        if sudokuModel.grid[row][col] != nil {
            return "Bu hücre zaten dolu. Başka bir hücre seçin."
        }
        
        if !sudokuModel.isCellEditable(at: row, col: col) {
            return "Bu hücre değiştirilemez. Başka bir hücre seçin."
        }
        
        if let hint = sudokuModel.getHint() {
            if hint.row == row && hint.col == col {
                return "Seçili hücreye \(hint.value) sayısını yerleştirebilirsiniz."
            } else {
                return "Satır \(hint.row+1), Sütun \(hint.col+1)'e \(hint.value) sayısını yerleştirebilirsiniz."
            }
        }
        
        return "Şu anda bir ipucu bulunamadı."
    }
    
    private func startTimer() {
        // Önceki zamanlayıcıyı iptal et
        timer?.invalidate()
        
        // Sayacı sıfırla
        sudokuModel.gameTime = 0
        
        // Yeni zamanlayıcı oluştur - 1 saniye aralıklarla
        timer = Timer(timeInterval: 1.0, repeats: true) { _ in
            // Eğer oyun bitmişse timer'ı durduralım
            if self.sudokuModel.isGameComplete {
                self.stopTimer()
                return
            }
            // Süreyi arttır
            self.sudokuModel.gameTime += 1
        }
        // Ana thread'de çalıştır ve daha doğru zamanlama için common modunu kullan
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        // SudokuModel içindeki timer'ı da durduralım
        sudokuModel.stopTimer()
    }
    
    private func resetTimer() {
        stopTimer()
        sudokuModel.gameTime = 0
        startTimer()
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let remainingSeconds = Int(timeInterval) % 60
        
        if minutes > 0 {
            return String(format: "%02d:%02d", minutes, remainingSeconds)
        } else {
            return String(format: "%02d", remainingSeconds)
        }
    }
    
    // Yeni oyun başlatma fonksiyonu
    private func startNewGame() {
        // Önce yükleme ekranını göster
        withAnimation(.easeIn(duration: 0.3)) {
            isLoading = true
        }
        
        // Yükleme ekranını göstermek için daha uzun bir gecikme
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Yeni oyun oluşturma işlemini arka planda yap
            DispatchQueue.global(qos: .userInitiated).async {
                // Yeni oyun verilerini hazırla
                let newNotes = Array(repeating: Array(repeating: [Int](), count: 9), count: 9)
                
                // Sudoku çözümünü oluştur (en yoğun işlem)
                autoreleasepool {
                    self.sudokuModel.prepareNewGame()
                }
                
                // Yapay gecikme ekle - yükleme ekranını görmek için
                Thread.sleep(forTimeInterval: 2.0)
                
                // UI güncellemelerini ana thread'de yap
                DispatchQueue.main.async {
                    // Önce UI güncellemelerini yap
                    self.sudokuModel.notes = newNotes
                    self.resetTimer()
                    self.completedNumbers = []
                    
                    // Sonra model güncellemesini tamamla
                    self.sudokuModel.finalizeNewGame()
                    
                    // Kısa bir gecikme ile yükleme ekranını kapat (daha iyi kullanıcı deneyimi için)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        withAnimation(.easeOut(duration: 0.5)) {
                            self.isLoading = false
                        }
                    }
                }
            }
        }
    }
}

struct SudokuBlock: View {
    let blockRow: Int
    let blockCol: Int
    @ObservedObject var sudokuModel: SudokuModel
    @Binding var selectedNumber: Int?
    let themeColor: Color
    let isDarkMode: Bool
    
    // Blok içindeki hücrelerin satır ve sütun indekslerini önceden hesapla
    private var cellIndices: [(row: Int, col: Int)] {
        var indices = [(Int, Int)]()
        for row in 0..<3 {
            for col in 0..<3 {
                indices.append((blockRow * 3 + row, blockCol * 3 + col))
            }
        }
        return indices
    }
    
    // Blok arka plan rengini hesapla
    private var blockBackground: some View {
        let isEvenBlock = (blockRow + blockCol) % 2 == 0
        return RoundedRectangle(cornerRadius: 6)
            .fill(
                isDarkMode ?
                (isEvenBlock ? Color.gray.opacity(0.25) : Color.gray.opacity(0.3)) :
                (isEvenBlock ? Color.gray.opacity(0.15) : Color.gray.opacity(0.2))
            )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<3) { row in
                HStack(spacing: 0) {
                    ForEach(0..<3) { col in
                        let index = row * 3 + col
                        let actualRow = cellIndices[index].row
                        let actualCol = cellIndices[index].col
                        
                        SudokuCellView(
                            row: actualRow,
                            col: actualCol,
                            sudokuModel: sudokuModel,
                            notes: sudokuModel.getNotes(row: actualRow, col: actualCol),
                            themeColor: themeColor,
                            isDarkMode: isDarkMode,
                            selectedNumber: $selectedNumber
                        )
                        .id("\(actualRow)-\(actualCol)") // Sabit ID ile gereksiz yeniden render önlenir
                    }
                }
            }
        }
        .background(blockBackground)
        .cornerRadius(6)
        .padding(2) // Bloklar arası boşluğu arttırdım
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isDarkMode ? Color.white.opacity(0.6) : Color.black.opacity(0.6), lineWidth: 2.5)
        )
    }
}

struct SudokuCellView: View {
    let row: Int
    let col: Int
    @ObservedObject var sudokuModel: SudokuModel
    let notes: [Int]
    let themeColor: Color
    let isDarkMode: Bool
    @Binding var selectedNumber: Int?
    
    // Ekran boyutuna göre hücre boyutunu ayarla - hesaplamayı optimize et
    private let cellSize: CGFloat = {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        let minDimension = min(screenWidth, screenHeight)
        
        if screenWidth >= 428 { // iPhone Pro Max modeller
            return minDimension / 9.5
        } else if screenWidth >= 390 { // iPhone Pro modeller
            return minDimension / 10
        } else { // iPhone mini ve standart modeller
            return minDimension / 10.5
        }
    }()
    
    private var isSelected: Bool {
        sudokuModel.selectedCell?.row == row && sudokuModel.selectedCell?.col == col
    }
    
    private var value: Int? {
        sudokuModel.grid[row][col]
    }
    
    private var fontSize: CGFloat {
        cellSize * 0.6
    }
    
    private var notesFontSize: CGFloat {
        cellSize * 0.25
    }
    
    private var notesItemSize: CGFloat {
        cellSize * 0.3
    }
    
    private var isInSameRowOrCol: Bool {
        guard let selectedCell = sudokuModel.selectedCell else { return false }
        return selectedCell.row == row || selectedCell.col == col
    }
    
    private var isInSameBlock: Bool {
        guard let selectedCell = sudokuModel.selectedCell else { return false }
        return (selectedCell.row / 3 == row / 3) && (selectedCell.col / 3 == col / 3)
    }
    
    private var isHighlightedNumber: Bool {
        guard let selectedCell = sudokuModel.selectedCell,
              let selectedNumber = sudokuModel.grid[selectedCell.row][selectedCell.col] else { return false }
        return value == selectedNumber
    }
    
    private var isEditable: Bool {
        sudokuModel.isCellEditable(at: row, col: col)
    }
    
    private var hasEnterAnimation: Bool {
        if let animCell = sudokuModel.numberEnterAnimationCell {
            return animCell.row == row && animCell.col == col
        }
        return false
    }
    
    private var backgroundColor: Color {
        if isSelected {
            // Seçilen hücre
            return themeColor.opacity(0.3)
        } else if isHighlightedNumber && value != nil {
            // Aynı sayıya sahip hücreler
            return themeColor.opacity(0.2)
        } else if isInSameRowOrCol {
            // Aynı satır veya sütundaki hücreler
            return themeColor.opacity(0.12)
        } else {
            // Diğer tüm hücreler (3x3 blok dahil)
            return isDarkMode ? Color.black.opacity(0.1) : Color.white.opacity(0.7)
        }
    }
    
    private var textColor: Color {
        if !isEditable {
            // Başlangıç hücreleri için farklı renk - daha belirgin
            return isDarkMode ? Color.yellow : Color.blue
        } else if isHighlightedNumber {
            return isDarkMode ? themeColor.opacity(0.9) : themeColor
        } else {
            return isDarkMode ? .white : .black
        }
    }
    
    var body: some View {
        Button(action: {
            sudokuModel.selectedCell = (row: self.row, col: self.col)
            
            // Haptic feedback - sadece iOS cihazlarda
            #if os(iOS)
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred(intensity: 0.3)
            #endif
        }) {
            ZStack {
                // Arka plan
                RoundedRectangle(cornerRadius: 4)
                    .fill(backgroundColor)
                    .frame(width: cellSize, height: cellSize)
                    // Tüm hücreler için ince bir kenarlık ekle
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(isDarkMode ? Color.white.opacity(0.2) : Color.black.opacity(0.2), lineWidth: 0.5)
                    )
                    // Hücre seçildiğinde animasyon
                    .scaleEffect(isSelected ? 1.02 : 1.0)
                    .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isSelected)
                    // Hücre seçildiğinde hafif gölge efekti
                    .shadow(color: isSelected ? themeColor.opacity(0.4) : Color.clear, radius: 1.5)
                
                // Değer veya notlar
                if let value = value {
                    Text("\(value)")
                        .font(.system(size: fontSize, weight: .semibold, design: .rounded))
                        .foregroundColor(textColor)
                        // Sayı girildiğinde animasyon
                        .scaleEffect(hasEnterAnimation ? (sudokuModel.successfulNumberEnter ? 1.2 : 0.9) : 1.0)
                        .opacity(hasEnterAnimation ? (sudokuModel.successfulNumberEnter ? 0.8 : 1.0) : 1.0)
                        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: sudokuModel.numberEnterAnimationCell != nil)
                        // Sayı uyumlu olmadığında sallama animasyonu
                        .modifier(ShakeEffect(animate: sudokuModel.isShaking && isSelected))
                        // Hata veya başarılı giriş için animasyon
                        .overlay(
                            Circle()
                                .fill(sudokuModel.successfulNumberEnter ? Color.green.opacity(0.3) : Color.red.opacity(0.3))
                                .scaleEffect(hasEnterAnimation ? 1.5 : 0.0)
                                .opacity(hasEnterAnimation ? 0.0 : 0.5)
                                .animation(.easeOut(duration: 0.3), value: hasEnterAnimation)
                                .allowsHitTesting(false)
                        )
                } else if !notes.isEmpty {
                    notesGrid
                }
            }
        }
    }
    
    private var notesGrid: some View {
        // Notları 3x3 grid olarak göster
        VStack(spacing: 1) {
            ForEach(0..<3) { rowIdx in
                HStack(spacing: 1) {
                    ForEach(0..<3) { colIdx in
                        let num = rowIdx * 3 + colIdx + 1
                        if notes.contains(num) {
                            Text("\(num)")
                                .font(.system(size: notesFontSize))
                                .foregroundColor(isDarkMode ? Color.white.opacity(0.6) : Color.black.opacity(0.6))
                                .frame(width: notesItemSize, height: notesItemSize)
                        } else {
                            Color.clear
                                .frame(width: notesItemSize, height: notesItemSize)
                        }
                    }
                }
            }
        }
        .frame(width: cellSize * 0.9, height: cellSize * 0.9)
    }
}

struct DifficultyPickerView: View {
    @Binding var difficulty: SudokuModel.Difficulty
    let themeColor: Color
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(SudokuModel.Difficulty.allCases, id: \.self) { level in
                    Button(action: {
                        difficulty = level
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Text(level.rawValue)
                                .font(.headline)
                            
                            Spacer()
                            
                            if difficulty == level {
                                Image(systemName: "checkmark")
                                    .foregroundColor(themeColor)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Zorluk Seviyesi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct StatsView: View {
    let gameTime: TimeInterval
    let mistakes: Int
    let difficulty: SudokuModel.Difficulty
    let themeColor: Color
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Oyun İstatistikleri")) {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(themeColor)
                        Text("Oyun Süresi:")
                        Spacer()
                        Text(formatTime(gameTime))
                            .fontWeight(.bold)
                    }
                    
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text("Yapılan Hatalar:")
                        Spacer()
                        Text("\(mistakes)")
                            .fontWeight(.bold)
                    }
                    
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(themeColor)
                        Text("Zorluk Seviyesi:")
                        Spacer()
                        Text(difficulty.rawValue)
                            .fontWeight(.bold)
                    }
                }
                
                Section(header: Text("Performans")) {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("Puan:")
                        Spacer()
                        Text("\(calculateScore())")
                            .fontWeight(.bold)
                    }
                }
            }
            .navigationTitle("İstatistikler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    private func calculateScore() -> Int {
        // Basit bir puan hesaplama sistemi
        let difficultyMultiplier: Int
        switch difficulty {
        case .kolay: difficultyMultiplier = 1
        case .orta: difficultyMultiplier = 2
        case .zor: difficultyMultiplier = 3
        }
        
        let timeScore = max(0, 1000 - Int(gameTime) * 2)
        let mistakesPenalty = mistakes * 50
        
        return max(0, (timeScore - mistakesPenalty) * difficultyMultiplier)
    }
}

// Konfeti efekti için view
struct ConfettiView: View {
    let colors: [Color] = [.red, .blue, .green, .yellow, .pink, .purple, .orange]
    @State private var confettiPieces: [ConfettiPiece] = []
    let pieceCount = 100
    
    struct ConfettiPiece: Identifiable {
        let id = UUID()
        let color: Color
        var position: CGPoint
        let rotation: Double
        let size: CGFloat
        let delay: Double
    }
    
    var body: some View {
        ZStack {
            ForEach(confettiPieces) { piece in
                Rectangle()
                    .fill(piece.color)
                    .frame(width: piece.size, height: piece.size * 3)
                    .position(piece.position)
                    .rotationEffect(.degrees(piece.rotation))
                    .opacity(0)
                    .animation(
                        Animation.timingCurve(0.2, 0.8, 0.5, 1)
                            .delay(piece.delay)
                            .speed(0.7)
                            .repeatForever(autoreverses: false),
                        value: UUID()
                    )
            }
        }
        .onAppear {
            confettiPieces = (0..<pieceCount).map { _ in
                let screenWidth = UIScreen.main.bounds.width
                
                return ConfettiPiece(
                    color: colors.randomElement()!,
                    position: CGPoint(
                        x: CGFloat.random(in: 0...screenWidth),
                        y: CGFloat.random(in: -50...0)
                    ),
                    rotation: Double.random(in: 0...360),
                    size: CGFloat.random(in: 5...12),
                    delay: Double.random(in: 0...1)
                )
            }
            
            // Konfeti animasyonu
            for (index, _) in confettiPieces.enumerated() {
                withAnimation(Animation.easeOut(duration: Double.random(in: 3...5)).delay(confettiPieces[index].delay)) {
                    confettiPieces[index].position.y = UIScreen.main.bounds.height + 50
                }
            }
        }
    }
}

// Sallama animasyonu için özel modifier
struct ShakeEffect: ViewModifier {
    var animate: Bool
    
    func body(content: Content) -> some View {
        content
            .offset(x: animate ? CGFloat.random(in: -2...2) : 0, y: animate ? CGFloat.random(in: -1...1) : 0)
            .animation(animate ? .linear(duration: 0.1).repeatCount(3, autoreverses: true) : .default, value: animate)
    }
}

// LoadingView sınıfını ekleyin
struct LoadingView: View {
    let themeColor: Color
    let isDarkMode: Bool
    @State private var isAnimating = false
    @State private var rotationAngle = 0.0
    
    var body: some View {
        ZStack {
            // Arka plan
            RoundedRectangle(cornerRadius: 20)
                .fill(isDarkMode ? Color.black.opacity(0.95) : Color.white.opacity(0.95))
                .shadow(color: themeColor.opacity(0.5), radius: 15, x: 0, y: 5)
                .frame(width: 300, height: 250)
            
            VStack(spacing: 20) {
                Text("Sudoku Hazırlanıyor...")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(isDarkMode ? .white : themeColor)
                
                // Dönen animasyon
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(themeColor, lineWidth: 6)
                    .frame(width: 70, height: 70)
                    .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                    .animation(Animation.linear(duration: 2).repeatForever(autoreverses: false), value: isAnimating)
                    .onAppear { isAnimating = true }
            }
        }
    }
}

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    var themeColor: Color
    @Binding var selectedThemeRaw: String
    @Binding var userColorSchemeRaw: String
    
    private var isDarkMode: Bool {
        switch userColorSchemeRaw {
        case "dark": return true
        case "light": return false
        default: return colorScheme == .dark
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Arka plan
                LinearGradient(gradient: Gradient(colors: isDarkMode ? 
                                                 [Color.blue.opacity(0.1), Color.purple.opacity(0.2), Color.black.opacity(0.3)] : 
                                                 [Color.blue.opacity(0.1), Color.purple.opacity(0.1), Color.white.opacity(0.2)]),
                             startPoint: .topLeading,
                             endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Tema Seçimi
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Tema Rengi")
                                .font(.headline)
                                .foregroundColor(themeColor)
                            
                            HStack(spacing: 15) {
                                ForEach(ThemeColor.allCases, id: \.self) { theme in
                                    Button(action: {
                                        selectedThemeRaw = theme.rawValue
                                    }) {
                                        Circle()
                                            .fill(theme.mainColor)
                                            .frame(width: 40, height: 40)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white, lineWidth: selectedThemeRaw == theme.rawValue ? 3 : 0)
                                            )
                                            .shadow(color: theme.mainColor.opacity(0.5), radius: 5, x: 0, y: 3)
                                    }
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(isDarkMode ? Color.black.opacity(0.3) : Color.white.opacity(0.9))
                            )
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
                        }
                        .padding(.horizontal)
                        
                        // Görünüm Modu
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Görünüm Modu")
                                .font(.headline)
                                .foregroundColor(themeColor)
                            
                            VStack(spacing: 10) {
                                Button(action: {
                                    userColorSchemeRaw = "light"
                                    UserDefaults.standard.synchronize()
                                }) {
                                    HStack {
                                        Image(systemName: "sun.max.fill")
                                            .foregroundColor(.orange)
                                        
                                        Text("Açık Mod")
                                            .foregroundColor(isDarkMode ? .white : .black)
                                        
                                        Spacer()
                                        
                                        if userColorSchemeRaw == "light" {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(themeColor)
                                        }
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(isDarkMode ? Color.black.opacity(0.3) : Color.white)
                                    )
                                }
                                
                                Button(action: {
                                    userColorSchemeRaw = "dark"
                                    UserDefaults.standard.synchronize()
                                }) {
                                    HStack {
                                        Image(systemName: "moon.fill")
                                            .foregroundColor(.purple)
                                        
                                        Text("Koyu Mod")
                                            .foregroundColor(isDarkMode ? .white : .black)
                                        
                                        Spacer()
                                        
                                        if userColorSchemeRaw == "dark" {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(themeColor)
                                        }
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(isDarkMode ? Color.black.opacity(0.3) : Color.white)
                                    )
                                }
                                
                                Button(action: {
                                    userColorSchemeRaw = "system"
                                    UserDefaults.standard.synchronize()
                                }) {
                                    HStack {
                                        Image(systemName: "gear")
                                            .foregroundColor(.gray)
                                        
                                        Text("Sistem Ayarı")
                                            .foregroundColor(isDarkMode ? .white : .black)
                                        
                                        Spacer()
                                        
                                        if userColorSchemeRaw == "system" {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(themeColor)
                                        }
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(isDarkMode ? Color.black.opacity(0.3) : Color.white)
                                    )
                                }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(isDarkMode ? Color.black.opacity(0.3) : Color.white.opacity(0.9))
                            )
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
                        }
                        .padding(.horizontal)
                        
                        // Uygulama Hakkında
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Hakkında")
                                .font(.headline)
                                .foregroundColor(themeColor)
                            
                            VStack(alignment: .leading, spacing: 15) {
                                HStack {
                                    Image(systemName: "app.fill")
                                        .foregroundColor(themeColor)
                                    Text("Sudoku Oyunu")
                                        .foregroundColor(isDarkMode ? .white : .black)
                                    Spacer()
                                    Text("Sürüm 1.0.0")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                HStack {
                                    Image(systemName: "envelope.fill")
                                        .foregroundColor(themeColor)
                                    Text("İletişim: ")
                                        .foregroundColor(isDarkMode ? .white : .black)
                                    Text("destek@sudoku.com")
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(isDarkMode ? Color.black.opacity(0.3) : Color.white.opacity(0.9))
                            )
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Ayarlar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(themeColor)
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 