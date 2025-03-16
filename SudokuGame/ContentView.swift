//
//  ContentView.swift
//  SudokuGame
//
//  Created by Necati Yıldırım on 16.03.2025.
//

import SwiftUI

// Konfeti efekti için yardımcı yapı
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

// Rozet yapısı
struct Badge: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let icon: String
    let color: Color
    var isEarned: Bool = false
}

struct ContentView: View {
    @StateObject private var sudokuModel = SudokuModel()
    @State private var showingDifficultyPicker = false
    @State private var showingStats = false
    @State private var showingHowToPlay = false
    @State private var timer: Timer?
    @State private var animateNewGame = false
    @State private var presentedSheet: SheetType? = nil
    @State private var dragOffset: CGFloat = 0
    @State private var showConfetti = false
    @State private var showBadgeEarned = false
    @State private var earnedBadge: Badge? = nil
    @State private var badges: [Badge] = [
        Badge(name: "Hızlı Çözücü", description: "Sudoku'yu 5 dakikadan kısa sürede çöz", icon: "bolt.fill", color: .yellow),
        Badge(name: "Hatasız", description: "Hiç hata yapmadan bir Sudoku çöz", icon: "checkmark.seal.fill", color: .green),
        Badge(name: "Zor Seviye", description: "Zor seviyede bir Sudoku çöz", icon: "star.fill", color: .orange),
        Badge(name: "Sudoku Ustası", description: "10 Sudoku çöz", icon: "crown.fill", color: .purple)
    ]
    @State private var selectedTheme: ColorTheme = .blue
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.presentationMode) var presentationMode
    
    enum SheetType: Identifiable {
        case difficulty, stats, howToPlay, badges, themes
        
        var id: Int {
            switch self {
            case .difficulty: return 0
            case .stats: return 1
            case .howToPlay: return 2
            case .badges: return 3
            case .themes: return 4
            }
        }
    }
    
    enum ColorTheme: String, CaseIterable, Identifiable {
        case blue = "Mavi"
        case purple = "Mor"
        case green = "Yeşil"
        case orange = "Turuncu"
        case pink = "Pembe"
        
        var id: String { self.rawValue }
        
        var mainColor: Color {
            switch self {
            case .blue: return .blue
            case .purple: return .purple
            case .green: return .green
            case .orange: return .orange
            case .pink: return .pink
            }
        }
        
        var secondaryColor: Color {
            switch self {
            case .blue: return .cyan
            case .purple: return Color(red: 0.5, green: 0.2, blue: 0.8)
            case .green: return .mint
            case .orange: return .yellow
            case .pink: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .blue: return "drop.fill"
            case .purple: return "sparkles"
            case .green: return "leaf.fill"
            case .orange: return "sun.max.fill"
            case .pink: return "heart.fill"
            }
        }
    }
    
    let gridSpacing: CGFloat = 1
    let boldSpacing: CGFloat = 2
    
    var body: some View {
        NavigationView {
            ZStack {
                // Arka plan rengi - koyu/beyaz moda göre değişir
                (colorScheme == .dark ? 
                    LinearGradient(gradient: Gradient(colors: [Color.black, themeColor.opacity(0.2)]), startPoint: .top, endPoint: .bottom) :
                    LinearGradient(gradient: Gradient(colors: [Color.white, themeColor.opacity(0.1)]), startPoint: .top, endPoint: .bottom))
                    .ignoresSafeArea()
                
                VStack(spacing: 10) {
                    // Üst bilgi alanı
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                    .shadow(color: .red.opacity(0.3), radius: 2, x: 0, y: 1)
                                Text("Hata: \(sudokuModel.mistakes)")
                                    .foregroundColor(.red)
                                    .fontWeight(.semibold)
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(colorScheme == .dark ? Color.red.opacity(0.1) : Color.red.opacity(0.05))
                                    .shadow(color: Color.red.opacity(0.1), radius: 2, x: 0, y: 1)
                            )
                            
                            HStack {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(colorScheme == .dark ? themeSecondaryColor : themeColor)
                                    .shadow(color: colorScheme == .dark ? themeSecondaryColor.opacity(0.3) : themeColor.opacity(0.3), radius: 2, x: 0, y: 1)
                                Text("Süre: \(formatTime(sudokuModel.gameTime))")
                                    .foregroundColor(colorScheme == .dark ? themeSecondaryColor : themeColor)
                                    .fontWeight(.semibold)
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(colorScheme == .dark ? themeColor.opacity(0.1) : themeColor.opacity(0.05))
                                    .shadow(color: colorScheme == .dark ? themeSecondaryColor.opacity(0.1) : themeColor.opacity(0.1), radius: 2, x: 0, y: 1)
                            )
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            Button(action: {
                                withAnimation {
                                    animateNewGame = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                                        animateNewGame = false
                                    }
                                }
                                sudokuModel.generateNewGame()
                                sudokuModel.gameTime = 0
                                sudokuModel.mistakes = 0
                                startTimer()
                            }) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 18))
                                    .foregroundColor(themeColor)
                                    .frame(width: 36, height: 36)
                                    .background(
                                        Circle()
                                            .fill(themeColor.opacity(0.2))
                                            .shadow(color: themeColor.opacity(0.3), radius: 2, x: 0, y: 1)
                                    )
                            }
                            
                            Button(action: {
                                presentedSheet = .difficulty
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "slider.horizontal.3")
                                        .font(.system(size: 12))
                                    Text(sudokuModel.difficulty.rawValue)
                                        .font(.system(size: 14))
                                }
                                .padding(.vertical, 6)
                                .padding(.horizontal, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(colorScheme == .dark ? themeColor.opacity(0.3) : themeColor.opacity(0.2))
                                        .shadow(color: colorScheme == .dark ? themeColor.opacity(0.3) : themeColor.opacity(0.2), radius: 3, x: 0, y: 2)
                                )
                            }
                            
                            Button(action: {
                                presentedSheet = .stats
                            }) {
                                Image(systemName: "chart.bar.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(themeColor)
                                    .frame(width: 36, height: 36)
                                    .background(
                                        Circle()
                                            .fill(themeColor.opacity(0.2))
                                            .shadow(color: themeColor.opacity(0.3), radius: 2, x: 0, y: 1)
                                    )
                            }
                            
                            Button(action: {
                                presentedSheet = .howToPlay
                            }) {
                                Image(systemName: "questionmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(themeColor)
                                    .frame(width: 36, height: 36)
                                    .background(
                                        Circle()
                                            .fill(themeColor.opacity(0.2))
                                            .shadow(color: themeColor.opacity(0.3), radius: 2, x: 0, y: 1)
                                    )
                            }
                            
                            Button(action: {
                                presentedSheet = .themes
                            }) {
                                Image(systemName: selectedTheme.icon)
                                    .font(.system(size: 18))
                                    .foregroundColor(themeColor)
                                    .frame(width: 36, height: 36)
                                    .background(
                                        Circle()
                                            .fill(themeColor.opacity(0.2))
                                            .shadow(color: themeColor.opacity(0.3), radius: 2, x: 0, y: 1)
                                    )
                            }
                            
                            Button(action: {
                                presentedSheet = .badges
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "medal.fill")
                                        .font(.system(size: 14))
                                    Text("\(badges.filter { $0.isEarned }.count)")
                                        .font(.system(size: 14))
                                }
                                .padding(.vertical, 6)
                                .padding(.horizontal, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(colorScheme == .dark ? Color.orange.opacity(0.3) : Color.orange.opacity(0.2))
                                        .shadow(color: colorScheme == .dark ? Color.orange.opacity(0.3) : Color.orange.opacity(0.2), radius: 3, x: 0, y: 2)
                                )
                                .foregroundColor(colorScheme == .dark ? .orange : .orange)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Sudoku grid
                    SudokuGridView(sudokuModel: sudokuModel, colorScheme: colorScheme, themeColor: themeColor, themeSecondaryColor: themeSecondaryColor)
                        .padding(.horizontal, 5)
                        .rotation3DEffect(
                            Angle(degrees: animateNewGame ? 360 : 0),
                            axis: (x: 0.0, y: 1.0, z: 0.0)
                        )
                        .animation(animateNewGame ? Animation.easeInOut(duration: 0.7) : .none, value: animateNewGame)
                        .modifier(ShakeEffect(shaking: sudokuModel.shakeGrid))
                    
                    // Rakam tuşları
                    NumberPadView(sudokuModel: sudokuModel, colorScheme: colorScheme, themeColor: themeColor, themeSecondaryColor: themeSecondaryColor)
                        .padding(.horizontal)
                }
                .navigationTitle("Sudoku")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("Sudoku")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(colorScheme == .dark ? .white : themeColor)
                    }
                }
                .alert("Tebrikler!", isPresented: .constant(sudokuModel.isGameComplete)) {
                    Button("Yeni Oyun") {
                        checkForBadges()
                        sudokuModel.generateNewGame()
                        sudokuModel.gameTime = 0
                        sudokuModel.mistakes = 0
                        startTimer()
                    }
                } message: {
                    Text("Sudoku'yu \(formatTime(sudokuModel.gameTime)) sürede, \(sudokuModel.mistakes) hata ile tamamladınız!")
                }
                .overlay(
                    ZStack {
                        if showConfetti {
                            ConfettiView()
                                .ignoresSafeArea()
                        }
                        
                        if showBadgeEarned, let badge = earnedBadge {
                            BadgeEarnedView(badge: badge, onDismiss: {
                                withAnimation {
                                    showBadgeEarned = false
                                }
                            })
                        }
                    }
                )
                .sheet(item: $presentedSheet) { sheetType in
                    switch sheetType {
                    case .difficulty:
                        DifficultyPickerView(difficulty: $sudokuModel.difficulty)
                            .gesture(DragGesture(minimumDistance: 20, coordinateSpace: .global)
                                .onEnded { value in
                                    if value.translation.width > 100 {
                                        presentedSheet = nil
                                    }
                                }
                            )
                    case .stats:
                        StatsView(gameTime: sudokuModel.gameTime, mistakes: sudokuModel.mistakes, difficulty: sudokuModel.difficulty)
                            .gesture(DragGesture(minimumDistance: 20, coordinateSpace: .global)
                                .onEnded { value in
                                    if value.translation.width > 100 {
                                        presentedSheet = nil
                                    }
                                }
                            )
                    case .howToPlay:
                        HowToPlayView()
                            .gesture(DragGesture(minimumDistance: 20, coordinateSpace: .global)
                                .onEnded { value in
                                    if value.translation.width > 100 {
                                        presentedSheet = nil
                                    }
                                }
                            )
                    case .badges:
                        BadgesView(badges: $badges)
                            .gesture(DragGesture(minimumDistance: 20, coordinateSpace: .global)
                                .onEnded { value in
                                    if value.translation.width > 100 {
                                        presentedSheet = nil
                                    }
                                }
                            )
                    case .themes:
                        ThemePickerView(selectedTheme: $selectedTheme)
                            .gesture(DragGesture(minimumDistance: 20, coordinateSpace: .global)
                                .onEnded { value in
                                    if value.translation.width > 100 {
                                        presentedSheet = nil
                                    }
                                }
                            )
                    }
                }
            }
            .offset(x: dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.width > 0 {
                            dragOffset = value.translation.width
                        }
                    }
                    .onEnded { value in
                        if value.translation.width > 100 {
                            presentationMode.wrappedValue.dismiss()
                        } else {
                            withAnimation {
                                dragOffset = 0
                            }
                        }
                    }
            )
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            sudokuModel.gameTime += 1
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    private func checkForBadges() {
        // Oyun tamamlandığında rozet kontrolü
        if sudokuModel.isGameComplete {
            // Konfeti efektini göster
            withAnimation {
                showConfetti = true
            }
            
            // 5 dakikadan kısa sürede çözüldü mü?
            if sudokuModel.gameTime < 300 && !badges[0].isEarned {
                badges[0].isEarned = true
                earnedBadge = badges[0]
                showBadgeEarned = true
            }
            
            // Hiç hata yapılmadan çözüldü mü?
            if sudokuModel.mistakes == 0 && !badges[1].isEarned {
                badges[1].isEarned = true
                earnedBadge = badges[1]
                showBadgeEarned = true
            }
            
            // Zor seviyede çözüldü mü?
            if sudokuModel.difficulty == .hard && !badges[2].isEarned {
                badges[2].isEarned = true
                earnedBadge = badges[2]
                showBadgeEarned = true
            }
            
            // Konfeti efektini 3 saniye sonra kapat
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    showConfetti = false
                }
            }
        }
    }
    
    // Tema rengini döndüren yardımcı fonksiyon
    var themeColor: Color {
        colorScheme == .dark ? selectedTheme.mainColor : selectedTheme.mainColor
    }
    
    var themeSecondaryColor: Color {
        colorScheme == .dark ? selectedTheme.secondaryColor : selectedTheme.secondaryColor
    }
}

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat
    
    init(shaking: Bool) {
        animatableData = shaking ? 1 : 0
    }
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        guard animatableData > 0 else { return ProjectionTransform(.identity) }
        
        let translation = amount * sin(animatableData * .pi * CGFloat(shakesPerUnit))
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}

