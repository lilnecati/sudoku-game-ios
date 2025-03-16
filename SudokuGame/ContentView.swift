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
    
    // Ekran boyutuna göre buton boyutunu ayarla
    private var numberButtonSize: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        if screenWidth >= 428 { // iPhone Pro Max modeller
            return min(60, (screenWidth - 40) / 9)
        } else if screenWidth >= 390 { // iPhone Pro modeller
            return min(55, (screenWidth - 30) / 9)
        } else { // iPhone mini ve standart modeller
            return min(50, (screenWidth - 20) / 9)
        }
    }
    
    // Ekran boyutuna göre padding değerlerini ayarla
    private var horizontalPadding: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        if screenWidth >= 428 { // iPhone Pro Max modeller
            return 20
        } else if screenWidth >= 390 { // iPhone Pro modeller
            return 15
        } else { // iPhone mini ve standart modeller
            return 10
        }
    }
    
    private var buttonFontSize: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        if screenWidth >= 428 { // iPhone Pro Max modeller
            return 17
        } else if screenWidth >= 390 { // iPhone Pro modeller
            return 15
        } else { // iPhone mini ve standart modeller
            return 13
        }
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
                // Arka plan
                LinearGradient(
                    gradient: Gradient(colors: [
                        isDarkMode ? Color.black : Color.white,
                        isDarkMode ? themeColor.opacity(0.15) : themeColor.opacity(0.08)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
                
                if isLoading {
                    LoadingView(themeColor: themeColor, isDarkMode: isDarkMode)
                } else {
                    VStack(spacing: 10) {
                        // Üst bilgi çubuğu
                        HStack {
                            Button(action: {
                                // Ana menüye dön
                                stopTimer()
                                showingWelcomeScreen = true
                            }) {
                                Image(systemName: "house.fill")
                                    .font(.system(size: UIScreen.main.bounds.width >= 390 ? 22 : 18))
                                    .foregroundColor(isDarkMode ? .white : .black)
                                    .padding(UIScreen.main.bounds.width >= 390 ? 10 : 8)
                                    .background(
                                        Circle()
                                            .fill(isDarkMode ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1))
                                    )
                            }
                            .padding(.leading, horizontalPadding)
                            
                            Spacer()
                            
                            Text("Sudoku")
                                .font(.system(size: UIScreen.main.bounds.width < 400 ? 24 : 28, weight: .bold, design: .rounded))
                                .foregroundColor(isDarkMode ? .white : themeColor)
                            
                            Spacer()
                            
                            Button(action: {
                                showingSettings.toggle()
                            }) {
                                Image(systemName: "gear")
                                    .font(.system(size: UIScreen.main.bounds.width >= 390 ? 22 : 18))
                                    .foregroundColor(isDarkMode ? .white : .black)
                                    .padding(UIScreen.main.bounds.width >= 390 ? 10 : 8)
                                    .background(
                                        Circle()
                                            .fill(isDarkMode ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1))
                                    )
                            }
                            .padding(.trailing, horizontalPadding)
                        }
                        
                        // Oyun bilgileri
                        HStack(spacing: UIScreen.main.bounds.width >= 390 ? 15 : 8) {
                            // Zorluk seviyesi
                            Button(action: {
                                showingDifficultyPicker = true
                            }) {
                                HStack {
                                    Image(systemName: "slider.horizontal.3")
                                        .foregroundColor(themeColor)
                                    Text(sudokuModel.difficulty.rawValue)
                                        .foregroundColor(isDarkMode ? .white : .black)
                                        .font(.system(size: buttonFontSize))
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, UIScreen.main.bounds.width >= 390 ? 12 : 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(themeColor.opacity(0.1))
                                        .shadow(color: themeColor.opacity(0.2), radius: 2, x: 0, y: 1)
                                )
                            }
                            
                            // Hatalar
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(.red)
                                Text("\(sudokuModel.mistakes)")
                                    .foregroundColor(isDarkMode ? .white : .black)
                                    .font(.system(size: buttonFontSize))
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, UIScreen.main.bounds.width >= 390 ? 12 : 8)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.red.opacity(0.1))
                                    .shadow(color: Color.red.opacity(0.2), radius: 2, x: 0, y: 1)
                            )
                            
                            // Süre
                            Button(action: {
                                showingStats = true
                            }) {
                                HStack {
                                    Image(systemName: "clock")
                                        .foregroundColor(themeColor)
                                    Text(formatTime(sudokuModel.gameTime))
                                        .foregroundColor(isDarkMode ? .white : .black)
                                        .font(.system(size: buttonFontSize))
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, UIScreen.main.bounds.width >= 390 ? 12 : 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(themeColor.opacity(0.1))
                                        .shadow(color: themeColor.opacity(0.2), radius: 2, x: 0, y: 1)
                                )
                            }
                        }
                        .padding(.horizontal, horizontalPadding)
                        
                        // Aksiyon butonları
                        HStack(spacing: UIScreen.main.bounds.width >= 390 ? 15 : 8) {
                            // Yeni oyun butonu
                            Button(action: {
                                withAnimation {
                                    startNewGame()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Yeni Oyun")
                                        .font(.system(size: buttonFontSize))
                                }
                                .foregroundColor(.white)
                                .padding(.vertical, 8)
                                .padding(.horizontal, UIScreen.main.bounds.width >= 390 ? 12 : 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(themeColor)
                                        .shadow(color: themeColor.opacity(0.4), radius: 2, x: 0, y: 2)
                                )
                            }
                            
                            // Geri alma butonu
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    // Geri alma işlemini arka planda yap
                                    DispatchQueue.global(qos: .userInitiated).async {
                                        DispatchQueue.main.async {
                                            sudokuModel.undoLastMove()
                                        }
                                    }
                                }
                            }) {
                                HStack {
                                    Image(systemName: "arrow.uturn.backward")
                                    Text("Geri Al")
                                        .font(.system(size: buttonFontSize))
                                }
                                .foregroundColor(.white)
                                .padding(.vertical, 8)
                                .padding(.horizontal, UIScreen.main.bounds.width >= 390 ? 12 : 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(sudokuModel.canUndo ? themeColor : Color.gray)
                                        .shadow(color: sudokuModel.canUndo ? themeColor.opacity(0.4) : Color.gray.opacity(0.4), radius: 2, x: 0, y: 2)
                                )
                            }
                            .disabled(!sudokuModel.canUndo)
                            
                            // İpucu butonu
                            Button(action: {
                                showHint()
                            }) {
                                HStack {
                                    Image(systemName: "lightbulb.fill")
                                    Text("İpucu")
                                        .font(.system(size: buttonFontSize))
                                }
                                .foregroundColor(.white)
                                .padding(.vertical, 8)
                                .padding(.horizontal, UIScreen.main.bounds.width >= 390 ? 12 : 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(themeSecondaryColor)
                                        .shadow(color: themeSecondaryColor.opacity(0.4), radius: 2, x: 0, y: 2)
                                )
                            }
                        }
                        .padding(.horizontal, horizontalPadding)
                        
                        HStack(spacing: 15) {
                            // Not modu butonu
                            Button(action: {
                                noteMode.toggle()
                            }) {
                                HStack {
                                    Image(systemName: noteMode ? "pencil.circle.fill" : "pencil.circle")
                                    Text("Not Modu")
                                        .font(.system(size: buttonFontSize))
                                }
                                .foregroundColor(noteMode ? .white : (isDarkMode ? .white : .black))
                                .padding(.vertical, 8)
                                .padding(.horizontal, UIScreen.main.bounds.width >= 390 ? 12 : 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(noteMode ? themeColor : (isDarkMode ? Color.gray.opacity(0.3) : Color.gray.opacity(0.1)))
                                        .shadow(color: noteMode ? themeColor.opacity(0.4) : Color.gray.opacity(0.2), radius: 2, x: 0, y: 2)
                                )
                            }
                        }
                        .padding(.horizontal, horizontalPadding)
                        
                        Spacer()
                        
                        // Sudoku ızgarası
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
                                    }
                                }
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isDarkMode ? Color.black.opacity(0.3) : Color.white)
                                .shadow(color: isDarkMode ? Color.black.opacity(0.5) : Color.gray.opacity(0.3), radius: 10, x: 0, y: 5)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(themeColor, lineWidth: 3)
                        )
                        .padding(.horizontal, UIScreen.main.bounds.width >= 390 ? 5 : 2)
                        .scaleEffect(sudokuModel.shakeGrid ? 0.95 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: sudokuModel.shakeGrid)
                        .frame(
                            maxWidth: min(UIScreen.main.bounds.width - 8, UIScreen.main.bounds.height * 0.8),
                            maxHeight: min(UIScreen.main.bounds.width - 8, UIScreen.main.bounds.height * 0.8)
                        )
                        .aspectRatio(1, contentMode: .fit)
                        
                        Spacer()
                        
                        // Rakam seçici
                        HStack(spacing: 2) {
                            ForEach(1...9, id: \.self) { number in
                                Button(action: {
                                    if let selected = sudokuModel.selectedCell {
                                        if noteMode {
                                            // Not modu aktifse, notu ekle veya çıkar
                                            toggleNote(number: number, at: selected)
                                        } else if sudokuModel.grid[selected.row][selected.col] == nil {
                                            // Normal mod, sayıyı yerleştir
                                            withAnimation {
                                                // Sayı yerleştirme işlemini arka planda yap
                                                DispatchQueue.global(qos: .userInitiated).async {
                                                    DispatchQueue.main.async {
                                                        sudokuModel.placeNumber(number)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    selectedNumber = number
                                }) {
                                    Text("\(number)")
                                        .font(.system(size: UIScreen.main.bounds.width >= 390 ? 28 : 24, weight: .bold))
                                        .frame(width: numberButtonSize, height: numberButtonSize)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(selectedNumber == number ? themeColor : themeColor.opacity(0.1))
                                        )
                                        .foregroundColor(selectedNumber == number ? .white : (isDarkMode ? .white : .black))
                                        .shadow(color: themeColor.opacity(0.3), radius: 2, x: 0, y: 1)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, horizontalPadding)
                        .padding(.vertical, 10)
                        
                        // Silme butonu
                        Button(action: {
                            if let selected = sudokuModel.selectedCell {
                                if noteMode {
                                    // Not modunda tüm notları temizle
                                    notes[selected.row][selected.col] = []
                                } else if sudokuModel.grid[selected.row][selected.col] != nil {
                                    // Normal modda hücreyi temizle
                                    withAnimation {
                                        // Silme işlemini arka planda yap
                                        DispatchQueue.global(qos: .userInitiated).async {
                                            DispatchQueue.main.async {
                                                sudokuModel.clearCell(at: selected.row, col: selected.col)
                                            }
                                        }
                                    }
                                }
                            }
                        }) {
                            HStack {
                                Image(systemName: "delete.left")
                                Text("Sil")
                                    .font(.system(size: UIScreen.main.bounds.width >= 390 ? 16 : 14))
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, UIScreen.main.bounds.width >= 390 ? 20 : 15)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.red.opacity(0.8))
                            )
                            .foregroundColor(.white)
                            .shadow(color: Color.red.opacity(0.3), radius: 2, x: 0, y: 1)
                        }
                        .padding(.bottom, UIScreen.main.bounds.width >= 390 ? 15 : 10)
                    }
                }
            }
            .sheet(isPresented: $showingHowToPlay) {
                HowToPlayView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(isDarkMode: $isDarkMode, selectedTheme: $selectedTheme)
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
            .alert(isPresented: $sudokuModel.isGameComplete) {
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
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
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
    
    var body: some View {
        VStack(spacing: 3) {
            ForEach(0..<3) { row in
                HStack(spacing: 3) {
                    ForEach(0..<3) { col in
                        let actualRow = blockRow * 3 + row
                        let actualCol = blockCol * 3 + col
                        
                        SudokuCellView(
                            row: actualRow,
                            col: actualCol,
                            sudokuModel: sudokuModel,
                            notes: notes[actualRow][actualCol],
                            themeColor: themeColor,
                            isDarkMode: isDarkMode
                        )
                    }
                }
            }
        }
        .background(isDarkMode ? Color.gray.opacity(0.4) : Color.gray.opacity(0.3))
        .cornerRadius(4)
        .padding(3)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(isDarkMode ? Color.gray.opacity(0.8) : Color.gray.opacity(0.7), lineWidth: 5)
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
    
    // Ekran boyutuna göre hücre boyutunu ayarla
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    private var cellSize: CGFloat {
        // Ekran boyutuna göre hücre boyutunu ayarla
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
    
    private var isEditable: Bool {
        sudokuModel.isCellEditable(at: row, col: col)
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return themeColor.opacity(0.3)
        } else if isInSameRowOrCol {
            return themeColor.opacity(0.1)
        } else if isInSameBlock {
            return themeColor.opacity(0.05)
        } else {
            return isDarkMode ? Color.black.opacity(0.2) : Color.white
        }
    }
    
    private var textColor: Color {
        if !isEditable {
            // Başlangıç hücreleri için farklı renk
            return isDarkMode ? themeColor : themeColor.opacity(0.8)
        } else {
            return isDarkMode ? .white : .black
        }
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                sudokuModel.selectedCell = (row: row, col: col)
            }
        }) {
            ZStack {
                Rectangle()
                    .fill(backgroundColor)
                    .frame(width: cellSize, height: cellSize)
                
                if let value = value {
                    // Ana sayı
                    Text("\(value)")
                        .font(.system(size: fontSize, weight: isEditable ? .regular : .bold))
                        .foregroundColor(textColor)
                } else if !notes.isEmpty {
                    // Notlar
                    VStack(spacing: 1) {
                        ForEach(0..<3) { row in
                            HStack(spacing: 1) {
                                ForEach(1...3, id: \.self) { col in
                                    let num = row * 3 + col
                                    if notes.contains(num) {
                                        Text("\(num)")
                                            .font(.system(size: notesFontSize))
                                            .foregroundColor(isDarkMode ? .white.opacity(0.7) : .black.opacity(0.7))
                                            .frame(width: notesItemSize, height: notesItemSize)
                                    } else {
                                        Text("")
                                            .frame(width: notesItemSize, height: notesItemSize)
                                    }
                                }
                            }
                        }
                    }
                    .frame(width: cellSize * 0.9, height: cellSize * 0.9)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .overlay(
            RoundedRectangle(cornerRadius: 2)
                .stroke(isSelected ? themeColor : Color.gray.opacity(0.3), lineWidth: isSelected ? 3 : 1)
        )
        .scaleEffect(isSelected ? 1.05 : 1.0)
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
    @Binding var isDarkMode: Bool
    @Binding var selectedTheme: ThemeColor
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Görünüm")) {
                    HStack {
                        Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                            .foregroundColor(isDarkMode ? .yellow : .orange)
                        
                        Toggle("Karanlık Mod", isOn: $isDarkMode)
                            .toggleStyle(SwitchToggleStyle(tint: selectedTheme.mainColor))
                    }
                    
                    Picker("Tema Rengi", selection: $selectedTheme) {
                        ForEach(ThemeColor.allCases) { theme in
                            HStack {
                                Circle()
                                    .fill(theme.mainColor)
                                    .frame(width: 20, height: 20)
                                Text(theme.rawValue)
                            }
                            .tag(theme)
                        }
                    }
                }
                
                Section(header: Text("Hakkında")) {
                    Text("Sudoku Oyunu v1.0")
                    Text("© 2025 Tüm hakları saklıdır")
                    Text("Necati Yıldırım")
                }
            }
            .navigationTitle("Ayarlar")
            .navigationBarItems(trailing: Button("Kapat") {
                presentationMode.wrappedValue.dismiss()
            })
        }
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