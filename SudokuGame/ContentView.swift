import SwiftUI

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
    @State private var showingHowToPlay = false
    @State private var showingSettings = false
    @State private var selectedNumber: Int? = nil
    @State private var timer: Timer? = nil
    @State private var isDarkMode = false
    @State private var showingDifficultyPicker = false
    @State private var showConfetti = false
    @State private var showingStats = false
    @State private var showingHint = false
    @State private var selectedTheme: ThemeColor = .blue
    @State private var noteMode = false
    @State private var notes: [[[Int]]] = Array(repeating: Array(repeating: [], count: 9), count: 9)
    @State private var showingWelcomeScreen = false
    @State private var isLoading = false
    @Environment(\.colorScheme) var colorScheme
    @State private var showingGameCompleteAlert = false
    
    // Sabit değerler - performans için önceden hesaplanır
    private let buttonSize: CGFloat = UIScreen.main.bounds.width < 375 ? 40 : 45
    private let numberButtonPadding: CGFloat = UIScreen.main.bounds.width < 375 ? 4 : 6
    private let numberButtonFontSize: CGFloat = UIScreen.main.bounds.width < 375 ? 20 : 22
    
    private var isDarkMode: Bool {
        colorScheme == .dark
    }
    
    var themeColor: Color {
        selectedTheme.mainColor
    }
    
    var themeSecondaryColor: Color {
        selectedTheme.secondaryColor
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Geliştirilmiş arka plan
                backgroundView
                
                if isLoading {
                    LoadingView(themeColor: themeColor, isDarkMode: isDarkMode)
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
                        
                        // Geliştirilmiş silme butonu
                        deleteButton
                    }
                }
            }
            .sheet(isPresented: $showingHowToPlay) {
                HowToPlayView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(isPresented: $showingSettings, themeColor: $selectedTheme, sudokuModel: sudokuModel)
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
                        showConfetti = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            showConfetti = false
                        }
                        sudokuModel.generateNewGame()
                        resetTimer()
                        notes = Array(repeating: Array(repeating: [], count: 9), count: 9)
                    }
                )
            }
            .overlay(
                showConfetti ? ConfettiView() : nil
            )
            .onAppear {
                startTimer()
            }
            .onDisappear {
                stopTimer()
            }
            .fullScreenCover(isPresented: $showingWelcomeScreen) {
                WelcomeView()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
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
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    stopTimer()
                    showingWelcomeScreen = true
                }
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
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                noteMode.toggle()
            }
        }) {
            HStack {
                Image(systemName: noteMode ? "pencil.circle.fill" : "pencil.circle")
                    .font(.system(size: numberButtonFontSize + 2))
                Text("Not Modu")
                    .font(.system(size: numberButtonFontSize, weight: noteMode ? .semibold : .medium))
            }
            .foregroundColor(noteMode ? .white : (isDarkMode ? .white : .black))
            .padding(.vertical, 10)
            .padding(.horizontal, UIScreen.main.bounds.width >= 390 ? 20 : 15)
            .background(noteModeBackground)
        }
        .padding(.horizontal, numberButtonPadding)
        .padding(.top, 5)
    }
    
    private var noteModeBackground: some View {
        Group {
            if noteMode {
                LinearGradient(
                    gradient: Gradient(colors: [themeColor.opacity(0.8), themeColor]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: themeColor.opacity(0.5), radius: 3, x: 0, y: 2)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isDarkMode ? Color.gray.opacity(0.3) : Color.gray.opacity(0.1))
                    .shadow(color: Color.gray.opacity(0.2), radius: 2, x: 0, y: 1)
            }
        }
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
            RoundedRectangle(cornerRadius: 8)
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
                .shadow(color: isDarkMode ? Color.black.opacity(0.3) : Color.gray.opacity(0.3), radius: 5, x: 0, y: 2)
        )
        .cornerRadius(8)
        .padding(5)
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
        HStack(spacing: 4) {
            ForEach(1...9, id: \.self) { number in
                Button(action: {
                    numberButtonAction(number: number)
                }) {
                    Text("\(number)")
                        .font(.system(size: UIScreen.main.bounds.width >= 390 ? 28 : 24, weight: .bold))
                        .frame(width: buttonSize, height: buttonSize)
                        .background(numberButtonBackground(for: number))
                        .foregroundColor(selectedNumber == number ? .white : (isDarkMode ? .white : .black))
                        .scaleEffect(selectedNumber == number ? 1.05 : 1.0)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, numberButtonPadding)
        .padding(.vertical, 10)
    }
    
    private func numberButtonBackground(for number: Int) -> some View {
        ZStack {
            if selectedNumber == number {
                LinearGradient(
                    gradient: Gradient(colors: [themeColor, themeSecondaryColor]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(color: themeColor.opacity(0.5), radius: 3, x: 0, y: 2)
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(isDarkMode ? Color.gray.opacity(0.2) : Color.gray.opacity(0.2))
                    .shadow(color: Color.gray.opacity(0.2), radius: 3, x: 0, y: 2)
            }
            
            RoundedRectangle(cornerRadius: 10)
                .stroke(themeColor.opacity(0.3), lineWidth: 1)
        }
    }
    
    private var deleteButton: some View {
        Button(action: {
            deleteButtonAction()
        }) {
            HStack {
                Image(systemName: "delete.left.fill")
                    .font(.system(size: UIScreen.main.bounds.width >= 390 ? 18 : 16))
                Text("Sil")
                    .font(.system(size: UIScreen.main.bounds.width >= 390 ? 16 : 14, weight: .semibold))
            }
            .padding(.vertical, 10)
            .padding(.horizontal, UIScreen.main.bounds.width >= 390 ? 25 : 20)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.red.opacity(0.8), Color.red]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            )
            .foregroundColor(.white)
            .shadow(color: Color.red.opacity(0.4), radius: 3, x: 0, y: 2)
        }
        .padding(.bottom, 10)
    }
    
    // MARK: - Yardımcı fonksiyonlar
    
    private func numberButtonAction(number: Int) {
        if let selected = sudokuModel.selectedCell {
            if noteMode {
                // Not modu aktifse, notu ekle veya çıkar
                withAnimation(.easeInOut(duration: 0.1)) {
                    toggleNote(number: number, at: selected)
                    
                    // Haptic feedback - sadece iOS cihazlarda
                    #if os(iOS)
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred(intensity: 0.5)
                    #endif
                }
            } else if sudokuModel.grid[selected.row][selected.col] == nil {
                // Normal mod, sayıyı yerleştir
                withAnimation(.easeInOut(duration: 0.1)) {
                    let success = sudokuModel.placeNumber(number)
                    
                    // Haptic feedback - sadece iOS cihazlarda
                    #if os(iOS)
                    let generator = UIImpactFeedbackGenerator(style: success ? .medium : .heavy)
                    generator.impactOccurred(intensity: success ? 0.7 : 1.0)
                    #endif
                }
            }
        }
        withAnimation(.easeInOut(duration: 0.1)) {
            selectedNumber = number
        }
    }
    
    private func deleteButtonAction() {
        if let selected = sudokuModel.selectedCell {
            withAnimation(.easeInOut(duration: 0.1)) {
                if noteMode {
                    // Not modunda tüm notları temizle
                    notes[selected.row][selected.col] = []
                } else if sudokuModel.grid[selected.row][selected.col] != nil {
                    // Normal modda hücreyi temizle
                    sudokuModel.clearCell(at: selected.row, col: selected.col)
                }
                
                // Haptic feedback - sadece iOS cihazlarda
                #if os(iOS)
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred(intensity: 0.5)
                #endif
            }
        }
    }
    
    private func toggleNote(number: Int, at cell: (row: Int, col: Int)) {
        if sudokuModel.grid[cell.row][cell.col] != nil {
            return // Eğer hücrede zaten bir sayı varsa not eklenemez
        }
        
        if notes[cell.row][cell.col].contains(number) {
            // Notu kaldır
            notes[cell.row][cell.col].removeAll { $0 == number }
        } else {
            // Notu ekle
            notes[cell.row][cell.col].append(number)
            notes[cell.row][cell.col].sort()
        }
    }
    
    private func showHint() {
        showingHint = true
    }
    
    private func getHintText() -> String {
        // Optimize edilmiş ipucu sistemi
        guard let selectedCell = sudokuModel.selectedCell else {
            // Eğer seçili hücre yoksa, rastgele bir ipucu ver
            var hints = [(row: Int, col: Int, num: Int)]()
            
            for row in 0..<9 {
                for col in 0..<9 {
                    if sudokuModel.grid[row][col] == nil && sudokuModel.isCellEditable(at: row, col: col) {
                        if let correctNumber = sudokuModel.getCorrectNumber(at: row, col: col) {
                            hints.append((row: row, col: col, num: correctNumber))
                        }
                    }
                }
            }
            
            if hints.isEmpty {
                return "Şu anda bir ipucu bulunamadı."
            }
            
            let randomHint = hints.randomElement()!
            return "Satır \(randomHint.row+1), Sütun \(randomHint.col+1)'e \(randomHint.num) sayısını yerleştirebilirsiniz."
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
        
        if let correctNumber = sudokuModel.getCorrectNumber(at: row, col: col) {
            return "Seçili hücreye \(correctNumber) sayısını yerleştirebilirsiniz."
        }
        
        return "Şu anda bir ipucu bulunamadı."
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            sudokuModel.gameTime += 1
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func resetTimer() {
        stopTimer()
        sudokuModel.gameTime = 0
        startTimer()
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) / 60 % 60
        let seconds = Int(timeInterval) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    // Yeni oyun başlatma fonksiyonu
    private func startNewGame() {
        isLoading = true
        
        // Yeni oyun oluşturma işlemini arka planda yap
        DispatchQueue.global(qos: .userInitiated).async {
            // Yeni oyun verilerini hazırla
            let newNotes = Array(repeating: Array(repeating: [Int](), count: 9), count: 9)
            
            // UI güncellemelerini ana thread'de yap
            DispatchQueue.main.async {
                // Önce UI güncellemelerini yap
                self.notes = newNotes
                self.resetTimer()
                
                // Sonra model güncellemesini yap
                self.sudokuModel.generateNewGame()
                self.isLoading = false
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
        return Rectangle()
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
                            isDarkMode: isDarkMode
                        )
                        .id("\(actualRow)-\(actualCol)") // Sabit ID ile gereksiz yeniden render önlenir
                    }
                }
            }
        }
        .background(blockBackground)
        .cornerRadius(4)
        .padding(0.5)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(isDarkMode ? Color.gray.opacity(0.6) : Color.gray.opacity(0.5), lineWidth: 1.5)
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
            return themeColor.opacity(0.15)
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
            // Başlangıç hücreleri için farklı renk
            return isDarkMode ? themeColor : themeColor.opacity(0.8)
        } else if isHighlightedNumber {
            return isDarkMode ? themeColor.opacity(0.9) : themeColor
        } else {
            return isDarkMode ? .white : .black
        }
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
                sudokuModel.selectedCell = (row: row, col: col)
                
                // Haptic feedback - sadece iOS cihazlarda
                #if os(iOS)
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred(intensity: 0.3)
                #endif
            }
        }) {
            ZStack {
                Rectangle()
                    .fill(backgroundColor)
                    .frame(width: cellSize, height: cellSize)
                
                cellContent
            }
        }
        .buttonStyle(PlainButtonStyle())
        .overlay(
            RoundedRectangle(cornerRadius: 2)
                .stroke(isSelected ? themeColor : Color.clear, lineWidth: isSelected ? 2 : 0)
        )
        .scaleEffect(isSelected ? 1.01 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isSelected)
        .animation(.easeInOut(duration: 0.1), value: isHighlightedNumber)
    }
    
    @ViewBuilder
    private var cellContent: some View {
        if let value = value {
            // Ana sayı
            Text("\(value)")
                .font(.system(size: fontSize, weight: isEditable ? .regular : .bold))
                .foregroundColor(textColor)
                .opacity(isHighlightedNumber ? 1.0 : 0.9)
                .shadow(color: isHighlightedNumber ? themeColor.opacity(0.3) : Color.clear, radius: 0.5)
        } else if !notes.isEmpty {
            // Notlar
            notesGrid
        }
    }
    
    private var notesGrid: some View {
        VStack(spacing: 0) {
            ForEach(0..<3) { row in
                HStack(spacing: 0) {
                    ForEach(1...3, id: \.self) { col in
                        noteCell(for: row * 3 + col)
                    }
                }
            }
        }
        .frame(width: cellSize * 0.9, height: cellSize * 0.9)
    }
    
    @ViewBuilder
    private func noteCell(for number: Int) -> some View {
        if notes.contains(number) {
            Text("\(number)")
                .font(.system(size: notesFontSize))
                .foregroundColor(
                    number == selectedNumber ? 
                    (isDarkMode ? themeColor.opacity(0.9) : themeColor.opacity(0.8)) : 
                    (isDarkMode ? .white.opacity(0.6) : .black.opacity(0.6))
                )
                .frame(width: notesItemSize, height: notesItemSize)
        } else {
            Color.clear
                .frame(width: notesItemSize, height: notesItemSize)
        }
    }
}