struct SudokuGridView: View {
    @ObservedObject var sudokuModel: SudokuModel
    let colorScheme: ColorScheme
    let themeColor: Color
    let themeSecondaryColor: Color
    
    let gridSpacing: CGFloat = 1
    let boldSpacing: CGFloat = 2
    
    var body: some View {
        VStack(spacing: boldSpacing) {
            ForEach(0..<3) { blockRow in
                HStack(spacing: boldSpacing) {
                    ForEach(0..<3) { blockCol in
                        buildBlock(blockRow: blockRow, blockCol: blockCol)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? 
                      Color(UIColor.systemGray6) : 
                      Color.white)
                .shadow(color: colorScheme == .dark ? 
                        Color.black.opacity(0.7) : 
                        Color.gray.opacity(0.5), 
                        radius: 15, x: 0, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            colorScheme == .dark ? themeColor.opacity(0.7) : themeColor.opacity(0.5),
                            colorScheme == .dark ? themeColor.opacity(0.3) : themeColor.opacity(0.2)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 5)
    }
    
    private func buildBlock(blockRow: Int, blockCol: Int) -> some View {
        VStack(spacing: gridSpacing) {
            ForEach(0..<3) { row in
                HStack(spacing: gridSpacing) {
                    ForEach(0..<3) { col in
                        let actualRow = blockRow * 3 + row
                        let actualCol = blockCol * 3 + col
                        buildCell(row: actualRow, col: actualCol)
                    }
                }
            }
        }
        .background(colorScheme == .dark ? 
                    Color(UIColor.systemGray5) : 
                    Color(UIColor.systemGray6))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(colorScheme == .dark ? 
                        Color.gray.opacity(0.6) : 
                        Color.gray.opacity(0.4), 
                        lineWidth: 1.5)
        )
    }
    
    private func buildCell(row: Int, col: Int) -> some View {
        let isSelected = sudokuModel.selectedCell?.row == row && sudokuModel.selectedCell?.col == col
        let isInSameRowOrCol = sudokuModel.selectedCell != nil && 
                              (sudokuModel.selectedCell!.row == row || sudokuModel.selectedCell!.col == col)
        let isInSameBlock = sudokuModel.selectedCell != nil && 
                           (sudokuModel.selectedCell!.row / 3 == row / 3 && sudokuModel.selectedCell!.col / 3 == col / 3)
        let value = sudokuModel.grid[row][col]
        let isInitialValue = false // Burada başlangıç değerlerini kontrol edebilirsiniz
        
        return Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                sudokuModel.selectedCell = (row, col)
            }
        }) {
            cellContent(value: value, isSelected: isSelected, isInSameRowOrCol: isInSameRowOrCol, 
                       isInSameBlock: isInSameBlock, isInitialValue: isInitialValue)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func cellContent(value: Int?, isSelected: Bool, isInSameRowOrCol: Bool, 
                            isInSameBlock: Bool, isInitialValue: Bool) -> some View {
        Text(value.map(String.init) ?? "")
            .font(.system(size: 26, weight: .bold, design: .rounded))
            .frame(width: 45, height: 45)
            .background(cellBackground(isSelected: isSelected, isInSameRowOrCol: isInSameRowOrCol, isInSameBlock: isInSameBlock))
            .cornerRadius(10)
            .overlay(cellBorder(isSelected: isSelected))
            .shadow(color: shadowColor(isSelected: isSelected), radius: isSelected ? 5 : 0)
            .foregroundColor(textColor(isInitialValue: isInitialValue))
            .scaleEffect(isSelected ? 1.08 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }
    
    private func cellBackground(isSelected: Bool, isInSameRowOrCol: Bool, isInSameBlock: Bool) -> some View {
        ZStack {
            if isSelected {
                LinearGradient(
                    gradient: Gradient(colors: [
                        colorScheme == .dark ? themeColor.opacity(0.6) : themeColor.opacity(0.5),
                        colorScheme == .dark ? themeColor.opacity(0.4) : themeColor.opacity(0.3)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else if isInSameRowOrCol {
                colorScheme == .dark ? themeColor.opacity(0.15) : themeColor.opacity(0.15)
            } else if isInSameBlock {
                colorScheme == .dark ? themeColor.opacity(0.1) : themeColor.opacity(0.1)
            } else {
                colorScheme == .dark ? Color(UIColor.systemGray4) : Color.white
            }
        }
    }
    
    private func cellBorder(isSelected: Bool) -> some View {
        RoundedRectangle(cornerRadius: 10)
            .stroke(
                isSelected ? 
                    (colorScheme == .dark ? themeColor : themeColor) : 
                    Color.gray.opacity(0.3),
                lineWidth: isSelected ? 2.5 : 0.5
            )
    }
    
    private func shadowColor(isSelected: Bool) -> Color {
        isSelected ? 
            (colorScheme == .dark ? themeColor.opacity(0.5) : themeColor.opacity(0.3)) : 
            Color.clear
    }
    
    private func textColor(isInitialValue: Bool) -> Color {
        isInitialValue ? 
            (colorScheme == .dark ? Color.gray : Color.black) : 
            (colorScheme == .dark ? Color.white : themeColor)
    }
}

struct NumberPadView: View {
    @ObservedObject var sudokuModel: SudokuModel
    let colorScheme: ColorScheme
    let themeColor: Color
    let themeSecondaryColor: Color
    @State private var pressedNumber: Int? = nil
    @State private var animateSuccess = false
    
    var body: some View {
        VStack(spacing: 10) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 9), spacing: 8) {
                ForEach(1...9, id: \.self) { number in
                    Button(action: {
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                            pressedNumber = number
                        }
                        
                        let success = sudokuModel.placeNumber(number)
                        
                        // Başarılı yerleştirme animasyonu
                        if success {
                            withAnimation {
                                animateSuccess = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation {
                                    animateSuccess = false
                                }
                            }
                        }
                        
                        // Haptic feedback
                        let generator = UIImpactFeedbackGenerator(style: success ? .medium : .light)
                        generator.impactOccurred()
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            withAnimation {
                                pressedNumber = nil
                            }
                        }
                    }) {
                        Text("\(number)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    colorScheme == .dark ? themeColor.opacity(0.5) : themeColor.opacity(0.4),
                                                    colorScheme == .dark ? themeColor.opacity(0.3) : themeColor.opacity(0.2)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                    
                                    // Üst kısımda parlak efekt
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.white.opacity(0.2))
                                        .frame(height: 15)
                                        .offset(y: -13)
                                        .mask(
                                            RoundedRectangle(cornerRadius: 10)
                                                .frame(maxWidth: .infinity, maxHeight: 42)
                                        )
                                }
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(
                                        colorScheme == .dark ? themeColor.opacity(0.7) : themeColor.opacity(0.5),
                                        lineWidth: 1
                                    )
                            )
                            .shadow(
                                color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.gray.opacity(0.3),
                                radius: 3,
                                x: 0,
                                y: 2
                            )
                            .foregroundColor(.white)
                            .scaleEffect(pressedNumber == number ? 0.9 : 1.0)
                            .overlay(
                                Circle()
                                    .fill(Color.green)
                                    .scaleEffect(animateSuccess && pressedNumber == number ? 1.5 : 0.01)
                                    .opacity(animateSuccess && pressedNumber == number ? 0 : 0.5)
                                    .animation(.easeOut(duration: 0.5), value: animateSuccess)
                            )
                    }
                }
            }
            
            Button(action: {
                if let selected = sudokuModel.selectedCell {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                        pressedNumber = 0
                    }
                    
                    sudokuModel.grid[selected.row][selected.col] = nil
                    
                    // Haptic feedback
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation {
                            pressedNumber = nil
                        }
                    }
                }
            }) {
                HStack {
                    Image(systemName: "delete.left")
                    Text("Sil")
                }
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        colorScheme == .dark ? Color.red.opacity(0.5) : Color.red.opacity(0.4),
                                        colorScheme == .dark ? Color.red.opacity(0.3) : Color.red.opacity(0.2)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        // Üst kısımda parlak efekt
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 15)
                            .offset(y: -13)
                            .mask(
                                RoundedRectangle(cornerRadius: 10)
                                    .frame(maxWidth: .infinity, maxHeight: 42)
                                )
                            )
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            colorScheme == .dark ? Color.red.opacity(0.7) : Color.red.opacity(0.5),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.gray.opacity(0.3),
                    radius: 3,
                    x: 0,
                    y: 2
                )
                .foregroundColor(.white)
                .scaleEffect(pressedNumber == 0 ? 0.95 : 1.0)
            }
        }
        .padding(.top, 5)
    }
}

