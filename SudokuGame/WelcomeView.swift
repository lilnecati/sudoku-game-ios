import SwiftUI

struct WelcomeView: View {
    @State private var isGameStarted = false
    @State private var selectedDifficulty: SudokuModel.Difficulty = .medium
    @State private var showingHowToPlay = false
    @State private var showingLogin = false
    @State private var showingEvents = false
    @State private var isLoggedIn = false
    @State private var username = ""
    @Environment(\.colorScheme) private var colorScheme
    
    // Animasyon için state değişkenleri
    @State private var logoScale: CGFloat = 0.8
    @State private var titleOpacity: Double = 0
    @State private var contentOpacity: Double = 0
    @State private var buttonOffset: CGFloat = 100
    
    // Tema renkleri
    private var primaryColor: Color {
        colorScheme == .dark ? Color.purple : Color.blue
    }
    
    private var secondaryColor: Color {
        colorScheme == .dark ? Color.blue : Color.purple
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Geliştirilmiş arka plan gradyanı
                LinearGradient(gradient: Gradient(colors: colorScheme == .dark ? 
                                                 [Color.blue.opacity(0.2), Color.purple.opacity(0.3), Color.black.opacity(0.4)] : 
                                                 [Color.blue.opacity(0.2), Color.purple.opacity(0.2), Color.white.opacity(0.3)]),
                             startPoint: .topLeading,
                             endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                // Arka plan deseni
                ZStack {
                    ForEach(0..<9) { row in
                        ForEach(0..<9) { col in
                            Rectangle()
                                .stroke(primaryColor.opacity(0.1), lineWidth: 1)
                                .frame(width: UIScreen.main.bounds.width / 9, height: UIScreen.main.bounds.width / 9)
                                .offset(x: CGFloat(col - 4) * UIScreen.main.bounds.width / 9,
                                        y: CGFloat(row - 4) * UIScreen.main.bounds.width / 9)
                        }
                    }
                }
                .rotationEffect(.degrees(15))
                .opacity(0.5)
                
                VStack(spacing: 20) {
                    // Üst bar - Giriş/Profil ve Etkinlikler
                    HStack {
                        Spacer()
                        
                        // Kullanıcı girişi/profil butonu
                        Button(action: {
                            showingLogin = true
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: isLoggedIn ? "person.fill" : "person")
                                    .font(.system(size: 16, weight: .semibold))
                                Text(isLoggedIn ? username : "Giriş Yap")
                                    .font(.subheadline)
                            }
                            .foregroundColor(primaryColor)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                Capsule()
                                    .stroke(primaryColor, lineWidth: 1.5)
                                    .background(
                                        Capsule()
                                            .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white.opacity(0.7))
                                    )
                            )
                        }
                        .sheet(isPresented: $showingLogin) {
                            LoginView(isLoggedIn: $isLoggedIn, username: $username)
                        }
                        
                        Spacer().frame(width: 10)
                        
                        // Etkinlikler butonu
                        Button(action: {
                            showingEvents = true
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Etkinlikler")
                                    .font(.subheadline)
                            }
                            .foregroundColor(primaryColor)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                Capsule()
                                    .stroke(primaryColor, lineWidth: 1.5)
                                    .background(
                                        Capsule()
                                            .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white.opacity(0.7))
                                    )
                            )
                        }
                        .sheet(isPresented: $showingEvents) {
                            EventsView()
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .opacity(contentOpacity)
                    .animation(.easeIn(duration: 0.8).delay(0.4), value: contentOpacity)
                    
                    // Logo ve başlık
                    VStack(spacing: 20) {
                        Image(systemName: "grid.circle.fill")
                            .resizable()
                            .frame(width: 120, height: 120)
                            .foregroundColor(primaryColor)
                            .background(
                                Circle()
                                    .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white.opacity(0.7))
                                    .frame(width: 140, height: 140)
                            )
                            .shadow(color: primaryColor.opacity(0.5), radius: 10, x: 0, y: 5)
                            .scaleEffect(logoScale)
                            .animation(.spring(response: 0.6, dampingFraction: 0.6), value: logoScale)
                        
                        Text("SUDOKU")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundColor(primaryColor)
                            .opacity(titleOpacity)
                            .animation(.easeIn(duration: 0.8).delay(0.3), value: titleOpacity)
                    }
                    .padding(.top, 20)
                    
                    Spacer()
                    
                    // İçerik bölümü
                    VStack(spacing: 25) {
                        // Zorluk seviyesi seçimi
                        VStack(spacing: 15) {
                            Text("Zorluk Seviyesi")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Picker("Zorluk", selection: $selectedDifficulty) {
                                ForEach(SudokuModel.Difficulty.allCases, id: \.self) { level in
                                    Text(level.rawValue)
                                        .tag(level)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding(.horizontal)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white.opacity(0.7))
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        )
                        .padding(.horizontal)
                        
                        // Oyuna başla butonu
                        NavigationLink(destination: ContentView()
                            .navigationBarBackButtonHidden(true), isActive: $isGameStarted) {
                                Button(action: {
                                    withAnimation {
                                        isGameStarted = true
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "play.fill")
                                            .font(.headline)
                                        Text("OYUNA BAŞLA")
                                            .font(.headline)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 60)
                                    .background(
                                        LinearGradient(gradient: Gradient(colors: [primaryColor, secondaryColor]),
                                                     startPoint: .leading, endPoint: .trailing)
                                    )
                                    .cornerRadius(15)
                                    .shadow(color: primaryColor.opacity(0.5), radius: 5, x: 0, y: 3)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 15)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                    )
                                }
                                .padding(.horizontal, 30)
                                .offset(y: buttonOffset)
                                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: buttonOffset)
                        }
                        
                        // Nasıl oynanır butonu
                        Button(action: {
                            showingHowToPlay = true
                        }) {
                            HStack {
                                Image(systemName: "questionmark.circle")
                                Text("Nasıl Oynanır?")
                            }
                            .font(.subheadline)
                            .foregroundColor(primaryColor)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(primaryColor, lineWidth: 1.5)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(colorScheme == .dark ? Color.black.opacity(0.2) : Color.white.opacity(0.7))
                                    )
                            )
                        }
                        .padding(.top, 5)
                        .sheet(isPresented: $showingHowToPlay) {
                            HowToPlayView()
                        }
                        .offset(y: buttonOffset)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3), value: buttonOffset)
                    }
                    .opacity(contentOpacity)
                    .animation(.easeIn(duration: 0.8).delay(0.5), value: contentOpacity)
                    
                    Spacer()
                    
                    // Alt bilgi
                    VStack(spacing: 5) {
                        Text("Sudoku Oyunu v1.0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("© 2025 Necati Yıldırım")
                            .font(.caption2)
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                    .padding(.bottom, 20)
                    .opacity(contentOpacity)
                    .animation(.easeIn(duration: 0.8).delay(0.7), value: contentOpacity)
                }
            }
            .onAppear {
                // Animasyonları başlat
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    logoScale = 1.0
                    titleOpacity = 1.0
                    contentOpacity = 1.0
                    buttonOffset = 0
                }
            }
        }
        .preferredColorScheme(colorScheme)
    }
}

