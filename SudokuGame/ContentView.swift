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
    @State private var showingHowToPlay = false
    @State private var showingSettings = false
    @State private var selectedNumber: Int? = nil
    @State private var timer: Timer? = nil
    @State private var showingDifficultyPicker = false
    @State private var showConfetti = false
    @State private var showingStats = false
    @State private var showingHint = false
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = "Mavi"
    @State private var noteMode = false
    @State private var notes: [[[Int]]] = Array(repeating: Array(repeating: [], count: 9), count: 9)
    @State private var showingWelcomeScreen = true // İlk açılışta hoş geldiniz ekranını göster
    @State private var isLoading = true // Başlangıçta yükleme ekranını göster
    @Environment(\.colorScheme) var colorScheme
    @State private var showingGameCompleteAlert = false
    @AppStorage("userColorScheme") private var userColorSchemeRaw: String = "system"
    @State private var completedNumbers: Set<Int> = []
    @AppStorage("firstLaunch") private var isFirstLaunch: Bool = true
    
    // Sabit değerler - performans için önceden hesaplanır
    private let buttonSize: CGFloat = UIScreen.main.bounds.width < 375 ? 40 : 45
    private let numberButtonPadding: CGFloat = UIScreen.main.bounds.width < 375 ? 4 : 6
    private let numberButtonFontSize: CGFloat = UIScreen.main.bounds.width < 375 ? 20 : 22
    
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
        NavigationStack {
            ZStack {
                // Geliştirilmiş arka plan
                backgroundView
                
                if isLoading {
                    LoadingView(themeColor: themeColor, isDarkMode: isDarkMode)
                        .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .center)))
                        .zIndex(1) // Yükleme ekranını en üstte göster
                } else {
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
                }
            }
            .sheet(isPresented: $showingHowToPlay) {
                HowToPlayView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(isPresented: $showingSettings, themeColor: Binding(
                    get: { self.selectedTheme },
                    set: { self.selectedThemeRaw = $0.rawValue }
                ), sudokuModel: sudokuModel, userColorScheme: Binding(
                    get: { self.userColorScheme },
                    set: { 
                        switch $0 {
                        case .light: self.userColorSchemeRaw = "light"
                        case .dark: self.userColorSchemeRaw = "dark"
                        case .none: self.userColorSchemeRaw = "system"
                        @unknown default: self.userColorSchemeRaw = "system"
                        }
                        UserDefaults.standard.synchronize()
                    }
                ))
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
            .overlay(
                showConfetti ? ConfettiView() : nil
            )
            .onAppear {
                // İlk açılışta hoş geldiniz ekranını göster
                if isFirstLaunch {
                    showingWelcomeScreen = true
                    isFirstLaunch = false
                }
                
                // Uygulama başladığında yükleme ekranını göster
                withAnimation(.easeIn(duration: 0.3)) {
                    isLoading = true
                }
                
                // Uygulama başladığında otomatik kaydetmeyi başlat
                sudokuModel.startAutoSave()
                
                // Sayacı sıfırla
                sudokuModel.gameTime = 0
                
                // NotificationCenter dinleyicisi ekle
                setupNotificationObservers()
                
                // Yükleme ekranını gösterdikten sonra oyunu başlat
                startLoadingSequence()
            }
            .onDisappear {
                // Görünüm kaybolduğunda timer'ı durdur
                stopTimer()
                
                // NotificationCenter dinleyicisini kaldır
                NotificationCenter.default.removeObserver(self)
            }
            .fullScreenCover(isPresented: $showingWelcomeScreen) {
                WelcomeView()
            }
            .preferredColorScheme(userColorScheme)
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
                // Ana menüye dön
                stopTimer()
                showingWelcomeScreen = true
            }) {
                HStack(spacing: 5) {
                    Image(systemName: "house.fill")
                        .font(.system(size: UIScreen.main.bounds.width >= 390 ? 18 : 16))
                    Text("Ana Sayfa")
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
                            notes: $notes,
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
        .rotation3DEffect(
            sudokuModel.isGameComplete ? Angle(degrees: 360) : Angle(degrees: 0),
            axis: (x: 0.0, y: 1.0, z: 0.0)
        )
        .animation(.easeInOut(duration: 0.5), value: sudokuModel.isGameComplete)
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
                                notes[cell.row][cell.col] = []
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
                    // Seçili hücreye sayı gir
                    sudokuModel.enterNumber(number, at: selectedCell.row, col: selectedCell.col)
                    
                    // Sayı tamamlandı mı kontrol et
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
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
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isSelected ? 
                        themeColor.opacity(0.3) : 
                        (isDarkMode ? Color.black.opacity(0.2) : Color.white.opacity(0.9))
                    )
                    .shadow(
                        color: isSelected ? themeColor.opacity(0.5) : Color.black.opacity(0.1),
                        radius: isSelected ? 4 : 2,
                        x: 0,
                        y: isSelected ? 2 : 1
                    )
                    .frame(width: buttonSize, height: buttonSize)
                
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
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isSelected)
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
        timer = Timer(timeInterval: 1.0, repeats: true) { [self] _ in
            // SudokuModel'deki timer'ı durdur, çünkü orada da bir timer çalışıyor
            sudokuModel.stopTimer()
            // Sadece buradaki timer'ı kullan
            sudokuModel.gameTime += 1
        }
        // Ana thread'de çalıştır ve daha doğru zamanlama için common modunu kullan
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
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
                    self.notes = newNotes
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
    @Binding var notes: [[[Int]]]
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
                            notes: notes[actualRow][actualCol],
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
        .padding(1.5) // Bloklar arası boşluğu artır
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isDarkMode ? Color.white.opacity(0.4) : Color.black.opacity(0.4), lineWidth: 1.5)
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
    
    private var fontSize: CGFloat {
        cellSize * 0.6
    }
    
    private var notesFontSize: CGFloat {
        cellSize * 0.25
    }
    
    private var notesItemSize: CGFloat {
        cellSize * 0.3
    }
    
    private var value: Int? {
        sudokuModel.grid[row][col]
    }
    
    private var isSelected: Bool {
        sudokuModel.selectedCell?.row == row && sudokuModel.selectedCell?.col == col
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
    
    private var backgroundColor: Color {
        if isSelected {
            return themeColor.opacity(0.3)
        } else if isHighlightedNumber && value != nil {
            return themeColor.opacity(0.2)
        } else if isInSameRowOrCol {
            return themeColor.opacity(0.08)
        } else if isInSameBlock {
            return themeColor.opacity(0.04)
        } else {
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
                
                // Sayı olan hücreler için özel arka plan - SADECE SEÇİLİ OLDUĞUNDA
                if isSelected && value != nil {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            isDarkMode ? 
                            (isEditable ? Color.gray.opacity(0.3) : Color.gray.opacity(0.4)) : 
                            (isEditable ? Color.white : Color.white.opacity(0.95))
                        )
                        .shadow(
                            color: themeColor.opacity(0.6),
                            radius: 4,
                            x: 0,
                            y: 2
                        )
                        .frame(width: cellSize - 2, height: cellSize - 2)
                }
                
                // Aynı sayılar için özel arka plan
                else if isHighlightedNumber && value != nil {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            isDarkMode ? 
                            (isEditable ? Color.gray.opacity(0.2) : Color.gray.opacity(0.3)) : 
                            (isEditable ? Color.white.opacity(0.9) : Color.white.opacity(0.8))
                        )
                        .shadow(
                            color: themeColor.opacity(0.3),
                            radius: 2,
                            x: 0,
                            y: 1
                        )
                        .frame(width: cellSize - 2, height: cellSize - 2)
                }
                
                cellContent
            }
        }
        .buttonStyle(PlainButtonStyle())
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(
                    isSelected ? themeColor : (isDarkMode ? Color.white.opacity(0.2) : Color.black.opacity(0.2)), 
                    lineWidth: isSelected ? 2 : 0.5
                )
        )
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isSelected)
    }
    
    @ViewBuilder
    private var cellContent: some View {
        if let value = value {
            // Ana sayı - daha belirgin
            Text("\(value)")
                .font(.system(size: fontSize * 1.2, weight: isEditable ? .semibold : .bold, design: .rounded))
                .foregroundColor(textColor)
                .opacity(isHighlightedNumber || isSelected ? 1.0 : 0.9)
                .shadow(color: isSelected ? themeColor.opacity(0.7) : (isHighlightedNumber ? themeColor.opacity(0.3) : Color.clear), radius: isSelected ? 2 : 0.5)
                .scaleEffect(isSelected ? 1.2 : (isHighlightedNumber ? 1.1 : 1.0))
                .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isSelected)
                // Sayıların etrafına ince bir kontur ekle
                .overlay(
                    Text("\(value)")
                        .font(.system(size: fontSize * 1.2, weight: isEditable ? .semibold : .bold, design: .rounded))
                        .foregroundColor(isDarkMode ? Color.black.opacity(0.5) : Color.white.opacity(0.5))
                        .opacity(0.8)
                        .scaleEffect(isSelected ? 1.2 : (isHighlightedNumber ? 1.1 : 1.0))
                        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isSelected)
                        .blur(radius: 1.5)
                        .allowsHitTesting(false)
                )
                // Sayıların altına gölge ekle
                .background(
                    Text("\(value)")
                        .font(.system(size: fontSize * 1.2, weight: isEditable ? .semibold : .bold, design: .rounded))
                        .foregroundColor(isDarkMode ? Color.white.opacity(0.2) : Color.black.opacity(0.2))
                        .offset(x: 1, y: 1)
                        .blur(radius: 1.0)
                        .scaleEffect(isSelected ? 1.2 : (isHighlightedNumber ? 1.1 : 1.0))
                        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isSelected)
                        .allowsHitTesting(false)
                )
        } else if !notes.isEmpty {
            // Notlar
            notesGrid
        }
    }
    
    private var notesGrid: some View {
        // Daha verimli not gösterimi - LazyVGrid yerine manuel grid
        VStack(spacing: 0) {
            ForEach(0..<3) { row in
                HStack(spacing: 0) {
                    ForEach(0..<3) { col in
                        let number = row * 3 + col + 1
                        if notes.contains(number) {
                            Text("\(number)")
                                .font(.system(size: notesFontSize))
                                .foregroundColor(
                                    number == selectedNumber ? 
                                    (isDarkMode ? themeColor.opacity(0.9) : themeColor.opacity(0.8)) : 
                                    (isDarkMode ? Color.white.opacity(0.6) : Color.black.opacity(0.6))
                                )
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

struct ConfettiView: View {
    @State private var isAnimating = false
    let colors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange]
    let confettiCount = 100
    
    var body: some View {
        ZStack {
            ForEach(0..<confettiCount, id: \.self) { index in
                ConfettiPiece(color: colors[index % colors.count], isAnimating: $isAnimating)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

struct ConfettiPiece: View {
    let color: Color
    @Binding var isAnimating: Bool
    @State private var xPosition: CGFloat = 0
    @State private var yPosition: CGFloat = -100
    @State private var rotation: Double = 0
    
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: CGFloat.random(in: 5...10), height: CGFloat.random(in: 5...10))
            .position(x: xPosition, y: yPosition)
            .rotationEffect(.degrees(rotation))
            .opacity(yPosition > UIScreen.main.bounds.height * 0.8 ? 0 : 1)
            .onAppear {
                withAnimation(Animation.linear(duration: Double.random(in: 2...4)).repeatForever(autoreverses: false)) {
                    self.xPosition = CGFloat.random(in: 0...UIScreen.main.bounds.width)
                    self.yPosition = UIScreen.main.bounds.height + 50
                    self.rotation = Double.random(in: 0...360) * 5
                }
            }
    }
}

struct SettingsView: View {
    @Binding var isPresented: Bool
    @Binding var themeColor: ThemeColor
    @ObservedObject var sudokuModel: SudokuModel
    @Environment(\.colorScheme) var colorScheme
    @Binding var userColorScheme: ColorScheme?
    @AppStorage("userColorScheme") private var userColorSchemeRaw: String = "system"
    
    private var isDarkMode: Bool {
        userColorScheme == .dark || (userColorScheme == nil && colorScheme == .dark)
    }
    
    private let themeColors: [ThemeColor] = ThemeColor.allCases
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Ayarlar")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(isDarkMode ? .white : .black)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        isPresented = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
            .padding(.bottom, 10)
            
            // Zorluk seviyesi ayarı
            VStack(alignment: .leading, spacing: 10) {
                Text("Zorluk Seviyesi")
                    .font(.headline)
                    .foregroundColor(isDarkMode ? .white : .black)
                
                HStack {
                    ForEach(SudokuModel.Difficulty.allCases, id: \.self) { difficulty in
                        Button(action: {
                            sudokuModel.difficulty = difficulty
                        }) {
                            Text(difficulty.rawValue)
                                .padding(.horizontal, 15)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(sudokuModel.difficulty == difficulty ? 
                                              themeColor.mainColor.opacity(0.3) : 
                                              (isDarkMode ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1)))
                                )
                                .foregroundColor(sudokuModel.difficulty == difficulty ? 
                                                themeColor.mainColor : 
                                                (isDarkMode ? .white : .black))
                        }
                    }
                }
            }
            .padding(.bottom, 10)
            
            // Tema rengi ayarı
            VStack(alignment: .leading, spacing: 10) {
                Text("Tema Rengi")
                    .font(.headline)
                    .foregroundColor(isDarkMode ? .white : .black)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 15) {
                    ForEach(themeColors, id: \.self) { color in
                        Circle()
                            .fill(color.mainColor)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle()
                                    .stroke(color == themeColor ? .white : .clear, lineWidth: 2)
                            )
                            .shadow(color: color.mainColor.opacity(0.5), radius: 3, x: 0, y: 2)
                            .onTapGesture {
                                withAnimation {
                                    themeColor = color
                                }
                            }
                    }
                }
            }
            .padding(.bottom, 10)
            
            // Koyu/Açık mod ayarı
            VStack(alignment: .leading, spacing: 10) {
                Text("Görünüm Modu")
                    .font(.headline)
                    .foregroundColor(isDarkMode ? .white : .black)
                
                HStack(spacing: 15) {
                    Button(action: {
                        withAnimation {
                            userColorScheme = .light
                            userColorSchemeRaw = "light"
                            UserDefaults.standard.synchronize()
                        }
                    }) {
                        HStack {
                            Image(systemName: "sun.max.fill")
                                .font(.system(size: 18))
                            Text("Açık Mod")
                        }
                        .padding(.horizontal, 15)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(userColorScheme == .light ? 
                                      themeColor.mainColor.opacity(0.3) : 
                                      (isDarkMode ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1)))
                                )
                                .foregroundColor(userColorScheme == .light ? 
                                                themeColor.mainColor : 
                                                (isDarkMode ? .white : .black))
                        )
                    }
                    
                    Button(action: {
                        withAnimation {
                            userColorScheme = .dark
                            userColorSchemeRaw = "dark"
                            UserDefaults.standard.synchronize()
                        }
                    }) {
                        HStack {
                            Image(systemName: "moon.fill")
                                .font(.system(size: 18))
                            Text("Koyu Mod")
                        }
                        .padding(.horizontal, 15)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(userColorScheme == .dark ? 
                                      themeColor.mainColor.opacity(0.3) : 
                                      (isDarkMode ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1)))
                                )
                                .foregroundColor(userColorScheme == .dark ? 
                                                themeColor.mainColor : 
                                                (isDarkMode ? .white : .black))
                        )
                    }
                    
                    Button(action: {
                        withAnimation {
                            userColorScheme = nil
                            userColorSchemeRaw = "system"
                            UserDefaults.standard.synchronize()
                        }
                    }) {
                        HStack {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 18))
                            Text("Sistem")
                        }
                        .padding(.horizontal, 15)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(userColorScheme == nil ? 
                                      themeColor.mainColor.opacity(0.3) : 
                                      (isDarkMode ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1)))
                                )
                                .foregroundColor(userColorScheme == nil ? 
                                                themeColor.mainColor : 
                                                (isDarkMode ? .white : .black))
                        )
                    }
                }
            }
            .padding(.bottom, 10)
            
            // Yeni oyun butonu
            Button(action: {
                withAnimation {
                    sudokuModel.generateNewGame()
                    isPresented = false
                }
            }) {
                Text("Yeni Oyun Başlat")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(themeColor.mainColor)
                    )
                    .shadow(color: themeColor.mainColor.opacity(0.3), radius: 5, x: 0, y: 2)
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: 400)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(isDarkMode ? Color(UIColor.systemBackground) : Color.white)
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
        .padding()
    }
}

