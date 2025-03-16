import SwiftUI

struct WelcomeView: View {
    @State private var isGameStarted = false
    @State private var selectedDifficulty: SudokuModel.Difficulty = .medium
    @State private var showingHowToPlay = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
            ZStack {
                // Arka plan gradyanı - koyu/beyaz moda göre değişir
                LinearGradient(gradient: Gradient(colors: colorScheme == .dark ? 
                                                 [Color.blue.opacity(0.2), Color.purple.opacity(0.2)] : 
                                                 [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]),
                             startPoint: .topLeading,
                             endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Logo ve başlık
                    VStack(spacing: 20) {
                        Image(systemName: "grid.circle.fill")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .foregroundColor(colorScheme == .dark ? .white : .blue)
                        
                        Text("Sudoku")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    .padding(.top, 50)
                    
                    Spacer()
                    
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
                    .background(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white.opacity(0.7))
                    .cornerRadius(15)
                    .padding(.horizontal)
                    
                    // Oyuna başla butonu
                    NavigationLink(destination: ContentView()
                        .navigationBarBackButtonHidden(true), isActive: $isGameStarted) {
                            Button(action: {
                                isGameStarted = true
                            }) {
                                HStack {
                                    Image(systemName: "play.fill")
                                    Text("Oyuna Başla")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 55)
                                .background(colorScheme == .dark ? Color.purple : Color.blue)
                                .cornerRadius(15)
                                .shadow(radius: 5)
                            }
                    }
                    .padding(.horizontal, 30)
                    
                    // Nasıl oynanır butonu
                    Button(action: {
                        showingHowToPlay = true
                    }) {
                        Text("Nasıl Oynanır?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white.opacity(0.7))
                            .cornerRadius(10)
                    }
                    .padding(.top)
                    .sheet(isPresented: $showingHowToPlay) {
                        HowToPlayView()
                    }
                    
                    Spacer()
                    
                    // Alt bilgi
                    VStack(spacing: 5) {
                        Text("Sudoku Oyunu v1.0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .preferredColorScheme(colorScheme)
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