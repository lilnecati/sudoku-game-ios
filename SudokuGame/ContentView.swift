import SwiftUI

struct ContentView: View {
    @StateObject private var sudokuModel = SudokuModel()
    @State private var showingHowToPlay = false
    @State private var showingSettings = false
    @State private var selectedNumber: Int? = nil
    @State private var timer: Timer? = nil
    @State private var isDarkMode = false
    
    let colors = [
        Color.blue.opacity(0.3),
        Color.green.opacity(0.3),
        Color.orange.opacity(0.3),
        Color.purple.opacity(0.3),
        Color.pink.opacity(0.3)
    ]
    
    var body: some View {
        ZStack {
            Color(isDarkMode ? .black : .white)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                // Üst bilgi çubuğu
                HStack {
                    Button(action: {
                        // Ana menüye dön
                    }) {
                        Image(systemName: "house.fill")
                            .font(.title)
                            .foregroundColor(isDarkMode ? .white : .black)
                    }
                    .padding()
                    
                    Spacer()
                    
                    Text("Sudoku")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(isDarkMode ? .white : .black)
                    
                    Spacer()
                    
                    Button(action: {
                        showingSettings.toggle()
                    }) {
                        Image(systemName: "gear")
                            .font(.title)
                            .foregroundColor(isDarkMode ? .white : .black)
                    }
                    .padding()
                }
                
                // Oyun bilgileri
                HStack {
                    VStack(alignment: .leading) {
                        Text("Zorluk: \(sudokuModel.difficulty.rawValue)")
                            .foregroundColor(isDarkMode ? .white : .black)
                        
                        Text("Hatalar: \(sudokuModel.mistakes)")
                            .foregroundColor(isDarkMode ? .white : .black)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Süre: \(formatTime(sudokuModel.gameTime))")
                            .foregroundColor(isDarkMode ? .white : .black)
                        
                        Button("Yeni Oyun") {
                            sudokuModel.generateNewGame()
                            resetTimer()
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(5)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Sudoku ızgarası
                VStack(spacing: 0) {
                    ForEach(0..<9) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<9) { col in
                                SudokuCell(
                                    value: sudokuModel.grid[row][col],
                                    isSelected: sudokuModel.selectedCell?.row == row && sudokuModel.selectedCell?.col == col,
                                    onTap: {
                                        sudokuModel.selectedCell = (row: row, col: col)
                                    }
                                )
                                .frame(width: 35, height: 35)
                                .overlay(
                                    Rectangle()
                                        .stroke(Color.gray, lineWidth: 0.5)
                                )
                                .overlay(
                                    Group {
                                        if col == 2 || col == 5 {
                                            Rectangle()
                                                .frame(width: 2, height: 35)
                                                .foregroundColor(.black)
                                                .offset(x: 17.5)
                                        }
                                        if row == 2 || row == 5 {
                                            Rectangle()
                                                .frame(width: 35, height: 2)
                                                .foregroundColor(.black)
                                                .offset(y: 17.5)
                                        }
                                    }
                                )
                            }
                        }
                    }
                }
                .overlay(
                    Rectangle()
                        .stroke(Color.black, lineWidth: 2)
                )
                .padding()
                .scaleEffect(sudokuModel.shakeGrid ? 0.95 : 1.0)
                
                Spacer()
                
                // Rakam seçici
                HStack {
                    ForEach(1...9, id: \.self) { number in
                        Button(action: {
                            if let selected = sudokuModel.selectedCell {
                                if sudokuModel.grid[selected.row][selected.col] == nil {
                                    sudokuModel.placeNumber(number)
                                }
                            }
                            selectedNumber = number
                        }) {
                            Text("\(number)")
                                .font(.title)
                                .frame(width: 35, height: 35)
                                .background(selectedNumber == number ? Color.blue.opacity(0.3) : Color.clear)
                                .foregroundColor(isDarkMode ? .white : .black)
                                .cornerRadius(5)
                        }
                    }
                }
                .padding()
                
                // Alt bilgi çubuğu
                HStack {
                    Button(action: {
                        showingHowToPlay.toggle()
                    }) {
                        Text("Nasıl Oynanır?")
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    Toggle(isOn: $isDarkMode) {
                        Text("Karanlık Mod")
                            .foregroundColor(isDarkMode ? .white : .black)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                }
                .padding()
            }
        }
        .sheet(isPresented: $showingHowToPlay) {
            HowToPlayView()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(isDarkMode: $isDarkMode)
        }
        .alert(isPresented: $sudokuModel.isGameComplete) {
            Alert(
                title: Text("Tebrikler!"),
                message: Text("Sudoku'yu \(formatTime(sudokuModel.gameTime)) sürede tamamladınız!"),
                dismissButton: .default(Text("Tamam")) {
                    sudokuModel.generateNewGame()
                    resetTimer()
                }
            )
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
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

struct SudokuCell: View {
    let value: Int?
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                Rectangle()
                    .fill(isSelected ? Color.blue.opacity(0.3) : Color.clear)
                
                if let value = value {
                    Text("\(value)")
                        .font(.title2)
                        .foregroundColor(.black)
                }
            }
        }
    }
}

struct SettingsView: View {
    @Binding var isDarkMode: Bool
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Görünüm")) {
                    Toggle("Karanlık Mod", isOn: $isDarkMode)
                }
                
                Section(header: Text("Hakkında")) {
                    Text("Sudoku Oyunu v1.0")
                    Text("© 2023 Tüm hakları saklıdır")
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