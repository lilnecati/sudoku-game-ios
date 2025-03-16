import Foundation

class SudokuModel: ObservableObject {
    @Published var grid: [[Int?]]
    @Published var selectedCell: (row: Int, col: Int)?
    @Published var difficulty: Difficulty = .medium
    @Published var mistakes: Int = 0
    @Published var gameTime: Int = 0
    @Published var isGameComplete: Bool = false
    @Published var shakeGrid: Bool = false
    @Published var canUndo: Bool = false
    
    // Hamle geçmişini tutacak yapı
    private struct Move {
        let row: Int
        let col: Int
        let oldValue: Int?
        let newValue: Int?
    }
    
    // Hamle geçmişi
    private var moveHistory: [Move] = []
    
    // Performans iyileştirmesi için ön hesaplanmış değerler
    private var initialGrid: [[Int?]] = Array(repeating: Array(repeating: nil, count: 9), count: 9)
    private var solution: [[Int]] = Array(repeating: Array(repeating: 0, count: 9), count: 9)
    
    enum Difficulty: String, CaseIterable {
        case easy = "Kolay"
        case medium = "Orta"
        case hard = "Zor"
        
        var emptyCellCount: Int {
            switch self {
            case .easy: return 30
            case .medium: return 40
            case .hard: return 50
            }
        }
    }
    
    init() {
        grid = Array(repeating: Array(repeating: nil, count: 9), count: 9)
        generateNewGame()
    }
    
    func generateNewGame() {
        // Boş grid oluştur
        grid = Array(repeating: Array(repeating: nil, count: 9), count: 9)
        
        // Çözüm oluşturma işlemini ana thread'de yapmak için kontrol
        if !Thread.isMainThread {
            DispatchQueue.main.sync {
                self.generateSolution()
            }
        } else {
            generateSolution()
        }
        
        // Çözümü kopyala
        for row in 0..<9 {
            for col in 0..<9 {
                grid[row][col] = solution[row][col]
            }
        }
        
        // Zorluk seviyesine göre hücreleri boşalt
        let cellsToRemove = difficulty.emptyCellCount
        var removedCells = 0
        
        while removedCells < cellsToRemove {
            let row = Int.random(in: 0..<9)
            let col = Int.random(in: 0..<9)
            
            if grid[row][col] != nil {
                grid[row][col] = nil
                removedCells += 1
            }
        }
        
        // Başlangıç gridini kaydet
        initialGrid = grid.map { $0.map { $0 } }
        
        // Yeni oyun başladığında hamle geçmişini temizle
        moveHistory.removeAll()
        canUndo = false
        
        // Hataları ve süreyi sıfırla
        mistakes = 0
        gameTime = 0
        isGameComplete = false
    }
    
    // Daha hızlı bir çözüm oluşturma algoritması
    private func generateSolution() {
        // Boş çözüm oluştur
        solution = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        
        // Önce ilk satırı karıştır
        var numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9]
        numbers.shuffle()
        
        for col in 0..<9 {
            solution[0][col] = numbers[col]
        }
        
