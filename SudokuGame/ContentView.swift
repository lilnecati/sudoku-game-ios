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
    @State private var timer: Timer?
    
    let gridSpacing: CGFloat = 1
    let boldSpacing: CGFloat = 2
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Üst bilgi alanı
                HStack {
                    VStack(alignment: .leading) {
                        Text("Hata: \(sudokuModel.mistakes)")
                            .foregroundColor(.red)
                        Text("Süre: \(formatTime(sudokuModel.gameTime))")
                            .foregroundColor(.blue)
                    }
                    Spacer()
                    Button(action: {
                        showingDifficultyPicker = true
                    }) {
                        Text(sudokuModel.difficulty.rawValue)
                            .padding()
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                
                // Sudoku grid
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
                .background(Color.gray.opacity(0.2))
                
                // Rakam tuşları
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                    ForEach(1...9, id: \.self) { number in
                        Button(action: {
                            sudokuModel.placeNumber(number)
                        }) {
                            Text("\(number)")
                                .font(.title2)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(10)
                        }
                    }
                    Button(action: {
                        if let selected = sudokuModel.selectedCell {
                            sudokuModel.grid[selected.row][selected.col] = nil
                        }
                    }) {
                        Image(systemName: "delete.left")
                            .font(.title2)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.red.opacity(0.2))
                            .cornerRadius(10)
                    }
                }
                .padding()
                
                Button(action: {
                    sudokuModel.generateNewGame()
                    sudokuModel.gameTime = 0
                    sudokuModel.mistakes = 0
                    startTimer()
                }) {
                    Text("Yeni Oyun")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }
            .navigationTitle("Sudoku")
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
            .sheet(isPresented: $showingDifficultyPicker) {
                DifficultyPickerView(difficulty: $sudokuModel.difficulty, isPresented: $showingDifficultyPicker)
            }
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
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
        .background(Color.white)
    }
    
    private func buildCell(row: Int, col: Int) -> some View {
        let isSelected = sudokuModel.selectedCell?.row == row && sudokuModel.selectedCell?.col == col
        
        return Button(action: {
            sudokuModel.selectedCell = (row, col)
        }) {
            Text(sudokuModel.grid[row][col].map(String.init) ?? "")
                .font(.title2)
                .frame(width: 35, height: 35)
                .background(isSelected ? Color.blue.opacity(0.3) : Color.white)
                .cornerRadius(5)
        }
        .buttonStyle(PlainButtonStyle())
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

struct DifficultyPickerView: View {
    @Binding var difficulty: SudokuModel.Difficulty
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            List(SudokuModel.Difficulty.allCases, id: \.self) { level in
                Button(action: {
                    difficulty = level
                    isPresented = false
                }) {
                    HStack {
                        Text(level.rawValue)
                        Spacer()
                        if difficulty == level {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Zorluk Seviyesi")
            .navigationBarItems(trailing: Button("Kapat") {
                isPresented = false
            })
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