struct DifficultyPickerView: View {
    @Binding var difficulty: SudokuModel.Difficulty
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.presentationMode) var presentationMode
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                (colorScheme == .dark ? Color.black : Color.white).ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("Zorluk Seviyesini Seçin")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .padding(.top, 20)
                    
                    ForEach(SudokuModel.Difficulty.allCases, id: \.self) { level in
                        Button(action: {
                            difficulty = level
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack {
                                Image(systemName: difficultyIcon(for: level))
                                    .font(.title3)
                                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                                
                                Text(level.rawValue)
                                    .font(.title3)
                                    .padding(.leading, 10)
                                
                                Spacer()
                                
                                if difficulty == level {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(colorScheme == .dark ? .purple : .blue)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(colorScheme == .dark ? 
                                          (difficulty == level ? Color.purple.opacity(0.3) : Color.gray.opacity(0.2)) : 
                                          (difficulty == level ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1)))
                                    .shadow(color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.gray.opacity(0.2), radius: 3, x: 0, y: 2)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                    
                    // Kaydırma ipucu
                    HStack {
                        Image(systemName: "arrow.right")
                        Text("Kapatmak için sağa kaydırın")
                        Image(systemName: "arrow.right")
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.bottom, 20)
                }
                .offset(x: dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if value.translation.width > 0 {
                                dragOffset = value.translation.width
                            }
                        }
                        .onEnded { value in
                            if value.translation.width > 100 {
                                presentationMode.wrappedValue.dismiss()
                            } else {
                                withAnimation {
                                    dragOffset = 0
                                }
                            }
                        }
                )
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(colorScheme == .dark ? .purple : .blue)
                }
            }
        }
    }
    
    private func difficultyIcon(for level: SudokuModel.Difficulty) -> String {
        switch level {
        case .easy:
            return "1.circle.fill"
        case .medium:
            return "2.circle.fill"
        case .hard:
            return "3.circle.fill"
        }
    }
}

