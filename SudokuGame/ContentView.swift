//
//  ContentView.swift
//  SudokuGame
//
//  Created by Necati Yıldırım on 16.03.2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var sudokuModel = SudokuModel()
    @State private var showingDifficultyPicker = false
    @State private var showingStats = false
    @State private var showingHowToPlay = false
    @State private var timer: Timer?
    @State private var animateNewGame = false
    @State private var presentedSheet: SheetType? = nil
    @State private var dragOffset: CGFloat = 0
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.presentationMode) var presentationMode
    
    enum SheetType: Identifiable {
        case difficulty, stats, howToPlay
        
        var id: Int {
            switch self {
            case .difficulty: return 0
            case .stats: return 1
            case .howToPlay: return 2
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
                    LinearGradient(gradient: Gradient(colors: [Color.black, Color.purple.opacity(0.2)]), startPoint: .top, endPoint: .bottom) :
                    LinearGradient(gradient: Gradient(colors: [Color.white, Color.blue.opacity(0.1)]), startPoint: .top, endPoint: .bottom))
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
                                    .foregroundColor(colorScheme == .dark ? .cyan : .blue)
                                    .shadow(color: colorScheme == .dark ? .cyan.opacity(0.3) : .blue.opacity(0.3), radius: 2, x: 0, y: 1)
                                Text("Süre: \(formatTime(sudokuModel.gameTime))")
                                    .foregroundColor(colorScheme == .dark ? .cyan : .blue)
                                    .fontWeight(.semibold)
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(colorScheme == .dark ? Color.blue.opacity(0.1) : Color.blue.opacity(0.05))
                                    .shadow(color: colorScheme == .dark ? Color.cyan.opacity(0.1) : Color.blue.opacity(0.1), radius: 2, x: 0, y: 1)
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
                                    .foregroundColor(colorScheme == .dark ? .purple : .blue)
                                    .frame(width: 36, height: 36)
                                    .background(
                                        Circle()
                                            .fill(colorScheme == .dark ? Color.purple.opacity(0.2) : Color.blue.opacity(0.1))
                                            .shadow(color: colorScheme == .dark ? Color.purple.opacity(0.3) : Color.blue.opacity(0.2), radius: 2, x: 0, y: 1)
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
                                        .fill(colorScheme == .dark ? Color.purple.opacity(0.3) : Color.blue.opacity(0.2))
                                        .shadow(color: colorScheme == .dark ? Color.purple.opacity(0.3) : Color.blue.opacity(0.2), radius: 3, x: 0, y: 2)
                                )
                            }
                            
                            Button(action: {
                                presentedSheet = .stats
                            }) {
                                Image(systemName: "chart.bar.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(colorScheme == .dark ? .purple : .blue)
                                    .frame(width: 36, height: 36)
                                    .background(
                                        Circle()
                                            .fill(colorScheme == .dark ? Color.purple.opacity(0.2) : Color.blue.opacity(0.1))
                                            .shadow(color: colorScheme == .dark ? Color.purple.opacity(0.3) : Color.blue.opacity(0.2), radius: 2, x: 0, y: 1)
                                    )
                            }
                            
                            Button(action: {
                                presentedSheet = .howToPlay
                            }) {
                                Image(systemName: "questionmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(colorScheme == .dark ? .purple : .blue)
                                    .frame(width: 36, height: 36)
                                    .background(
                                        Circle()
                                            .fill(colorScheme == .dark ? Color.purple.opacity(0.2) : Color.blue.opacity(0.1))
                                            .shadow(color: colorScheme == .dark ? Color.purple.opacity(0.3) : Color.blue.opacity(0.2), radius: 2, x: 0, y: 1)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Sudoku grid
                    SudokuGridView(sudokuModel: sudokuModel, colorScheme: colorScheme)
                        .padding(.horizontal, 5)
                        .rotation3DEffect(
                            Angle(degrees: animateNewGame ? 360 : 0),
                            axis: (x: 0.0, y: 1.0, z: 0.0)
                        )
                        .animation(animateNewGame ? Animation.easeInOut(duration: 0.7) : .none, value: animateNewGame)
                        .modifier(ShakeEffect(shaking: sudokuModel.shakeGrid))
                    
                    // Rakam tuşları
                    NumberPadView(sudokuModel: sudokuModel, colorScheme: colorScheme)
                        .padding(.horizontal)
                }
                .navigationTitle("Sudoku")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("Sudoku")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(colorScheme == .dark ? .white : .blue)
                    }
                }
                .alert("Tebrikler!", isPresented: .constant(sudokuModel.isGameComplete)) {
                    Button("Yeni Oyun") {
                        sudokuModel.generateNewGame()
                        sudokuModel.gameTime = 0
                        sudokuModel.mistakes = 0
                        startTimer()
                    }
                } message: {
                    Text("Sudoku'yu \(formatTime(sudokuModel.gameTime)) sürede, \(sudokuModel.mistakes) hata ile tamamladınız!")
                }
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
                            colorScheme == .dark ? Color.purple.opacity(0.7) : Color.blue.opacity(0.5),
                            colorScheme == .dark ? Color.purple.opacity(0.3) : Color.blue.opacity(0.2)
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
                        colorScheme == .dark ? Color.purple.opacity(0.6) : Color.blue.opacity(0.5),
                        colorScheme == .dark ? Color.purple.opacity(0.4) : Color.blue.opacity(0.3)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else if isInSameRowOrCol {
                colorScheme == .dark ? Color.purple.opacity(0.15) : Color.blue.opacity(0.15)
            } else if isInSameBlock {
                colorScheme == .dark ? Color.purple.opacity(0.1) : Color.blue.opacity(0.1)
            } else {
                colorScheme == .dark ? Color(UIColor.systemGray4) : Color.white
            }
        }
    }
    
    private func cellBorder(isSelected: Bool) -> some View {
        RoundedRectangle(cornerRadius: 10)
            .stroke(
                isSelected ? 
                    (colorScheme == .dark ? Color.purple : Color.blue) : 
                    Color.gray.opacity(0.3),
                lineWidth: isSelected ? 2.5 : 0.5
            )
    }
    
    private func shadowColor(isSelected: Bool) -> Color {
        isSelected ? 
            (colorScheme == .dark ? Color.purple.opacity(0.5) : Color.blue.opacity(0.3)) : 
            Color.clear
    }
    
    private func textColor(isInitialValue: Bool) -> Color {
        isInitialValue ? 
            (colorScheme == .dark ? Color.gray : Color.black) : 
            (colorScheme == .dark ? Color.white : Color.blue)
    }
}

struct NumberPadView: View {
    @ObservedObject var sudokuModel: SudokuModel
    let colorScheme: ColorScheme
    @State private var pressedNumber: Int? = nil
    
    var body: some View {
        VStack(spacing: 10) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 9), spacing: 8) {
                ForEach(1...9, id: \.self) { number in
                    Button(action: {
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                            pressedNumber = number
                        }
                        
                        sudokuModel.placeNumber(number)
                        
                        // Haptic feedback
                        let generator = UIImpactFeedbackGenerator(style: .light)
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
                                                    colorScheme == .dark ? Color.purple.opacity(0.5) : Color.blue.opacity(0.4),
                                                    colorScheme == .dark ? Color.purple.opacity(0.3) : Color.blue.opacity(0.2)
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
                                        colorScheme == .dark ? Color.purple.opacity(0.7) : Color.blue.opacity(0.5),
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
