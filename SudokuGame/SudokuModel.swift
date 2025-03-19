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
    @Published var selectedCell: (row: Int, col: Int)? = nil {
        didSet {
            // Hücre değiştiğinde animasyon tetikleyicisini güncelle
            cellSelectionAnimationTrigger = UUID()
        }
    }
    @Published var cellSelectionAnimationTrigger = UUID()
    @Published var isShaking = false
    @Published var gameTime: TimeInterval = 0
    @Published var mistakes: Int = 0
    @Published var isGameComplete: Bool = false
    @Published var numberEnterAnimationCell: (row: Int, col: Int)? = nil
    @Published var successfulNumberEnter = false
    
    private var timer: Timer?
    private var solution: [[Int]] = Array(repeating: Array(repeating: 0, count: 9), count: 9)
    
    // Performans için önbelleğe alınmış değerler
    private var validMovesCache: [String: Bool] = [:]
    private var cellEditabilityCache: [String: Bool] = [:]
    
    // Oyuncu notları
    @Published var notes: [[[Int]]] = Array(repeating: Array(repeating: [], count: 9), count: 9)
    
    // Önbelleği temizleme
    private func clearCache() {
        validMovesCache.removeAll(keepingCapacity: true)
        cellEditabilityCache.removeAll(keepingCapacity: true)
    }
    
    // Zorluk seviyesi için UserDefaults kullanımı
    @Published var difficulty: Difficulty {
        didSet {
            UserDefaults.standard.set(difficulty.rawValue, forKey: "difficulty")
            UserDefaults.standard.synchronize()
        }
    }
    
    // Oyun durumunu kaydetme
    func saveGameState() {
        // Grid'i kaydet
        let gridData = try? JSONEncoder().encode(grid)
        UserDefaults.standard.set(gridData, forKey: "currentGrid")
        
        // Orijinal grid'i kaydet
        let originalGridData = try? JSONEncoder().encode(originalGrid)
        UserDefaults.standard.set(originalGridData, forKey: "originalGrid")
        
        // Çözümü kaydet
        let solutionData = try? JSONEncoder().encode(solution)
        UserDefaults.standard.set(solutionData, forKey: "solution")
        
        // Diğer oyun durumu verilerini kaydet
        UserDefaults.standard.set(gameTime, forKey: "gameTime")
        UserDefaults.standard.set(mistakes, forKey: "mistakes")
        UserDefaults.standard.set(isGameComplete, forKey: "isGameComplete")
        
        // Değişiklikleri hemen kaydet
        UserDefaults.standard.synchronize()
    }
    
    // Oyun durumunu yükle
    private func loadGameState() -> Bool {
        // Grid'i yükle
        if let gridData = UserDefaults.standard.data(forKey: "currentGrid"),
           let loadedGrid = try? JSONDecoder().decode([[Int?]].self, from: gridData) {
            self.grid = loadedGrid
        } else {
            return false
        }
        
        // Orijinal grid'i yükle
        if let originalGridData = UserDefaults.standard.data(forKey: "originalGrid"),
           let loadedOriginalGrid = try? JSONDecoder().decode([[Int?]].self, from: originalGridData) {
            self.originalGrid = loadedOriginalGrid
        } else {
            return false
        }
        
        // Çözümü yükle
        if let solutionData = UserDefaults.standard.data(forKey: "solution"),
           let loadedSolution = try? JSONDecoder().decode([[Int]].self, from: solutionData) {
            self.solution = loadedSolution
        } else {
            return false
        }
        
        // Diğer oyun durumu verilerini yükle
        // Oyun süresini 0'dan başlat
        self.gameTime = 0
        self.mistakes = UserDefaults.standard.integer(forKey: "mistakes")
        self.isGameComplete = UserDefaults.standard.bool(forKey: "isGameComplete")
        
        return true
    }
    
    init() {
        // UserDefaults'tan zorluk seviyesini yükle
        let savedDifficulty = UserDefaults.standard.string(forKey: "difficulty") ?? Difficulty.orta.rawValue
        self.difficulty = Difficulty.allCases.first { $0.rawValue == savedDifficulty } ?? .orta
        
        // Oyun süresini sıfırla
        self.gameTime = 0
        
        // Kaydedilmiş oyun durumunu yüklemeyi dene
        if !loadGameState() {
            // Yükleme başarısız olursa yeni oyun oluştur
            generateNewGame()
        }
    }
    
    deinit {
        timer?.invalidate()
        // Çıkışta oyun durumunu kaydet
        saveGameState()
    }
    
    // Yeni oyun hazırlığı - arka planda çalıştırılacak ağır işlemler
    func prepareNewGame() {
        // Önbelleği temizle
        clearCache()
        
        // Yeni çözüm oluştur (en yoğun işlem)
        generateSolution()
        
        // NOT: UI güncellemelerini burada yapmıyoruz, finalizeNewGame'de yapılacak
    }
    
    // Yeni oyunu tamamla - UI thread'de çalıştırılacak hızlı işlemler
    func finalizeNewGame() {
        // Oyun durumunu sıfırla - UI güncellemeleri ana thread'de yapılmalı
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.selectedCell = nil
            self.isShaking = false
            self.gameTime = 0
            self.mistakes = 0
            self.isGameComplete = false
            
            // Zorluk seviyesine göre ipuçlarını belirle
            var hints: Int
            
            switch self.difficulty {
            case .kolay:
                hints = 45 // Daha fazla ipucu = daha kolay
            case .orta:
                hints = 35
            case .zor:
                hints = 25 // Daha az ipucu = daha zor
            }
            
            // Boş ızgara oluştur
            self.grid = Array(repeating: Array(repeating: nil, count: 9), count: 9)
            
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
                self.grid[pos.row][pos.col] = self.solution[pos.row][pos.col]
            }
            
            // Orijinal ızgarayı kaydet
            self.originalGrid = self.grid.map { $0.map { $0 } }
            
            // Zamanlayıcıyı yeniden başlat
            self.timer?.invalidate()
            self.startTimer()
            
            // Yeni oyun durumunu kaydet
            self.saveGameState()
        }
    }
    
    // Yeni oyun oluştur ve başlat
    func generateNewGame() {
        prepareNewGame()
        finalizeNewGame()
    }
    
    private func startTimer() {
        // ContentView'da timer kullanıldığı için burada timer başlatmıyoruz
        // Bu fonksiyon geriye dönük uyumluluk için korundu
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
    
    // Hızlı performans için isValid metodu - cache kullanarak
    func isValid(row: Int, col: Int, num: Int) -> Bool {
        let cacheKey = "\(row)-\(col)-\(num)"
        
        // Önbellekte varsa, doğrudan sonucu döndür
        if let cachedResult = validMovesCache[cacheKey] {
            return cachedResult
        }
        
        // Satırı kontrol et
        for i in 0..<9 {
            if grid[row][i] == num {
                validMovesCache[cacheKey] = false
                return false
            }
        }
        
        // Sütunu kontrol et
        for i in 0..<9 {
            if grid[i][col] == num {
                validMovesCache[cacheKey] = false
                return false
            }
        }
        
        // 3x3 bloğu kontrol et
        let boxRow = row / 3 * 3
        let boxCol = col / 3 * 3
        
        for i in 0..<3 {
            for j in 0..<3 {
                if grid[boxRow + i][boxCol + j] == num {
                    validMovesCache[cacheKey] = false
                    return false
                }
            }
        }
        
        // Geçerli hamle
        validMovesCache[cacheKey] = true
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
        var tempSolution = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        
        // Çözümü oluştur
        _ = solveSudoku(for: &tempSolution)
        
        // Ana thread'de solution değişkenini güncelle
        DispatchQueue.main.async { [weak self] in
            self?.solution = tempSolution
        }
    }
    
    private func solveSudoku(for grid: inout [[Int]]) -> Bool {
        for row in 0..<9 {
            for col in 0..<9 {
                if grid[row][col] == 0 {
                    // Rastgele sayı sırası oluştur
                    var numbers = Array(1...9)
                    numbers.shuffle()
                    
                    for num in numbers {
                        if isSafe(row: row, col: col, num: num, in: grid) {
                            grid[row][col] = num
                            
                            if solveSudoku(for: &grid) {
                                return true
                            }
                            
                            grid[row][col] = 0
                        }
                    }
                    
                    return false
                }
            }
        }
        
        return true
    }
    
    private func isSafe(row: Int, col: Int, num: Int, in grid: [[Int]]) -> Bool {
        // Satır kontrolü
        for c in 0..<9 {
            if grid[row][c] == num {
                return false
            }
        }
        
        // Sütun kontrolü
        for r in 0..<9 {
            if grid[r][col] == num {
                return false
            }
        }
        
        // Blok kontrolü
        let blockRow = (row / 3) * 3
        let blockCol = (col / 3) * 3
        
        for r in blockRow..<blockRow+3 {
            for c in blockCol..<blockCol+3 {
                if grid[r][c] == num {
                    return false
                }
            }
        }
        
        return true
    }
    
    // Oyunun tamamlanıp tamamlanmadığını kontrol et ve true/false döndür
    func checkGameCompletion() -> Bool {
        // Tüm hücreler dolu mu kontrol et
        for row in 0..<9 {
            for col in 0..<9 {
                if grid[row][col] == nil {
                    isGameComplete = false
                    return false
                }
            }
        }
        
        // Tüm satırlar, sütunlar ve bloklar geçerli mi kontrol et
        for i in 0..<9 {
            if !isValidRow(i) || !isValidColumn(i) || !isValidBlock(i / 3, i % 3) {
                isGameComplete = false
                return false
            }
        }
        
        // Oyun tamamlandı
        isGameComplete = true
        timer?.invalidate()
        return true
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
    
    func placeNumber(_ number: Int, at cell: (row: Int, col: Int)) -> Bool {
        let (row, col) = cell
        
        // Hücre düzenlenebilir mi kontrol et
        if !isCellEditable(at: row, col: col) {
            return false
        }
        
        // Geçerli bir hamle mi kontrol et
        if isValid(row: row, col: col, num: number) {
            // Animasyon için hücreyi belirle
            numberEnterAnimationCell = (row: row, col: col)
            
            // Sayıyı yerleştir
            grid[row][col] = number
            
            // Başarılı giriş animasyonu
            successfulNumberEnter = true
            
            // Oyun durumunu kaydet
            saveGameState()
            
            return true
        } else {
            // Hata animasyonu ve sayacı
            mistakes += 1
            
            // Oyun durumunu kaydet
            saveGameState()
            
            // Animasyon için gerekli değişkenleri ayarla
            numberEnterAnimationCell = (row: row, col: col)
            successfulNumberEnter = false
            
            return false
        }
    }
    
    // Periyodik kaydetme için timer
    func startAutoSave() {
        // Her 30 saniyede bir oyun durumunu kaydet
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.saveGameState()
        }
    }
    
    // Not ekle/çıkar (toggle) metodu
    func toggleNote(row: Int, col: Int, number: Int) {
        guard isCellEditable(at: row, col: col) && grid[row][col] == nil else { return }
        
        if notes[row][col].contains(number) {
            // Not zaten varsa, kaldır
            notes[row][col].removeAll { $0 == number }
        } else {
            // Not yoksa, ekle
            notes[row][col].append(number)
            
            // Sıralama için
            notes[row][col].sort()
        }
        
        // Oyun durumunu kaydet
        saveGameState()
    }
    
    // Belirli bir hücredeki notları getir
    func getNotes(row: Int, col: Int) -> [Int] {
        return notes[row][col]
    }
} 