struct StatsView: View {
    let gameTime: Int
    let mistakes: Int
    let difficulty: SudokuModel.Difficulty
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                (colorScheme == .dark ? Color.black : Color.white).ignoresSafeArea()
                
                VStack(spacing: 25) {
                    Text("Oyun İstatistikleri")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .padding(.top, 20)
                    
                    VStack(spacing: 20) {
                        StatItemView(
                            icon: "clock.fill",
                            title: "Oyun Süresi",
                            value: formatTime(gameTime),
                            color: .blue
                        )
                        
                        StatItemView(
                            icon: "exclamationmark.triangle.fill",
                            title: "Yapılan Hatalar",
                            value: "\(mistakes)",
                            color: .red
                        )
                        
                        StatItemView(
                            icon: "slider.horizontal.3",
                            title: "Zorluk Seviyesi",
                            value: difficulty.rawValue,
                            color: .purple
                        )
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1))
                            .shadow(color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.gray.opacity(0.3), radius: 5, x: 0, y: 3)
                    )
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Kaydırma ipucu
                    HStack {
                        Image(systemName: "arrow.right")
                        Text("Kapatmak için sağa kaydırın")
                        Image(systemName: "arrow.right")
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.bottom, 20)
                }
                .offset(x: dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if value.translation.width > 0 {
                                dragOffset = value.translation.width
                            }
                        }
                        .onEnded { value in
                            if value.translation.width > 100 {
                                dismiss()
                            } else {
                                withAnimation {
                                    dragOffset = 0
                                }
                            }
                        }
                )
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                    .foregroundColor(colorScheme == .dark ? .purple : .blue)
                }
            }
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