// Giriş Ekranı
struct LoginView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @Binding var isLoggedIn: Bool
    @Binding var username: String
    
    @State private var password = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    private var primaryColor: Color {
        colorScheme == .dark ? Color.purple : Color.blue
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Arka plan
                LinearGradient(gradient: Gradient(colors: colorScheme == .dark ? 
                                                 [Color.blue.opacity(0.1), Color.purple.opacity(0.2), Color.black.opacity(0.3)] : 
                                                 [Color.blue.opacity(0.1), Color.purple.opacity(0.1), Color.white.opacity(0.2)]),
                             startPoint: .topLeading,
                             endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundColor(primaryColor)
                        .padding(.top, 40)
                    
                    Text("Hesabınıza Giriş Yapın")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(primaryColor)
                    
                    VStack(spacing: 20) {
                        TextField("Kullanıcı Adı", text: $username)
                            .padding()
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        
                        SecureField("Şifre", text: $password)
                            .padding()
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        
                        Button(action: {
                            if username.isEmpty || password.isEmpty {
                                alertMessage = "Kullanıcı adı ve şifre boş olamaz!"
                                showingAlert = true
                            } else {
                                // Gerçek uygulamada burada API çağrısı yapılır
                                isLoggedIn = true
                                presentationMode.wrappedValue.dismiss()
                            }
                        }) {
                            Text("Giriş Yap")
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
                            // Kayıt işlemi
                        }) {
                            Text("Hesabınız yok mu? Kayıt olun")
                                .font(.footnote)
                                .foregroundColor(primaryColor)
                        }
                        .padding(.top, 10)
                    }
                    .padding(.horizontal, 30)
                    
                    Spacer()
                }
                .padding(.vertical)
                .alert(isPresented: $showingAlert) {
                    Alert(title: Text("Hata"), message: Text(alertMessage), dismissButton: .default(Text("Tamam")))
                }
            }
            .navigationBarTitle("Giriş", displayMode: .inline)
            .navigationBarItems(trailing: Button("Kapat") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// Etkinlikler Ekranı
struct EventsView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    private var primaryColor: Color {
        colorScheme == .dark ? Color.purple : Color.blue
    }
    
    // Örnek etkinlikler
    private let events = [
        Event(title: "Haftalık Turnuva", date: "Her Cumartesi 15:00", description: "Haftalık sudoku turnuvasına katılın ve ödüller kazanın!"),
        Event(title: "Yeni Başlayanlar Eğitimi", date: "Her Pazartesi 18:00", description: "Sudoku'ya yeni başlayanlar için temel stratejiler ve ipuçları."),
        Event(title: "Uzman Seviye Yarışma", date: "15 Haziran 2025", description: "Sadece uzman seviyedeki oyuncular için özel yarışma."),
        Event(title: "Sudoku Maratonu", date: "1-2 Temmuz 2025", description: "24 saat süren sudoku maratonunda dayanıklılığınızı test edin.")
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Arka plan
                LinearGradient(gradient: Gradient(colors: colorScheme == .dark ? 
                                                 [Color.blue.opacity(0.1), Color.purple.opacity(0.2), Color.black.opacity(0.3)] : 
                                                 [Color.blue.opacity(0.1), Color.purple.opacity(0.1), Color.white.opacity(0.2)]),
                             startPoint: .topLeading,
                             endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                VStack {
                    Text("Yaklaşan Etkinlikler")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(primaryColor)
                        .padding(.top, 20)
                    
                    List {
                        ForEach(events) { event in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(event.title)
                                    .font(.headline)
                                    .foregroundColor(primaryColor)
                                
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundColor(.secondary)
                                    Text(event.date)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Text(event.description)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                    .padding(.top, 2)
                                
                                Button(action: {
                                    // Etkinliğe katılma işlemi
                                }) {
                                    Text("Katıl")
                                        .font(.footnote)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 8)
                                        .background(primaryColor)
                                        .cornerRadius(20)
                                }
                                .padding(.top, 5)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationBarTitle("Etkinlikler", displayMode: .inline)
            .navigationBarItems(trailing: Button("Kapat") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// Etkinlik modeli
struct Event: Identifiable {
    let id = UUID()
    let title: String
    let date: String
    let description: String
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            WelcomeView()
                .preferredColorScheme(.light)
                .previewDisplayName("Beyaz Mod")
            
            WelcomeView()
                .preferredColorScheme(.dark)
                .previewDisplayName("Koyu Mod")
        }
    }
} 