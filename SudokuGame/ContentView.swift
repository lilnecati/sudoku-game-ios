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
    
    var themeColor: Color {
        selectedTheme.mainColor
    }
    
    var themeSecondaryColor: Color {
        selectedTheme.secondaryColor
    }
    
    var body: some View {
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
            
            VStack(spacing: 10) {
                // Üst bilgi çubuğu
                HStack {
                    Button(action: {
                        // Ana menüye dön
                    }) {
                        Image(systemName: "house.fill")
                            .font(.title)
                            .foregroundColor(isDarkMode ? .white : .black)
                            .padding(10)
                            .background(
                                Circle()
                                    .fill(isDarkMode ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1))
                            )
                    }
                    .padding(.leading)
                    
                    Spacer()
                    
                    Text("Sudoku")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(isDarkMode ? .white : themeColor)
                    
                    Spacer()
                    
                    Button(action: {
                        showingSettings.toggle()
                    }) {
                        Image(systemName: "gear")
                            .font(.title)
                            .foregroundColor(isDarkMode ? .white : .black)
                            .padding(10)
                            .background(
                                Circle()
                                    .fill(isDarkMode ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1))
                            )
                    }
                    .padding(.trailing)
                }
                
                // Oyun bilgileri
                HStack(spacing: 15) {
                    // Zorluk seviyesi
                    Button(action: {
                        showingDifficultyPicker = true
                    }) {
                        HStack {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundColor(themeColor)
                            Text(sudokuModel.difficulty.rawValue)
                                .foregroundColor(isDarkMode ? .white : .black)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
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
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
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
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(themeColor.opacity(0.1))
                                .shadow(color: themeColor.opacity(0.2), radius: 2, x: 0, y: 1)
                        )
                    }
                }
                .padding(.horizontal)
                
                // Aksiyon butonları
                HStack(spacing: 15) {
                    // Yeni oyun butonu
                    Button(action: {
                        withAnimation {
                            sudokuModel.generateNewGame()
                            resetTimer()
                            notes = Array(repeating: Array(repeating: [], count: 9), count: 9)
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Yeni Oyun")
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(themeColor)
                                .shadow(color: themeColor.opacity(0.4), radius: 2, x: 0, y: 2)
                        )
                    }
                    
                    // Geri alma butonu
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            sudokuModel.undoLastMove()
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.uturn.backward")
                            Text("Geri Al")
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
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
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(themeSecondaryColor)
                                .shadow(color: themeSecondaryColor.opacity(0.4), radius: 2, x: 0, y: 2)
                        )
                    }
                }
                .padding(.horizontal)
                
                HStack(spacing: 15) {
                    // Not modu butonu
                    Button(action: {
                        noteMode.toggle()
                    }) {
                        HStack {
                            Image(systemName: noteMode ? "pencil.circle.fill" : "pencil.circle")
                            Text("Not Modu")
                        }
                        .foregroundColor(noteMode ? .white : (isDarkMode ? .white : .black))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(noteMode ? themeColor : (isDarkMode ? Color.gray.opacity(0.3) : Color.gray.opacity(0.1)))
                                .shadow(color: noteMode ? themeColor.opacity(0.4) : Color.gray.opacity(0.2), radius: 2, x: 0, y: 2)
                        )
                    }
                }
                .padding(.horizontal)
                
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
                        .stroke(themeColor, lineWidth: 2)
                )
                .padding()
                .scaleEffect(sudokuModel.shakeGrid ? 0.95 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: sudokuModel.shakeGrid)
                
                Spacer()
                
                // Rakam seçici
                HStack {
                    ForEach(1...9, id: \.self) { number in
                        Button(action: {
                            if let selected = sudokuModel.selectedCell {
                                if noteMode {
                                    // Not modu aktifse, notu ekle veya çıkar
                                    toggleNote(number: number, at: selected)
                                } else if sudokuModel.grid[selected.row][selected.col] == nil {
                                    // Normal mod, sayıyı yerleştir
                                    withAnimation {
                                        sudokuModel.placeNumber(number)
                                    }
                                }
                            }
                            selectedNumber = number
                        }) {
                            Text("\(number)")
                                .font(.title)
                                .frame(width: 35, height: 35)
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
                .padding()
                
                // Silme butonu
                Button(action: {
                    if let selected = sudokuModel.selectedCell {
                        if noteMode {
                            // Not modunda tüm notları temizle
                            notes[selected.row][selected.col] = []
                        } else if sudokuModel.grid[selected.row][selected.col] != nil {
                            // Normal modda hücreyi temizle
                            withAnimation {
                                sudokuModel.clearCell(at: selected.row, selected.col)
                            }
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "delete.left")
                        Text("Sil")
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red.opacity(0.8))
                    )
                    .foregroundColor(.white)
                    .shadow(color: Color.red.opacity(0.3), radius: 2, x: 0, y: 1)
                }
                .padding(.bottom)
                
                // Alt bilgi çubuğu
                HStack {
                    Button(action: {
                        showingHowToPlay.toggle()
                    }) {
                        HStack {
                            Image(systemName: "questionmark.circle")
                            Text("Nasıl Oynanır?")
                        }
                        .foregroundColor(themeColor)
                    }
                    
                    Spacer()
                    
                    Toggle(isOn: $isDarkMode) {
                        HStack {
                            Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                            Text(isDarkMode ? "Karanlık Mod" : "Aydınlık Mod")
                        }
                        .foregroundColor(isDarkMode ? .white : .black)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: themeColor))
                }
                .padding()
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
        // Performans iyileştirmesi için ipucu sistemini optimize edelim
        var hints = [(row: Int, col: Int, num: Int)]()
        
        // Önce boş hücreleri bul
        for row in 0..<9 {
            for col in 0..<9 {
                if sudokuModel.grid[row][col] == nil {
                    // Her boş hücre için geçerli sayıları kontrol et
                    for num in 1...9 {
                        if sudokuModel.isValid(num, at: row, col: col) {
                            hints.append((row: row, col: col, num: num))
                        }
                    }
                }
            }
        }
        
        // Eğer ipucu bulunamazsa
        if hints.isEmpty {
            return "Şu anda bir ipucu bulunamadı."
        }
        
        // Rastgele bir ipucu seç
        let randomHint = hints.randomElement()!
        return "Satır \(randomHint.row+1), Sütun \(randomHint.col+1)'e \(randomHint.num) sayısını yerleştirebilirsiniz."
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
        VStack(spacing: 1) {
            ForEach(0..<3) { row in
                HStack(spacing: 1) {
                    ForEach(0..<3) { col in
                        let actualRow = blockRow * 3 + row
                        let actualCol = blockCol * 3 + col
                        
                        SudokuCell(
                            value: sudokuModel.grid[actualRow][actualCol],
                            notes: notes[actualRow][actualCol],
                            isSelected: sudokuModel.selectedCell?.row == actualRow && sudokuModel.selectedCell?.col == actualCol,
                            isInSameRowOrCol: sudokuModel.selectedCell != nil && (sudokuModel.selectedCell!.row == actualRow || sudokuModel.selectedCell!.col == actualCol),
                            isInSameBlock: sudokuModel.selectedCell != nil && (sudokuModel.selectedCell!.row / 3 == actualRow / 3 && sudokuModel.selectedCell!.col / 3 == actualCol / 3),
                            themeColor: themeColor,
                            isDarkMode: isDarkMode,
                            onTap: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    sudokuModel.selectedCell = (row: actualRow, col: actualCol)
                                }
                            }
                        )
                    }
                }
            }
        }
        .background(isDarkMode ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1))
        .cornerRadius(4)
        .padding(2)
    }
}