struct StatItemView: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(colorScheme == .dark ? color.opacity(0.2) : color.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white)
                .shadow(color: colorScheme == .dark ? Color.black.opacity(0.2) : Color.gray.opacity(0.2), radius: 3, x: 0, y: 2)
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
                .preferredColorScheme(.light)
                .previewDisplayName("Beyaz Mod")
            
            ContentView()
                .preferredColorScheme(.dark)
                .previewDisplayName("Koyu Mod")
        }
    }
}

// Rozet kazanıldı görünümü
struct BadgeEarnedView: View {
    let badge: Badge
    let onDismiss: () -> Void
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }
            
            VStack(spacing: 20) {
                Text("Yeni Rozet Kazandınız!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Image(systemName: badge.icon)
                    .font(.system(size: 80))
                    .foregroundColor(badge.color)
                    .padding()
                    .background(
                        Circle()
                            .fill(badge.color.opacity(0.2))
                            .frame(width: 150, height: 150)
                    )
                    .overlay(
                        Circle()
                            .stroke(badge.color, lineWidth: 3)
                            .frame(width: 150, height: 150)
                    )
                
                Text(badge.name)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(badge.description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.8))
                
                Button(action: {
                    dismiss()
                }) {
                    Text("Harika!")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 30)
                        .background(badge.color)
                        .cornerRadius(25)
                }
                .padding(.top, 10)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.gray.opacity(0.2))
                    .shadow(color: badge.color.opacity(0.5), radius: 20, x: 0, y: 0)
            )
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    scale = 1.0
                    opacity = 1.0
                }
            }
        }
    }
    
    private func dismiss() {
        withAnimation(.easeOut(duration: 0.2)) {
            scale = 0.5
            opacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }
}

