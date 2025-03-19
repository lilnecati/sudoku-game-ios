import SwiftUI

// Etkinlik modeli
struct EventItem: Identifiable {
    let id = UUID()
    let title: String
    let date: String
    let description: String
}

struct WelcomeView: View {
    @StateObject private var gameStats = GameStats()
    @StateObject private var lifecycleManager = AppLifecycleManager()
    @StateObject private var sudokuModel = SudokuModel()
    @StateObject private var userModel = UserModel()
    @State private var isGameStarted = false
    @State private var selectedDifficulty: SudokuModel.Difficulty = .orta
    @State private var showingHowToPlay = false
    @State private var showingLogin = false
    @State private var showingProfile = false
    @State private var showingEvents = false
    @State private var timer: Timer? = nil
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @AppStorage("showWelcomeScreen") private var shouldShowWelcomeScreen: Bool = true
    
    // Animasyon için state değişkenleri
    @State private var logoScale: CGFloat = 0.8
    @State private var titleOpacity: Double = 0
    @State private var contentOpacity: Double = 0
    @State private var logoOffset: CGFloat = -50
    @State private var buttonOffset: CGFloat = 50
    
    // Tema renkleri
    private var primaryColor: Color {
        colorScheme == .dark ? Color.purple : Color.blue
    }
    