struct LoadingView: View {
    let themeColor: Color
    let isDarkMode: Bool
    @State private var isAnimating = false
    @State private var rotationAngle = 0.0
    @State private var scaleEffect = 1.0
    @State private var opacity = 0.7
    @State private var progressValue = 0.0
    @State private var tipIndex = 0
    
    // Yükleme ekranında gösterilecek ipuçları
    private let tips = [
        "Önce kolay olan hücreleri doldurun",
        "Eleme yöntemini kullanarak ilerleyin",
        "Not alma özelliğini kullanın",
        "Aynı satır ve sütunda aynı sayı olamaz",
        "Her 3x3 kutuda 1-9 arası sayılar birer kez olmalı",
        "Zorlandığınızda ipucu alabilirsiniz",
        "Tema rengini ayarlardan değiştirebilirsiniz",
        "Açık/koyu mod arasında geçiş yapabilirsiniz"
    ]
    
    var body: some View {
        ZStack {
            // Arka plan efekti
            RoundedRectangle(cornerRadius: 20)
                .fill(isDarkMode ? 
                      Color.black.opacity(0.8) : 
                      Color.white.opacity(0.9))
                .shadow(color: themeColor.opacity(0.3), radius: 15, x: 0, y: 5)
                .frame(width: 300, height: 250)
            
            VStack(spacing: 20) {
                Text("Sudoku Hazırlanıyor...")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(isDarkMode ? .white : themeColor)
                    .shadow(color: themeColor.opacity(0.3), radius: 2, x: 0, y: 1)
                    .scaleEffect(scaleEffect)
                    .opacity(opacity)
                
                ZStack {
                    // Arka plan dairesi
                    Circle()
                        .stroke(lineWidth: 6)
                        .frame(width: 70, height: 70)
                        .foregroundColor(themeColor.opacity(0.2))
                    
                    // Dönen daire
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [themeColor.opacity(0.5), themeColor]),
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 70, height: 70)
                        .rotationEffect(Angle(degrees: rotationAngle))
                    
                    // İç daire
                    Circle()
                        .fill(themeColor.opacity(0.3))
                        .frame(width: 20, height: 20)
                        .scaleEffect(scaleEffect)
                    
                    // Sudoku ızgara simgesi - Grid yerine manuel ızgara
                    ZStack {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: 30, height: 30)
                        
                        // Manuel ızgara oluşturma
                        VStack(spacing: 2) {
                            ForEach(0..<3, id: \.self) { row in
                                HStack(spacing: 2) {
                                    ForEach(0..<3, id: \.self) { col in
                                        RoundedRectangle(cornerRadius: 1)
                                            .fill(isDarkMode ? Color.white : themeColor)
                                            .opacity(0.8)
                                            .frame(width: 8, height: 8)
                                    }
                                }
                            }
                        }
                    }
                }
                .scaleEffect(0.8)
                