// Rozetler sayfası
struct BadgesView: View {
    @Binding var badges: [Badge]
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.presentationMode) var presentationMode
    @State private var dragOffset: CGFloat = 0
    @State private var selectedBadge: Badge? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                (colorScheme == .dark ? Color.black : Color.white).ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("Rozetlerim")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .padding(.top, 20)
                    
                    if badges.filter({ $0.isEarned }).isEmpty {
                        VStack(spacing: 15) {
                            Image(systemName: "medal.fill")
                                .font(.system(size: 70))
                                .foregroundColor(.gray.opacity(0.5))
                                .padding()
                            
                            Text("Henüz rozet kazanmadınız")
                                .font(.title3)
                                .foregroundColor(.gray)
                            
                            Text("Sudoku çözerek rozetler kazanabilirsiniz")
                                .font(.subheadline)
                                .foregroundColor(.gray.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .frame(maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 20) {
                                ForEach(badges.filter { $0.isEarned }) { badge in
                                    BadgeItemView(badge: badge)
                                        .onTapGesture {
                                            selectedBadge = badge
                                        }
                                }
                            }
                            .padding()
                            
                            Divider()
                                .padding(.vertical)
                            
                            Text("Kazanılabilir Rozetler")
                                .font(.headline)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 20) {
                                ForEach(badges.filter { !$0.isEarned }) { badge in
                                    BadgeItemView(badge: badge, locked: true)
                                        .onTapGesture {
                                            selectedBadge = badge
                                        }
                                }
                            }
                            .padding()
                        }
                    }
                    
                    // Kaydırma ipucu
                    HStack {
                        Image(systemName: "arrow.right")
                        Text("Kapatmak için sağa kaydırın")
                        Image(systemName: "arrow.right")
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.bottom, 20)
                }
                .padding(.horizontal)
                .offset(x: dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if value.translation.width > 0 {
                                dragOffset = value.translation.width
                            }
                        }
                        .onEnded { value in
                            if value.translation.width > 100 {
                                presentationMode.wrappedValue.dismiss()
                            } else {
                                withAnimation {
                                    dragOffset = 0
                                }
                            }
                        }
                )
                
                if let badge = selectedBadge {
                    BadgeDetailView(badge: badge, isLocked: !badge.isEarned) {
                        selectedBadge = nil
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(colorScheme == .dark ? .purple : .blue)
                }
            }
        }
    }
}