    private var secondaryColor: Color {
        colorScheme == .dark ? Color.blue : Color.purple
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Geliştirilmiş arka plan
                welcomeBackgroundView
                
                VStack(spacing: 20) {
                    // Üst bar - Giriş/Profil
                    userProfileBarView
                    
                    // Logo ve başlık
                    logoTitleView
                    
                    Spacer()
                    
                    // İçerik bölümü
                    contentSectionView
                    
                    Spacer()
                    
                    // Nasıl oynanır butonu
                    howToPlayButtonView
                    
                    Spacer()
                    
                    // Alt bilgi
                    footerView
                }
                .opacity(contentOpacity)
                .animation(.easeIn(duration: 0.8).delay(0.5), value: contentOpacity)
            }
        }
        .onAppear {
            // Animasyonları başlat
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                logoScale = 1.0
                titleOpacity = 1.0
                contentOpacity = 1.0
                logoOffset = 0
                buttonOffset = 0
            }
        }
        .onChange(of: lifecycleManager.isActive) { oldValue, newValue in
            if newValue {
                print("Uygulama aktif duruma geldi, timer'ı başlat")
                startTimer()
            } else {
                print("Uygulama arka plana geçti, timer'ı durdur")
                stopTimer()
                
                // Oyun durumunu kaydet
                sudokuModel.saveGameState()
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                profileButton
            }
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView(userModel: userModel)
        }
        .sheet(isPresented: $showingLogin) {
            LoginView(userModel: userModel)
        }
    }
    
    // Arka plan görünümü
    private var welcomeBackgroundView: some View {
        ZStack {
            // Gradient arka plan
            LinearGradient(
                gradient: Gradient(
                    colors: colorScheme == .dark ? 
                    [Color.blue.opacity(0.2), Color.purple.opacity(0.3), Color.black.opacity(0.4)] : 
                    [Color.blue.opacity(0.2), Color.purple.opacity(0.2), Color.white.opacity(0.3)]
                ),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Arka plan deseni
            gridPatternView
        }
    }
    
    // Izgara deseni
    private var gridPatternView: some View {
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
    }
    
    // Üst bar - Profil/Giriş
    private var userProfileBarView: some View {
        HStack {
            Spacer()
            
            // Kullanıcı girişi/profil butonu
            Button(action: {
                withAnimation {
                    if userModel.isLoggedIn {
                        showingProfile = true
                    } else {
                        showingLogin = true
                    }
                }
            }) {
                HStack(spacing: 5) {
                    Image(systemName: userModel.isLoggedIn ? "person.circle.fill" : "person.circle")
                        .foregroundColor(primaryColor)
                    if userModel.isLoggedIn {
                        Text(userModel.username)
                            .font(.caption)
                            .foregroundColor(primaryColor)
                    }
                }
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
        .padding(.horizontal)
        .padding(.top, 10)
        .opacity(contentOpacity)
        .animation(.easeIn(duration: 0.8).delay(0.4), value: contentOpacity)
    }
    
    // Logo ve başlık
    private var logoTitleView: some View {
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
    }
    
    // İçerik bölümü
    private var contentSectionView: some View {
        VStack(spacing: 25) {
            // Zorluk seviyesi seçimi
            difficultyPickerView
            
            // Başlat düğmesi
            startGameButtonView
        }
        .opacity(contentOpacity)
        .animation(.easeIn(duration: 0.8).delay(0.5), value: contentOpacity)
    }
    
    // Zorluk seviyesi seçici
    private var difficultyPickerView: some View {
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
    }
    
    // Başlat düğmesi
    private var startGameButtonView: some View {
        Button(action: {
            // Seçilen zorluğu UserDefaults'a kaydet
            UserDefaults.standard.set(selectedDifficulty.rawValue, forKey: "difficulty")
            
            // Bu satırı ekleyin - welcome ekranını gösterme tercihini kaydeder
            UserDefaults.standard.set(false, forKey: "showWelcomeScreen")
            
            // Oyun başlatma bildirimini gönder
            NotificationCenter.default.post(name: NSNotification.Name("StartNewGame"), object: nil)
            
            // Görünümü kapat
            dismiss()
            
            // İstatistikleri güncelle
            gameStats.incrementGamesStarted()
            gameStats.setLastPlayedDate(Date())
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
    
    // Nasıl oynanır düğmesi
    private var howToPlayButtonView: some View {
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
    }
    
    // Alt bilgi görünümü
    private var footerView: some View {
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
    
    // Profil düğmesi
    private var profileButton: some View {
        Button(action: {
            withAnimation {
                if userModel.isLoggedIn {
                    showingProfile = true
                } else {
                    showingLogin = true
                }
            }
        }) {
            HStack(spacing: 5) {
                Image(systemName: userModel.isLoggedIn ? "person.circle.fill" : "person.circle")
                    .foregroundColor(primaryColor)
                if userModel.isLoggedIn {
                    Text(userModel.username)
                        .font(.caption)
                        .foregroundColor(primaryColor)
                }
            }
        }
    }
    
    // Timer fonksiyonları
    private func startTimer() {
        // Önceki zamanlayıcıyı iptal et
        timer?.invalidate()
        
        // Yeni zamanlayıcı oluştur - 1 saniye aralıklarla
        timer = Timer(timeInterval: 1.0, repeats: true) { [self] _ in
            // SudokuModel'deki timer'ı durdur, çünkü orada da bir timer çalışıyor
            sudokuModel.stopTimer()
            // Sadece buradaki timer'ı kullan
            sudokuModel.gameTime += 1
        }
        // Ana thread'de çalıştır ve daha doğru zamanlama için common modunu kullan
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        sudokuModel.stopTimer()
    }
}

// Giriş Ekranı
struct LoginView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var userModel: UserModel
    
    @State private var inputUsername = ""
    @State private var password = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingRegister = false
    
    private var primaryColor: Color {
        colorScheme == .dark ? Color.purple : Color.blue
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Arka plan
                loginBackgroundView
                
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
                    
                    loginFormView
                    
                    Spacer()
                }
                .alert(isPresented: $showingAlert) {
                    Alert(title: Text("Hata"), message: Text(alertMessage), dismissButton: .default(Text("Tamam")))
                }
                .sheet(isPresented: $showingRegister) {
                    RegisterView(userModel: userModel, presentationMode: _presentationMode)
                }
            }
            .navigationTitle("Giriş")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(primaryColor)
                    }
                }
            }
        }
    }
    
    // Arka plan
    private var loginBackgroundView: some View {
        LinearGradient(
            gradient: Gradient(
                colors: colorScheme == .dark ? 
                [Color.blue.opacity(0.1), Color.purple.opacity(0.2), Color.black.opacity(0.3)] : 
                [Color.blue.opacity(0.1), Color.purple.opacity(0.1), Color.white.opacity(0.2)]
            ),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // Form içeriği
    private var loginFormView: some View {
        VStack(spacing: 20) {
            TextField("Kullanıcı Adı", text: $inputUsername)
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
                if inputUsername.isEmpty || password.isEmpty {
                    alertMessage = "Kullanıcı adı ve şifre boş olamaz!"
                    showingAlert = true
                } else {
                    // UserModel'in login metodunu kullan
                    if userModel.login(username: inputUsername, password: password) {
                        presentationMode.wrappedValue.dismiss()
                    } else {
                        alertMessage = "Kullanıcı adı veya şifre hatalı!"
                        showingAlert = true
                    }
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
                showingRegister = true
            }) {
                Text("Hesabınız yok mu? Kayıt olun")
                    .font(.footnote)
                    .foregroundColor(primaryColor)
            }
            .padding(.top, 10)
        }
        .padding(.horizontal, 30)
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
        EventItem(title: "Haftalık Turnuva", date: "Her Cumartesi 15:00", description: "Haftalık sudoku turnuvasına katılın ve ödüller kazanın!"),
        EventItem(title: "Yeni Başlayanlar Eğitimi", date: "Her Pazartesi 18:00", description: "Sudoku'ya yeni başlayanlar için temel stratejiler ve ipuçları."),
        EventItem(title: "Uzman Seviye Yarışma", date: "15 Haziran 2025", description: "Sadece uzman seviyedeki oyuncular için özel yarışma."),
        EventItem(title: "Sudoku Maratonu", date: "1-2 Temmuz 2025", description: "24 saat süren sudoku maratonunda dayanıklılığınızı test edin.")
    ]
    
    @State private var selectedEvent: EventItem?
    @State private var showingEventDetail = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Arka plan
                eventsBackgroundView
                
                VStack {
                    Text("Yaklaşan Etkinlikler")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(primaryColor)
                        .padding(.top, 20)
                    
                    eventsListView
                }
            }
            .navigationTitle("Etkinlikler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingEventDetail) {
                if let event = selectedEvent {
                    EventDetailView(event: event)
                }
            }
        }
    }
    
    // Arka plan
    private var eventsBackgroundView: some View {
        LinearGradient(
            gradient: Gradient(
                colors: colorScheme == .dark ? 
                [Color.blue.opacity(0.1), Color.purple.opacity(0.2), Color.black.opacity(0.3)] : 
                [Color.blue.opacity(0.1), Color.purple.opacity(0.1), Color.white.opacity(0.2)]
            ),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // Etkinlik listesi
    private var eventsListView: some View {
        List {
            ForEach(events) { event in
                eventRowView(event: event)
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    // Etkinlik satırı
    private func eventRowView(event: EventItem) -> some View {
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
                selectedEvent = event
                showingEventDetail = true
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
        .onTapGesture {
            selectedEvent = event
            showingEventDetail = true
        }
    }
}

// Etkinlik Detay Sayfası
struct EventDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    let event: EventItem
    @State private var isRegistered = false
    
    private var primaryColor: Color {
        colorScheme == .dark ? Color.purple : Color.blue
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Arka plan
                eventDetailBackgroundView
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Etkinlik başlığı ve tarihi
                        eventHeaderView
                        
                        // Etkinlik detay bilgileri
                        eventDetailInfoView
                        
                        // Katılım butonu
                        registerButtonView
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Etkinlik Detayı")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    // Arka plan
    private var eventDetailBackgroundView: some View {
        LinearGradient(
            gradient: Gradient(
                colors: colorScheme == .dark ? 
                [Color.blue.opacity(0.1), Color.purple.opacity(0.2), Color.black.opacity(0.3)] : 
                [Color.blue.opacity(0.1), Color.purple.opacity(0.1), Color.white.opacity(0.2)]
            ),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // Başlık ve tarih
    private var eventHeaderView: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Etkinlik başlığı
            Text(event.title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(primaryColor)
                .padding(.top, 20)
            
            // Etkinlik tarihi
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.secondary)
                Text(event.date)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 10)
            
            // Etkinlik açıklaması
            Text("Etkinlik Detayları")
                .font(.headline)
                .foregroundColor(primaryColor)
            
            Text(event.description)
                .font(.body)
                .foregroundColor(.primary)
                .padding(.bottom, 20)
        }
    }
    
    // Detay bilgileri
    private var eventDetailInfoView: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(primaryColor)
                Text("Konum: Online")
                    .font(.subheadline)
            }
            
            HStack {
                Image(systemName: "person.3.fill")
                    .foregroundColor(primaryColor)
                Text("Katılımcılar: 24/50")
                    .font(.subheadline)
            }
            
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(primaryColor)
                Text("Süre: 2 saat")
                    .font(.subheadline)
            }
            
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(primaryColor)
                Text("Ödül: 500 Puan")
                    .font(.subheadline)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white.opacity(0.7))
        )
        .padding(.bottom, 30)
    }
    
    // Katılım butonu
    private var registerButtonView: some View {
        Button(action: {
            isRegistered.toggle()
        }) {
            Text(isRegistered ? "Katılımı İptal Et" : "Etkinliğe Katıl")
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    LinearGradient(
                        gradient: Gradient(
                            colors: [
                                isRegistered ? Color.red : primaryColor, 
                                isRegistered ? Color.red.opacity(0.8) : primaryColor.opacity(0.8)
                            ]
                        ),
                        startPoint: .leading, 
                        endPoint: .trailing
                    )
                )
                .cornerRadius(10)
                .shadow(color: (isRegistered ? Color.red : primaryColor).opacity(0.3), radius: 5, x: 0, y: 3)
        }
        .padding(.bottom, 20)
    }
}