struct SudokuCell: View {
    let value: Int?
    let notes: [Int]
    let isSelected: Bool
    let isInSameRowOrCol: Bool
    let isInSameBlock: Bool
    let themeColor: Color
    let isDarkMode: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                Rectangle()
                    .fill(backgroundColor)
                    .frame(width: 35, height: 35)
                
                if let value = value {
                    // Ana sayı
                    Text("\(value)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(isDarkMode ? .white : .black)
                } else if !notes.isEmpty {
                    // Notlar
                    VStack(spacing: 1) {
                        ForEach(0..<3) { row in
                            HStack(spacing: 1) {
                                ForEach(1...3, id: \.self) { col in
                                    let num = row * 3 + col
                                    if notes.contains(num) {
                                        Text("\(num)")
                                            .font(.system(size: 8))
                                            .foregroundColor(isDarkMode ? .white.opacity(0.7) : .black.opacity(0.7))
                                            .frame(width: 10, height: 10)
                                    } else {
                                        Text("")
                                            .frame(width: 10, height: 10)
                                    }
                                }
                            }
                        }
                    }
                    .frame(width: 30, height: 30)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .overlay(
            RoundedRectangle(cornerRadius: 2)
                .stroke(isSelected ? themeColor : Color.clear, lineWidth: isSelected ? 2 : 0)
        )
        .scaleEffect(isSelected ? 1.05 : 1.0)
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
                    Toggle("Karanlık Mod", isOn: $isDarkMode)
                    
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 