struct BadgeItemView: View {
    let badge: Badge
    var locked: Bool = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: badge.icon)
                .font(.system(size: 40))
                .foregroundColor(locked ? .gray : badge.color)
                .frame(width: 80, height: 80)
                .background(
                    Circle()
                        .fill(locked ? Color.gray.opacity(0.1) : badge.color.opacity(0.2))
                )
                .overlay(
                    Circle()
                        .stroke(locked ? Color.gray.opacity(0.3) : badge.color, lineWidth: 2)
                )
                .overlay(
                    locked ?
                        Image(systemName: "lock.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                            .offset(y: 25)
                        : nil
                )
            
            Text(badge.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(locked ? .gray : (colorScheme == .dark ? .white : .primary))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(width: 120, height: 150)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white)
                .shadow(color: locked ? Color.gray.opacity(0.2) : badge.color.opacity(0.3), radius: 5, x: 0, y: 3)
        )
        .opacity(locked ? 0.7 : 1.0)
    }
}

struct BadgeDetailView: View {
    let badge: Badge
    let isLocked: Bool
    let onDismiss: () -> Void
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }
            
            VStack(spacing: 25) {
                Image(systemName: badge.icon)
                    .font(.system(size: 80))
                    .foregroundColor(isLocked ? .gray : badge.color)
                    .padding()
                    .background(
                        Circle()
                            .fill(isLocked ? Color.gray.opacity(0.1) : badge.color.opacity(0.2))
                            .frame(width: 180, height: 180)
                    )
                    .overlay(
                        Circle()
                            .stroke(isLocked ? Color.gray.opacity(0.3) : badge.color, lineWidth: 3)
                            .frame(width: 180, height: 180)
                    )
                    .overlay(
                        isLocked ?
                            Image(systemName: "lock.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.gray)
                                .offset(y: 60)
                            : nil
                    )
                
                Text(badge.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(badge.description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.8))
                
                if isLocked {
                    Text("Bu rozeti kazanmak için görevini tamamla!")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.top, 5)
                } else {
                    Text("Tebrikler! Bu rozeti kazandınız.")
                        .font(.subheadline)
                        .foregroundColor(.green)
                        .padding(.top, 5)
                }
                
                Button(action: {
                    dismiss()
                }) {
                    Text("Tamam")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 30)
                        .background(isLocked ? Color.gray : badge.color)
                        .cornerRadius(25)
                }
                .padding(.top, 10)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1))
                    .shadow(color: isLocked ? Color.gray.opacity(0.5) : badge.color.opacity(0.5), radius: 20, x: 0, y: 0)
            )
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    scale = 1.0
                    opacity = 1.0
                }
            }
        }
    }
    
    private func dismiss() {
        withAnimation(.easeOut(duration: 0.2)) {
            scale = 0.5
            opacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }
}

// SudokuModel sınıfını ekleyelim
class SudokuModel: ObservableObject {
    @Published var grid: [[Int?]] = Array(repeating: Array(repeating: nil, count: 9), count: 9)
    @Published var selectedCell: (row: Int, col: Int)? = nil
    @Published var mistakes: Int = 0
    @Published var gameTime: Int = 0
    @Published var isGameComplete: Bool = false
    @Published var shakeGrid: Bool = false
    @Published var difficulty: Difficulty = .medium
    
    enum Difficulty: String, CaseIterable {
        case easy = "Kolay"
        case medium = "Orta"
        case hard = "Zor"
    }
    
    init() {
        generateNewGame()
    }
    
