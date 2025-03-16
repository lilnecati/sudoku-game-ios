import Foundation

class GameStats: ObservableObject {
    @Published var gamesStarted: Int = UserDefaults.standard.integer(forKey: "gamesStarted")
    @Published var gamesCompleted: Int = UserDefaults.standard.integer(forKey: "gamesCompleted")
    @Published var totalPlayTime: TimeInterval = UserDefaults.standard.double(forKey: "totalPlayTime")
    @Published var lastPlayedDate: Date? = UserDefaults.standard.object(forKey: "lastPlayedDate") as? Date
    
    func incrementGamesStarted() {
        gamesStarted += 1
        UserDefaults.standard.set(gamesStarted, forKey: "gamesStarted")
    }
    
    func incrementGamesCompleted() {
        gamesCompleted += 1
        UserDefaults.standard.set(gamesCompleted, forKey: "gamesCompleted")
    }
    
    func addPlayTime(_ time: TimeInterval) {
        totalPlayTime += time
        UserDefaults.standard.set(totalPlayTime, forKey: "totalPlayTime")
    }
    
    func setLastPlayedDate(_ date: Date) {
        lastPlayedDate = date
        UserDefaults.standard.set(date, forKey: "lastPlayedDate")
    }
    
    func resetStats() {
        gamesStarted = 0
        gamesCompleted = 0
        totalPlayTime = 0
        lastPlayedDate = nil
        
        UserDefaults.standard.removeObject(forKey: "gamesStarted")
        UserDefaults.standard.removeObject(forKey: "gamesCompleted")
        UserDefaults.standard.removeObject(forKey: "totalPlayTime")
        UserDefaults.standard.removeObject(forKey: "lastPlayedDate")
    }
} 