struct DifficultyPickerView: View {
    @Binding var difficulty: SudokuModel.Difficulty
    let themeColor: Color
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
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
            .navigationBarItems(trailing: Button("Kapat") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct StatsView: View {
    let gameTime: Int
    let mistakes: Int
    let difficulty: SudokuModel.Difficulty
    let themeColor: Color
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
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
            .navigationBarItems(trailing: Button("Kapat") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    private func calculateScore() -> Int {
        // Basit bir puan hesaplama sistemi
        let difficultyMultiplier: Int
        switch difficulty {
        case .easy: difficultyMultiplier = 1
        case .medium: difficultyMultiplier = 2
        case .hard: difficultyMultiplier = 3
        }
        
        let timeScore = max(0, 1000 - gameTime * 2)
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
    @Binding var themeColor: Color
    @ObservedObject var sudokuModel: SudokuModel
    @Environment(\.colorScheme) var colorScheme
    
    private var isDarkMode: Bool {
        colorScheme == .dark
    }
    
    private let themeColors: [Color] = [
        .blue, .green, .purple, .orange, .pink, .red, .teal, .indigo
    ]
    
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
                                              themeColor.opacity(0.3) : 
                                              (isDarkMode ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1)))
                                )
                                .foregroundColor(sudokuModel.difficulty == difficulty ? 
                                                themeColor : 
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
                            .fill(color)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle()
                                    .stroke(color == themeColor ? .white : .clear, lineWidth: 2)
                            )
                            .shadow(color: color.opacity(0.5), radius: 3, x: 0, y: 2)
                            .onTapGesture {
                                withAnimation {
                                    themeColor = color
                                }
                            }
                    }
                }
            }
            .padding(.bottom, 10)
            
            // Yeni oyun butonu
            Button(action: {
                withAnimation {
                    sudokuModel.newGame()
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
                            .fill(themeColor)
                    )
                    .shadow(color: themeColor.opacity(0.3), radius: 5, x: 0, y: 2)
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
    
    var body: some View {
        VStack {
            Text("Sudoku Hazırlanıyor...")
                .font(.title)
                .foregroundColor(isDarkMode ? .white : themeColor)
                .padding()
            
            Circle()
                .stroke(lineWidth: 4)
                .frame(width: 50, height: 50)
                .foregroundColor(themeColor.opacity(0.3))
                .overlay(
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(themeColor, lineWidth: 4)
                        .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                        .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
                )
                .onAppear {
                    isAnimating = true
                }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(isDarkMode ? Color.black.opacity(0.7) : Color.white.opacity(0.9))
                .shadow(color: Color.black.opacity(0.2), radius: 10)
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

class SudokuModel: ObservableObject {
    enum Difficulty: String, CaseIterable, Identifiable {
        case kolay = "Kolay"
        case orta = "Orta"
        case zor = "Zor"
        
        var id: String { self.rawValue }
    }
    
    @Published var grid: [[Int?]] = Array(repeating: Array(repeating: nil, count: 9), count: 9)
    @Published var originalGrid: [[Int?]] = Array(repeating: Array(repeating: nil, count: 9), count: 9)
    @Published var selectedCell: (row: Int, col: Int)? = nil
    @Published var isShaking = false
    @Published var difficulty: Difficulty = .orta
    @Published var gameTime: TimeInterval = 0
    @Published var mistakes: Int = 0
    @Published var isGameComplete: Bool = false
    
    private var timer: Timer?
    private var solution: [[Int]] = Array(repeating: Array(repeating: 0, count: 9), count: 9)
    
    // Performans için önbelleğe alınmış değerler
    private var validMovesCache: [String: Bool] = [:]
    private var cellEditabilityCache: [String: Bool] = [:]
    
    init() {
        generateNewGame()
        startTimer()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    func generateNewGame() {
        // Önbelleği temizle
        validMovesCache.removeAll()
        cellEditabilityCache.removeAll()
        
        // Yeni oyun oluştur
        generateSolution()
        selectedCell = nil
        isShaking = false
        gameTime = 0
        mistakes = 0
        isGameComplete = false
        
        // Zorluk seviyesine göre ipuçlarını belirle
        var hints: Int
        
        switch difficulty {
        case .kolay:
            hints = 45 // Daha fazla ipucu = daha kolay
        case .orta:
            hints = 35
        case .zor:
            hints = 25 // Daha az ipucu = daha zor
        }
        
        // Boş ızgara oluştur
        grid = Array(repeating: Array(repeating: nil, count: 9), count: 9)
        
        // Rastgele ipuçlarını yerleştir
        var positions = [(row: Int, col: Int)]()
        for row in 0..<9 {
            for col in 0..<9 {
                positions.append((row: row, col: col))
            }
        }
        positions.shuffle()
        
        for i in 0..<hints {
            let pos = positions[i]
            grid[pos.row][pos.col] = solution[pos.row][pos.col]
        }
        
        // Orijinal ızgarayı kaydet
        originalGrid = grid.map { $0.map { $0 } }
        
        // Zamanlayıcıyı yeniden başlat
        timer?.invalidate()
        startTimer()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.gameTime += 1
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func shake() {
        isShaking = true
        
        // Titreşimi 0.3 saniye sonra durdur
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.isShaking = false
        }
    }
    
    func isCellEditable(at row: Int, col: Int) -> Bool {
        let key = "\(row)-\(col)"
        
        // Önbellekte varsa, önbellekten döndür
        if let cached = cellEditabilityCache[key] {
            return cached
        }
        
        // Yoksa hesapla ve önbelleğe al
        let result = originalGrid[row][col] == nil
        cellEditabilityCache[key] = result
        return result
    }
    
    func isValidMove(number: Int, at row: Int, col: Int) -> Bool {
        let key = "\(row)-\(col)-\(number)"
        
        // Önbellekte varsa, önbellekten döndür
        if let cached = validMovesCache[key] {
            return cached
        }
        
        // Satır kontrolü
        for c in 0..<9 {
            if grid[row][c] == number && c != col {
                validMovesCache[key] = false
                return false
            }
        }
        
        // Sütun kontrolü
        for r in 0..<9 {
            if grid[r][col] == number && r != row {
                validMovesCache[key] = false
                return false
            }
        }
        
        // Blok kontrolü
        let blockRow = (row / 3) * 3
        let blockCol = (col / 3) * 3
        
        for r in blockRow..<blockRow+3 {
            for c in blockCol..<blockCol+3 {
                if grid[r][c] == number && (r != row || c != col) {
                    validMovesCache[key] = false
                    return false
                }
            }
        }
        
        // Geçerli hamle
        validMovesCache[key] = true
        return true
    }
    
    func getHint() -> (row: Int, col: Int, value: Int)? {
        // Boş hücreleri bul
        var emptyCells = [(row: Int, col: Int)]()
        
        for row in 0..<9 {
            for col in 0..<9 {
                if grid[row][col] == nil && isCellEditable(at: row, col: col) {
                    emptyCells.append((row: row, col: col))
                }
            }
        }
        
        // Boş hücre yoksa ipucu verilemez
        if emptyCells.isEmpty {
            return nil
        }
        
        // Rastgele bir boş hücre seç
        if let randomCell = emptyCells.randomElement() {
            let row = randomCell.row
            let col = randomCell.col
            let value = solution[row][col]
            
            return (row: row, col: col, value: value)
        }
        
        return nil
    }
    
    private func generateSolution() {
        // Boş ızgara oluştur
        solution = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        
        // Çözümü oluştur
        _ = solveSudoku()
    }
    
    private func solveSudoku() -> Bool {
        for row in 0..<9 {
            for col in 0..<9 {
                if solution[row][col] == 0 {
                    // Rastgele sayı sırası oluştur
                    var numbers = Array(1...9)
                    numbers.shuffle()
                    
                    for num in numbers {
                        if isSafe(row: row, col: col, num: num) {
                            solution[row][col] = num
                            
                            if solveSudoku() {
                                return true
                            }
                            
                            solution[row][col] = 0
                        }
                    }
                    
                    return false
                }
            }
        }
        
        return true
    }
    
    private func isSafe(row: Int, col: Int, num: Int) -> Bool {
        // Satır kontrolü
        for c in 0..<9 {
            if solution[row][c] == num {
                return false
            }
        }
        
        // Sütun kontrolü
        for r in 0..<9 {
            if solution[r][col] == num {
                return false
            }
        }
        
        // Blok kontrolü
        let blockRow = (row / 3) * 3
        let blockCol = (col / 3) * 3
        
        for r in blockRow..<blockRow+3 {
            for c in blockCol..<blockCol+3 {
                if solution[r][c] == num {
                    return false
                }
            }
        }
        
        return true
    }
    
    func checkGameCompletion() {
        // Tüm hücreler dolu mu kontrol et
        for row in 0..<9 {
            for col in 0..<9 {
                if grid[row][col] == nil {
                    isGameComplete = false
                    return
                }
            }
        }
        
        // Tüm satırlar, sütunlar ve bloklar geçerli mi kontrol et
        for i in 0..<9 {
            if !isValidRow(i) || !isValidColumn(i) || !isValidBlock(i / 3, i % 3) {
                isGameComplete = false
                return
            }
        }
        
        // Oyun tamamlandı
        isGameComplete = true
        timer?.invalidate()
    }
    
    private func isValidRow(_ row: Int) -> Bool {
        var seen = Set<Int>()
        for col in 0..<9 {
            if let num = grid[row][col] {
                if seen.contains(num) {
                    return false
                }
                seen.insert(num)
            }
        }
        return seen.count == 9
    }
    
    private func isValidColumn(_ col: Int) -> Bool {
        var seen = Set<Int>()
        for row in 0..<9 {
            if let num = grid[row][col] {
                if seen.contains(num) {
                    return false
                }
                seen.insert(num)
            }
        }
        return seen.count == 9
    }
    
    private func isValidBlock(_ blockRow: Int, _ blockCol: Int) -> Bool {
        var seen = Set<Int>()
        for row in blockRow * 3..<blockRow * 3 + 3 {
            for col in blockCol * 3..<blockCol * 3 + 3 {
                if let num = grid[row][col] {
                    if seen.contains(num) {
                        return false
                    }
                    seen.insert(num)
                }
            }
        }
        return seen.count == 9
    }
} 