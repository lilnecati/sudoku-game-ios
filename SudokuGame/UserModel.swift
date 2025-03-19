import Foundation
import SwiftUI
import Combine

class UserModel: ObservableObject {
    // Yayınlanan özellikler
    @Published var isLoggedIn: Bool = false
    @Published var username: String = ""
    @Published var email: String = ""
    @Published var profileImageName: String = "person.circle.fill"
    @Published var totalGames: Int = 0
    @Published var completedGames: Int = 0
    @Published var bestTime: TimeInterval = 0
    
    // UserDefaults anahtarları
    private let isLoggedInKey = "isLoggedIn"
    private let usernameKey = "username"
    private let emailKey = "email"
    private let profileImageNameKey = "profileImageName"
    private let passwordKey = "password" // Gerçek uygulamada şifreyi güvenli bir şekilde saklamalısınız
    private let totalGamesKey = "totalGames"
    private let completedGamesKey = "completedGames"
    private let bestTimeKey = "bestTime"
    
    init() {
        // UserDefaults'dan kullanıcı verilerini yükle
        loadUserData()
    }
    
    // Kullanıcı verilerini UserDefaults'dan yükleme
    private func loadUserData() {
        isLoggedIn = UserDefaults.standard.bool(forKey: isLoggedInKey)
        username = UserDefaults.standard.string(forKey: usernameKey) ?? ""
        email = UserDefaults.standard.string(forKey: emailKey) ?? ""
        profileImageName = UserDefaults.standard.string(forKey: profileImageNameKey) ?? "person.circle.fill"
        totalGames = UserDefaults.standard.integer(forKey: totalGamesKey)
        completedGames = UserDefaults.standard.integer(forKey: completedGamesKey)
        bestTime = UserDefaults.standard.double(forKey: bestTimeKey)
    }
    
    // Kullanıcı oturum açma
    func login(username: String, password: String) -> Bool {
        // Bu basit bir demo için. Gerçek uygulamada API ile doğrulama yapmalısınız.
        let savedUsername = UserDefaults.standard.string(forKey: usernameKey)
        let savedPassword = UserDefaults.standard.string(forKey: passwordKey)
        
        if username == savedUsername && password == savedPassword {
            self.isLoggedIn = true
            self.username = username
            
            UserDefaults.standard.set(true, forKey: isLoggedInKey)
            UserDefaults.standard.synchronize()
            return true
        }
        return false
    }
    
    // Yeni kullanıcı kayıt olma
    func register(username: String, email: String, password: String) -> Bool {
        // Gerçek uygulama bu bilgileri bir API'ye gönderir
        self.username = username
        self.email = email
        self.isLoggedIn = true
        
        UserDefaults.standard.set(username, forKey: usernameKey)
        UserDefaults.standard.set(email, forKey: emailKey)
        UserDefaults.standard.set(password, forKey: passwordKey)
        UserDefaults.standard.set(true, forKey: isLoggedInKey)
        UserDefaults.standard.synchronize()
        
        return true
    }
    
    // Kullanıcı oturumu kapatma
    func logout() {
        isLoggedIn = false
        UserDefaults.standard.set(false, forKey: isLoggedInKey)
        UserDefaults.standard.synchronize()
    }
    
    // Kullanıcı profilini güncelleme
    func updateProfile(username: String, email: String, profileImageName: String) {
        self.username = username
        self.email = email
        self.profileImageName = profileImageName
        
        UserDefaults.standard.set(username, forKey: usernameKey)
        UserDefaults.standard.set(email, forKey: emailKey)
        UserDefaults.standard.set(profileImageName, forKey: profileImageNameKey)
        UserDefaults.standard.synchronize()
    }
    
    // Oyun istatistiklerini güncelleme
    func updateGameStats(gameCompleted: Bool, gameTime: TimeInterval) {
        totalGames += 1
        if gameCompleted {
            completedGames += 1
            
            // En iyi süreyi güncelle
            if bestTime == 0 || gameTime < bestTime {
                bestTime = gameTime
            }
        }
        
        UserDefaults.standard.set(totalGames, forKey: totalGamesKey)
        UserDefaults.standard.set(completedGames, forKey: completedGamesKey)
        UserDefaults.standard.set(bestTime, forKey: bestTimeKey)
        UserDefaults.standard.synchronize()
    }
} 