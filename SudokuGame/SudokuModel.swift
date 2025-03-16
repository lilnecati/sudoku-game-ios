import Foundation
import SwiftUI

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
        // Timer'ı ContentView'da başlatacağız
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
        
        // Performans için daha hızlı kontroller
        // Satır kontrolü - daha hızlı implementasyon
        for c in 0..<9 where c != col {
            if grid[row][c] == number {
                validMovesCache[key] = false
                return false
            }
        }
        
        // Sütun kontrolü - daha hızlı implementasyon
        for r in 0..<9 where r != row {
            if grid[r][col] == number {
                validMovesCache[key] = false
                return false
            }
        }
        
        // Blok kontrolü - daha hızlı implementasyon
        let blockRow = (row / 3) * 3
        let blockCol = (col / 3) * 3
        
        for r in blockRow..<blockRow+3 {
            for c in blockCol..<blockCol+3 where (r != row || c != col) {
                if grid[r][c] == number {
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
    
    func enterNumber(_ number: Int, at row: Int, col: Int) {
        // Hücre düzenlenebilir değilse işlem yapma
        guard isCellEditable(at: row, col: col) else { return }
        
        // Geçerli bir hamle mi kontrol et
        if isValidMove(number: number, at: row, col: col) {
            grid[row][col] = number
            checkGameCompletion()
        } else {
            // Geçersiz hamle
            shake()
            mistakes += 1
        }
    }
} 