// Kayıt Ol Ekranı
struct RegisterView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var userModel: UserModel
    @Binding var presentationMode: PresentationMode
    
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var registrationSuccess = false
    
    private var primaryColor: Color {
        colorScheme == .dark ? Color.purple : Color.blue
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Arka plan
                registerBackgroundView
                
                ScrollView {
                    VStack(spacing: 30) {
                        Image(systemName: "person.badge.plus")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundColor(primaryColor)
                            .padding(.top, 40)
                        
                        Text("Yeni Hesap Oluştur")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(primaryColor)
                        
                        registerFormView
                        
                        Spacer().frame(height: 50)
                    }
                }
                .alert(isPresented: $showingAlert) {
                    Alert(
                        title: Text(registrationSuccess ? "Başarılı" : "Uyarı"),
                        message: Text(alertMessage),
                        dismissButton: .default(Text("Tamam")) {
                            if registrationSuccess {
                                // Kayıt başarılıysa, kayıt ekranını kapat ve giriş ekranına dön
                                self.presentationMode.dismiss()
                            }
                        }
                    )
                }
            }
            .navigationTitle("Kayıt Ol")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        self.presentationMode.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(primaryColor)
                    }
                }
            }
        }
    }
    
    // Arka plan
    private var registerBackgroundView: some View {
        LinearGradient(
            gradient: Gradient(
                colors: colorScheme == .dark ? 
                [Color.blue.opacity(0.1), Color.purple.opacity(0.2), Color.black.opacity(0.3)] : 
                [Color.blue.opacity(0.1), Color.purple.opacity(0.1), Color.white.opacity(0.2)]
            ),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // Form içeriği
    private var registerFormView: some View {
        VStack(spacing: 20) {
            TextField("Kullanıcı Adı", text: $username)
                .padding()
                .background(Color(UIColor.systemBackground))
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            
            TextField("E-posta", text: $email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding()
                .background(Color(UIColor.systemBackground))
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            
            SecureField("Şifre", text: $password)
                .padding()
                .background(Color(UIColor.systemBackground))
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            
            SecureField("Şifreyi Tekrarla", text: $confirmPassword)
                .padding()
                .background(Color(UIColor.systemBackground))
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            
            registerButtonsView
        }
        .padding(.horizontal, 30)
    }
    
    // Butonlar
    private var registerButtonsView: some View {
        VStack(spacing: 15) {
            Button(action: {
                if username.isEmpty || email.isEmpty || password.isEmpty {
                    alertMessage = "Tüm alanları doldurun!"
                    showingAlert = true
                } else if password != confirmPassword {
                    alertMessage = "Şifreler eşleşmiyor!"
                    showingAlert = true
                } else {
                    // UserModel'in register metodunu kullan
                    if userModel.register(username: username, email: email, password: password) {
                        registrationSuccess = true
                        alertMessage = "Kayıt başarılı! Giriş yapabilirsiniz."
                        showingAlert = true
                    } else {
                        alertMessage = "Kayıt sırasında bir hata oluştu!"
                        showingAlert = true
                    }
                }
            }) {
                Text("Kayıt Ol")
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
                self.presentationMode.dismiss()
            }) {
                Text("Zaten hesabınız var mı? Giriş yapın")
                    .font(.footnote)
                    .foregroundColor(primaryColor)
            }
            .padding(.top, 10)
        }
    }
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
