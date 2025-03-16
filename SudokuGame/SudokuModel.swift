import Foundation

class SudokuModel: ObservableObject {
    @Published var grid: [[Int?]]
    @Published var selectedCell: (row: Int, col: Int)?
    @Published var difficulty: Difficulty = .medium
    @Published var mistakes: Int = 0
    @Published var gameTime: Int = 0
    @Published var isGameComplete: Bool = false
    @Published var shakeGrid: Bool = false
    
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
        
        // Base sudoku çözümü oluştur
        _ = solveSudoku()
        
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
    }
    
    private func isValid(_ number: Int, at row: Int, col: Int) -> Bool {
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
        guard let selectedCell = selectedCell else { return }
        
        if isValid(number, at: selectedCell.row, col: selectedCell.col) {
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