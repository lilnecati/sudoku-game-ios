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
        )
        .cornerRadius(8)
        .padding(5)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isDarkMode ? Color.white.opacity(0.5) : Color.black.opacity(0.5), lineWidth: 3) // Dış çerçeveyi daha belirgin yap
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
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { number in
                    numberButton(for: number)
                }
            }
            
            HStack(spacing: 8) {
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
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isDarkMode ? Color.red.opacity(0.2) : Color.red.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                }
            }
        }
        .padding(.vertical, 5)
    }
    
    private func numberButton(for number: Int) -> some View {
        let isSelected = selectedNumber == number
        
        return Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
                selectedNumber = isSelected ? nil : number
                
                if let cell = sudokuModel.selectedCell, sudokuModel.isCellEditable(at: cell.row, col: cell.col) {
                    if noteMode {
                        // Not modunda
                        if notes[cell.row][cell.col].contains(number) {
                            notes[cell.row][cell.col].removeAll { $0 == number }
                        } else {
                            notes[cell.row][cell.col].append(number)
                            notes[cell.row][cell.col].sort()
                        }
                        
                        // Hafif haptic feedback
                        #if os(iOS)
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred(intensity: 0.3)
                        #endif
                    } else {
                        // Normal modda
                        withAnimation(.easeInOut(duration: 0.1)) {
                            let success = sudokuModel.isValidMove(number: number, at: cell.row, col: cell.col)
                            
                            if success {
                                sudokuModel.grid[cell.row][cell.col] = number
                                
                                // Notları temizle
                                notes[cell.row][cell.col] = []
                                
                                // Oyun tamamlandı mı kontrol et
                                sudokuModel.checkGameCompletion()
                            } else {
                                sudokuModel.shake()
                                sudokuModel.mistakes += 1
                            }
                            
                            // Haptic feedback - sadece iOS cihazlarda
                            #if os(iOS)
                            let generator = UIImpactFeedbackGenerator(style: success ? .medium : .heavy)
                            generator.impactOccurred(intensity: success ? 0.7 : 1.0)
                            #endif
                        }
                    }
                }
            }
        }) {
            Text("\(number)")
                .font(.system(size: numberButtonFontSize, weight: isSelected ? .bold : .regular))
                .foregroundColor(isSelected ? .white : (isDarkMode ? .white : .black))
                .frame(width: buttonSize, height: buttonSize)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? themeColor : (isDarkMode ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1)))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(themeColor.opacity(isSelected ? 1.0 : 0.3), lineWidth: 1)
                )
                .shadow(color: isSelected ? themeColor.opacity(0.3) : Color.clear, radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
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
        
        // Yeni zamanlayıcı oluştur - 1 saniye aralıklarla
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.sudokuModel.gameTime += 1
        }
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
                            isDarkMode: isDarkMode,
                            selectedNumber: $selectedNumber
                        )
                        .id("\(actualRow)-\(actualCol)") // Sabit ID ile gereksiz yeniden render önlenir
                    }
                }
            }
        }
        .background(blockBackground)
        .cornerRadius(4)
        .padding(1) // Bloklar arası boşluğu artır
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(isDarkMode ? Color.white.opacity(0.4) : Color.black.opacity(0.4), lineWidth: 2) // Çizgi kalınlığını ve rengini değiştir
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
                .stroke(
                    isSelected ? themeColor : (isDarkMode ? Color.white.opacity(0.2) : Color.black.opacity(0.2)), 
                    lineWidth: isSelected ? 2 : 0.5 // Seçili değilse de ince bir çizgi ekle
                )
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
    let gameTime: TimeInterval
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
    
    private var isDarkMode: Bool {
        colorScheme == .dark
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