        // Geri kalan ızgarayı çöz
        if !solveGrid() {
            // Çözüm bulunamazsa tekrar dene
            generateSolution()
        }
    }
    
    private func solveGrid() -> Bool {
        for row in 0..<9 {
            for col in 0..<9 {
                if solution[row][col] == 0 {
                    var numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9]
                    numbers.shuffle() // Rastgele çözümler için
                    
                    for num in numbers {
                        if isValidForSolution(num, at: row, col: col) {
                            solution[row][col] = num
                            
                            if solveGrid() {
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
    
    private func isValidForSolution(_ number: Int, at row: Int, col: Int) -> Bool {
        // Satır kontrolü
        for i in 0..<9 {
            if solution[row][i] == number {
                return false
            }
        }
        
        // Sütun kontrolü
        for i in 0..<9 {
            if solution[i][col] == number {
                return false
            }
        }
        
        // 3x3 kutu kontrolü
        let boxRow = (row / 3) * 3
        let boxCol = (col / 3) * 3
        
        for i in 0..<3 {
            for j in 0..<3 {
                if solution[boxRow + i][boxCol + j] == number {
                    return false
                }
            }
        }
        
        return true
    }
    
    func isValid(_ number: Int, at row: Int, col: Int) -> Bool {
        // Satır kontrolü
        for i in 0..<9 {
            if grid[row][i] == number && i != col {
                return false
            }
        }
        
        // Sütun kontrolü
        for i in 0..<9 {
            if grid[i][col] == number && i != row {
                return false
            }
        }
        
        // 3x3 kutu kontrolü
        let boxRow = (row / 3) * 3
        let boxCol = (col / 3) * 3
        
        for i in 0..<3 {
            for j in 0..<3 {
                if grid[boxRow + i][boxCol + j] == number && (boxRow + i != row || boxCol + j != col) {
                    return false
                }
            }
        }
        
        return true
    }
    
    // Hızlı ipucu için çözümden doğrudan kontrol
    func getCorrectNumber(at row: Int, col: Int) -> Int? {
        return solution[row][col]
    }
    
    // Hücrenin değiştirilebilir olup olmadığını kontrol et
    func isCellEditable(at row: Int, col: Int) -> Bool {
        return initialGrid[row][col] == nil
    }
    
    private func solveSudoku() -> Bool {
        var row = -1
        var col = -1
        var isEmpty = false
        
        // Boş hücre bul
        for i in 0..<9 {
            for j in 0..<9 {
                if grid[i][j] == nil {
                    row = i
                    col = j
                    isEmpty = true
                    break
                }
            }
            if isEmpty {
                break
            }
        }
        
        // Tüm hücreler dolu
        if !isEmpty {
            return true
        }
        
        // Rakamları dene
        for num in 1...9 {
            if isValid(num, at: row, col: col) {
                grid[row][col] = num
                
                if solveSudoku() {
                    return true
                }
                
                grid[row][col] = nil
            }
        }
        
        return false
    }
    
    func placeNumber(_ number: Int) {
        // Ana thread kontrolü
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.placeNumber(number)
            }
            return
        }
        
        guard let selectedCell = selectedCell else { return }
        
        // Başlangıçta dolu olan hücreleri değiştirmeye izin verme
        if initialGrid[selectedCell.row][selectedCell.col] != nil {
            return
        }
        
        if isValid(number, at: selectedCell.row, col: selectedCell.col) {
            // Hamleyi geçmişe kaydet
            let move = Move(row: selectedCell.row, col: selectedCell.col, oldValue: grid[selectedCell.row][selectedCell.col], newValue: number)
            moveHistory.append(move)
            canUndo = true
            
            grid[selectedCell.row][selectedCell.col] = number
            checkGameCompletion()
        } else {
            mistakes += 1
            // Hata yapınca sallama efekti için
            shakeGrid = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.shakeGrid = false
            }
        }
    }
    
    // Hücreyi temizleme fonksiyonu
    func clearCell(at row: Int, col: Int) {
        // Ana thread kontrolü
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.clearCell(at: row, col: col)
            }
            return
        }
        
        // Başlangıçta dolu olan hücreleri değiştirmeye izin verme
        if initialGrid[row][col] != nil {
            return
        }
        
        if grid[row][col] != nil {
            // Hamleyi geçmişe kaydet
            let move = Move(row: row, col: col, oldValue: grid[row][col], newValue: nil)
            moveHistory.append(move)
            canUndo = true
            
            grid[row][col] = nil
        }
    }
    
    // Son hamleyi geri alma fonksiyonu
    func undoLastMove() {
        // Ana thread kontrolü
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.undoLastMove()
            }
            return
        }
        
        guard !moveHistory.isEmpty else { return }
        
        let lastMove = moveHistory.removeLast()
        grid[lastMove.row][lastMove.col] = lastMove.oldValue
        
        // Geçmişte hamle kalmadıysa geri alma butonunu devre dışı bırak
        canUndo = !moveHistory.isEmpty
    }
    
    private func checkGameCompletion() {
        for row in 0..<9 {
            for col in 0..<9 {
                if grid[row][col] == nil {
                    return
                }
            }
        }
        isGameComplete = true
    }
} 