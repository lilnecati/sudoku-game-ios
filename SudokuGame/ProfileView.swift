import SwiftUI

struct ProfileView: View {
    @ObservedObject var userModel: UserModel
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    
    @State private var isEditing = false
    @State private var username = ""
    @State private var email = ""
    @State private var showImagePicker = false
    @State private var selectedProfileImage: String = "person.circle.fill"
    
    // Kullanıcı profil resim seçenekleri
    private let profileImageOptions = [
        "person.circle.fill", 
        "person.fill", 
        "brain.head.profile", 
        "figure.walk.circle.fill", 
        "figure.wave.circle.fill",
        "gamecontroller.fill",
        "crown.fill"
    ]
    
    private var primaryColor: Color {
        colorScheme == .dark ? Color.purple : Color.blue
    }
    
    private var formattedBestTime: String {
        let time = userModel.bestTime
        if time == 0 {
            return "Henüz yok"
        }
        
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Arka plan
                LinearGradient(gradient: Gradient(colors: colorScheme == .dark ? 
                                                 [Color.blue.opacity(0.1), Color.purple.opacity(0.2), Color.black.opacity(0.3)] : 
                                                 [Color.blue.opacity(0.1), Color.purple.opacity(0.1), Color.white.opacity(0.2)]),
                             startPoint: .topLeading,
                             endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Profil resmi
                        Image(systemName: isEditing ? selectedProfileImage : userModel.profileImageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .foregroundColor(primaryColor)
                            .background(
                                Circle()
                                    .fill(Color(UIColor.systemBackground).opacity(0.8))
                                    .frame(width: 140, height: 140)
                            )
                            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                            .padding(.top, 20)
                        
                        if isEditing {
                            // Profil resmi galerisi
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(profileImageOptions, id: \.self) { imageName in
                                        Button(action: {
                                            selectedProfileImage = imageName
                                        }) {
                                            Image(systemName: imageName)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 50, height: 50)
                                                .foregroundColor(
                                                    selectedProfileImage == imageName ? 
                                                    primaryColor : Color.gray
                                                )
                                                .padding(8)
                                                .background(
                                                    Circle()
                                                        .fill(selectedProfileImage == imageName ? 
                                                             primaryColor.opacity(0.1) : Color.clear)
                                                )
                                                .overlay(
                                                    Circle()
                                                        .stroke(selectedProfileImage == imageName ? 
                                                               primaryColor : Color.clear, lineWidth: 2)
                                                )
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // Form içeriği
                        VStack(spacing: 20) {
                            if isEditing {
                                // Düzenleme formu
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Kullanıcı Adı")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    
                                    TextField("Kullanıcı Adı", text: $username)
                                        .padding()
                                        .background(Color(UIColor.systemBackground))
                                        .cornerRadius(10)
                                        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("E-posta")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    
                                    TextField("E-posta", text: $email)
                                        .padding()
                                        .background(Color(UIColor.systemBackground))
                                        .cornerRadius(10)
                                        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
                                }
                            } else {
                                // Görüntüleme bölümü
                                ProfileInfoRow(title: "Kullanıcı Adı", value: userModel.username)
                                ProfileInfoRow(title: "E-posta", value: userModel.email)
                                
                                Divider()
                                    .padding(.vertical, 5)
                                
                                // İstatistikler
                                Text("Oyun İstatistikleri")
                                    .font(.headline)
                                    .foregroundColor(primaryColor)
                                    .padding(.top, 5)
                                
                                ProfileInfoRow(title: "Toplam Oyunlar", value: "\(userModel.totalGames)")
                                ProfileInfoRow(title: "Tamamlanan Oyunlar", value: "\(userModel.completedGames)")
                                ProfileInfoRow(title: "Tamamlanma Oranı", value: userModel.totalGames > 0 ? "\(Int(Double(userModel.completedGames) / Double(userModel.totalGames) * 100))%" : "0%")
                                ProfileInfoRow(title: "En İyi Süre", value: formattedBestTime)
                            }
                            
                            // Düğmeler
                            VStack(spacing: 12) {
                                if isEditing {
                                    Button(action: {
                                        // Profil bilgilerini kaydet
                                        userModel.updateProfile(username: username, email: email, profileImageName: selectedProfileImage)
                                        isEditing = false
                                    }) {
                                        Text("Değişiklikleri Kaydet")
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 50)
                                            .background(
                                                LinearGradient(gradient: Gradient(colors: [primaryColor, primaryColor.opacity(0.8)]),
                                                             startPoint: .leading, endPoint: .trailing)
                                            )
                                            .cornerRadius(10)
                                            .shadow(color: primaryColor.opacity(0.3), radius: 5, x: 0, y: 3)
                                    }
                                    
                                    Button(action: {
                                        // Düzenleme modundan çık
                                        isEditing = false
                                        username = userModel.username
                                        email = userModel.email
                                        selectedProfileImage = userModel.profileImageName
                                    }) {
                                        Text("İptal Et")
                                            .fontWeight(.medium)
                                            .foregroundColor(.gray)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 50)
                                            .background(Color(UIColor.systemBackground))
                                            .cornerRadius(10)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                            )
                                    }
                                } else {
                                    Button(action: {
                                        // Düzenleme moduna geç
                                        isEditing = true
                                        username = userModel.username
                                        email = userModel.email
                                        selectedProfileImage = userModel.profileImageName
                                    }) {
                                        Text("Profili Düzenle")
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 50)
                                            .background(
                                                LinearGradient(gradient: Gradient(colors: [primaryColor, primaryColor.opacity(0.8)]),
                                                             startPoint: .leading, endPoint: .trailing)
                                            )
                                            .cornerRadius(10)
                                            .shadow(color: primaryColor.opacity(0.3), radius: 5, x: 0, y: 3)
                                    }
                                    
                                    Button(action: {
                                        // Çıkış yap
                                        userModel.logout()
                                        presentationMode.wrappedValue.dismiss()
                                    }) {
                                        Text("Çıkış Yap")
                                            .fontWeight(.medium)
                                            .foregroundColor(.red)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 50)
                                            .background(Color(UIColor.systemBackground))
                                            .cornerRadius(10)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(Color.red.opacity(0.5), lineWidth: 1)
                                            )
                                    }
                                }
                            }
                            .padding(.top, 10)
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(primaryColor)
                    }
                }
            }
        }
    }
}

// Profil bilgi satırı bileşeni
struct ProfileInfoRow: View {
    var title: String
    var value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(UIColor.label))
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    let userModel = UserModel()
    userModel.username = "sudokumeister"
    userModel.email = "kullanici@örnek.com"
    userModel.totalGames = 42
    userModel.completedGames = 38
    userModel.bestTime = 247
    
    return ProfileView(userModel: userModel)
} 