    func generateNewGame() {
        // Burada gerçek bir Sudoku oluşturma algoritması kullanılabilir
        // Şimdilik basit bir grid oluşturalım
        grid = Array(repeating: Array(repeating: nil, count: 9), count: 9)
        selectedCell = nil
        isGameComplete = false
        
        // Örnek olarak bazı hücreleri dolduralım
        let cellsToFill = difficulty == .easy ? 30 : (difficulty == .medium ? 25 : 20)
        for _ in 0..<cellsToFill {
            let row = Int.random(in: 0..<9)
            let col = Int.random(in: 0..<9)
            grid[row][col] = Int.random(in: 1...9)
        }
    }
    
    func placeNumber(_ number: Int) -> Bool {
        guard let selected = selectedCell else { return false }
        
        // Burada gerçek bir Sudoku doğrulama algoritması kullanılabilir
        // Şimdilik basit bir kontrol yapalım
        let isValid = isValidPlacement(number, at: selected.row, col: selected.col)
        
        if isValid {
            grid[selected.row][selected.col] = number
            
            // Oyun tamamlandı mı kontrol et
            checkGameCompletion()
            
            return true
        } else {
            mistakes += 1
            
            // Hata animasyonu
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                shakeGrid = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation {
                    self.shakeGrid = false
                }
            }
            
            return false
        }
    }
    
    private func isValidPlacement(_ number: Int, at row: Int, col: Int) -> Bool {
        // Satır kontrolü
        for c in 0..<9 {
            if c != col && grid[row][c] == number {
                return false
            }
        }
        
        // Sütun kontrolü
        for r in 0..<9 {
            if r != row && grid[r][col] == number {
                return false
            }
        }
        
        // 3x3 blok kontrolü
        let blockRow = row / 3 * 3
        let blockCol = col / 3 * 3
        
        for r in blockRow..<blockRow+3 {
            for c in blockCol..<blockCol+3 {
                if (r != row || c != col) && grid[r][c] == number {
                    return false
                }
            }
        }
        
        return true
    }
    
    private func checkGameCompletion() {
        // Tüm hücreler dolu mu kontrol et
        for row in 0..<9 {
            for col in 0..<9 {
                if grid[row][col] == nil {
                    return
                }
            }
        }
        
        // Tüm hücreler dolu ise oyun tamamlandı
        isGameComplete = true
    }
}

// Tema seçici görünümü
struct ThemePickerView: View {
    @Binding var selectedTheme: ContentView.ColorTheme
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.presentationMode) var presentationMode
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                (colorScheme == .dark ? Color.black : Color.white).ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("Tema Seçin")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .padding(.top, 20)
                    
                    ScrollView {
                        VStack(spacing: 15) {
                            ForEach(ContentView.ColorTheme.allCases) { theme in
                                Button(action: {
                                    withAnimation {
                                        selectedTheme = theme
                                    }
                                    
                                    // Haptic feedback
                                    let generator = UIImpactFeedbackGenerator(style: .medium)
                                    generator.impactOccurred()
                                    
                                    // Kısa bir gecikme ile kapat
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        presentationMode.wrappedValue.dismiss()
                                    }
                                }) {
                                    HStack {
                                        Circle()
                                            .fill(theme.mainColor)
                                            .frame(width: 30, height: 30)
                                        
                                        Image(systemName: theme.icon)
                                            .foregroundColor(theme.mainColor)
                                            .font(.title3)
                                            .padding(.leading, 5)
                                        
                                        Text(theme.rawValue)
                                            .font(.title3)
                                            .padding(.leading, 10)
                                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                                        
                                        Spacer()
                                        
                                        if selectedTheme == theme {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(theme.mainColor)
                                        }
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(colorScheme == .dark ? 
                                                  (selectedTheme == theme ? theme.mainColor.opacity(0.3) : Color.gray.opacity(0.2)) : 
                                                  (selectedTheme == theme ? theme.mainColor.opacity(0.2) : Color.gray.opacity(0.1)))
                                            .shadow(color: colorScheme == .dark ? theme.mainColor.opacity(0.3) : theme.mainColor.opacity(0.2), radius: 3, x: 0, y: 2)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                    
                    // Kaydırma ipucu
                    HStack {
                        Image(systemName: "arrow.right")
                        Text("Kapatmak için sağa kaydırın")
                        Image(systemName: "arrow.right")
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.bottom, 20)
                }
                .offset(x: dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if value.translation.width > 0 {
                                dragOffset = value.translation.width
                            }
                        }
                        .onEnded { value in
                            if value.translation.width > 100 {
                                presentationMode.wrappedValue.dismiss()
                            } else {
                                withAnimation {
                                    dragOffset = 0
                                }
                            }
                        }
                )
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(selectedTheme.mainColor)
                }
            }
        }
    }
}