                // İpucu metni
                Text(tips[tipIndex])
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isDarkMode ? Color.white.opacity(0.9) : Color.black.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .frame(height: 40)
                    .frame(width: 250)
                    .transition(.opacity)
                    .id("tip-\(tipIndex)") // Animasyon için benzersiz ID
                
                // İlerleme göstergesi
                ProgressView(value: progressValue, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: themeColor))
                    .frame(width: 200)
                    .scaleEffect(0.8)
            }
            .padding(30)
        }
        .onAppear {
            // Performans iyileştirmeleri için
            DispatchQueue.main.async {
                // Animasyonları başlat
                withAnimation(Animation.linear(duration: 2).repeatForever(autoreverses: false)) {
                    rotationAngle = 360
                }
                
                withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    scaleEffect = 1.1
                    opacity = 1.0
                }
                
                // İlerleme çubuğu animasyonu
                withAnimation(Animation.easeInOut(duration: 2.5)) {
                    progressValue = 1.0
                }
                
                // İpuçlarını değiştir
                startTipTimer()
                
                isAnimating = true
            }
        }
        .drawingGroup() // Metal hızlandırma için
    }
    
    // İpuçlarını değiştiren zamanlayıcı
    private func startTipTimer() {
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { timer in
            withAnimation(.easeInOut(duration: 0.5)) {
                tipIndex = (tipIndex + 1) % tips.count
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 