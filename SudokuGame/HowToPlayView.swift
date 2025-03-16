import SwiftUI

struct HowToPlayView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTab = 0
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                // Arka plan rengi - koyu/beyaz moda göre değişir
                (colorScheme == .dark ? 
                    LinearGradient(gradient: Gradient(colors: [Color.black, Color.purple.opacity(0.2)]), startPoint: .top, endPoint: .bottom) :
                    LinearGradient(gradient: Gradient(colors: [Color.white, Color.blue.opacity(0.1)]), startPoint: .top, endPoint: .bottom))
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Üst sekme çubuğu
                    HStack(spacing: 0) {
                        TabButton(title: "Kurallar", isSelected: selectedTab == 0) {
                            withAnimation {
                                selectedTab = 0
                            }
                        }
                        
                        TabButton(title: "Nasıl Oynanır", isSelected: selectedTab == 1) {
                            withAnimation {
                                selectedTab = 1
                            }
                        }
                        
                        TabButton(title: "İpuçları", isSelected: selectedTab == 2) {
                            withAnimation {
                                selectedTab = 2
                            }
                        }
                    }
                    .padding(.top, 10)
                    
                    // İçerik alanı
                    TabView(selection: $selectedTab) {
                        RulesView()
                            .tag(0)
                        
                        HowToView()
                            .tag(1)
                        
                        TipsView()
                            .tag(2)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    
                    // Kaydırma ipucu
                    HStack {
                        Image(systemName: "arrow.right")
                        Text("Kapatmak için sağa kaydırın")
                        Image(systemName: "arrow.right")
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.bottom, 10)
                }
                .offset(x: dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if value.translation.width > 0 {
                                dragOffset = value.translation.width
                            }
                        }
                        .onEnded { value in
                            if value.translation.width > 100 {
                                dismiss()
                            } else {
                                withAnimation {
                                    dragOffset = 0
                                }
                            }
                        }
                )
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("Sudoku Rehberi")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(colorScheme == .dark ? .white : .blue)
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Kapat") {
                            dismiss()
                        }
                        .foregroundColor(colorScheme == .dark ? .purple : .blue)
                    }
                }
            }
        }
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 16, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? (colorScheme == .dark ? .white : .blue) : .gray)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                
                Rectangle()
                    .fill(isSelected ? (colorScheme == .dark ? Color.purple : Color.blue) : Color.clear)
                    .frame(height: 3)
                    .cornerRadius(1.5)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct RulesView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SectionCard(title: "Sudoku Nedir?") {
                    Text("Sudoku, 9x9'luk bir ızgarada oynanan bir bulmaca oyunudur. Oyunun amacı, her satır, sütun ve 3x3'lük kutuda 1'den 9'a kadar olan sayıları birer kez kullanarak ızgarayı doldurmaktır.")
                        .lineSpacing(4)
                }
                
                SectionCard(title: "Temel Kurallar") {
                    VStack(alignment: .leading, spacing: 12) {
                        RuleItem(text: "Her satırda 1-9 arası rakamlar sadece bir kez kullanılabilir")
                        RuleItem(text: "Her sütunda 1-9 arası rakamlar sadece bir kez kullanılabilir")
                        RuleItem(text: "Her 3x3'lük kutuda 1-9 arası rakamlar sadece bir kez kullanılabilir")
                    }
                }
                
                SectionCard(title: "Sudoku Tahtası") {
                    VStack(alignment: .center, spacing: 15) {
                        Image(systemName: "square.grid.3x3.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 120, height: 120)
                            .foregroundColor(colorScheme == .dark ? .purple.opacity(0.7) : .blue.opacity(0.7))
                            .padding()
                        
                        Text("Sudoku tahtası 9x9 hücreden oluşur ve 3x3'lük 9 bloğa bölünmüştür. Bazı hücreler başlangıçta doldurulmuştur ve bu sayılar değiştirilemez.")
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding()
        }
    }
}

struct HowToView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SectionCard(title: "Adım Adım Oynama") {
                    VStack(alignment: .leading, spacing: 15) {
                        StepItem(number: 1, text: "Boş bir hücre seçin")
                        StepItem(number: 2, text: "1-9 arası bir rakam seçin")
                        StepItem(number: 3, text: "Eğer seçtiğiniz rakam kurallara uygunsa yerleştirilir")
                        StepItem(number: 4, text: "Yanlış bir rakam seçerseniz hata sayınız artar")
                        StepItem(number: 5, text: "Tüm hücreleri doğru şekilde doldurduğunuzda oyunu kazanırsınız")
                    }
                }
                
                SectionCard(title: "Zorluk Seviyeleri") {
                    VStack(alignment: .leading, spacing: 12) {
                        DifficultyItem(level: "Kolay", description: "Daha az boş hücre, başlangıç için idealdir")
                        DifficultyItem(level: "Orta", description: "Orta seviyede zorluk, biraz düşünmenizi gerektirir")
                        DifficultyItem(level: "Zor", description: "Çok sayıda boş hücre, ileri düzey stratejiler gerektirir")
                    }
                }
                
                SectionCard(title: "Oyun Özellikleri") {
                    VStack(alignment: .leading, spacing: 12) {
                        FeatureItem(icon: "clock.fill", text: "Süre takibi - Oyunu ne kadar sürede tamamladığınızı gösterir")
                        FeatureItem(icon: "exclamationmark.triangle.fill", text: "Hata sayacı - Yaptığınız hataları sayar")
                        FeatureItem(icon: "arrow.clockwise", text: "Yeni oyun - İstediğiniz zaman yeni bir oyun başlatabilirsiniz")
                        FeatureItem(icon: "chart.bar.fill", text: "İstatistikler - Oyun performansınızı görüntüleyebilirsiniz")
                    }
                }
            }
            .padding()
        }
    }
}

struct TipsView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SectionCard(title: "Temel İpuçları") {
                    VStack(alignment: .leading, spacing: 12) {
                        TipItem(text: "Önce kolay olan bölümlerden başlayın")
                        TipItem(text: "Emin olmadığınız hücreleri geçin")
                        TipItem(text: "Satır, sütun ve kutuları sürekli kontrol edin")
                        TipItem(text: "Acele etmeyin, mantıklı düşünün")
                    }
                }
                
                SectionCard(title: "İleri Seviye Stratejiler") {
                    VStack(alignment: .leading, spacing: 15) {
                        StrategyItem(title: "Tek Olasılık", description: "Bir hücreye sadece bir rakam yerleştirilebiliyorsa, o rakamı yerleştirin")
                        StrategyItem(title: "Tek Konum", description: "Bir rakam bir satır, sütun veya kutuda sadece bir hücreye yerleştirilebiliyorsa, o rakamı yerleştirin")
                        StrategyItem(title: "İkili Eleme", description: "İki hücre aynı iki rakamı içerebiliyorsa, diğer hücrelerden bu rakamları eleyebilirsiniz")
                    }
                }
                
                SectionCard(title: "Hatalardan Kaçınma") {
                    VStack(alignment: .center, spacing: 15) {
                        Image(systemName: "lightbulb.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 60, height: 60)
                            .foregroundColor(colorScheme == .dark ? .yellow.opacity(0.7) : .yellow)
                            .padding()
                        
                        Text("Bir rakamı yerleştirmeden önce, o rakamın aynı satır, sütun veya 3x3 kutuda zaten var olup olmadığını kontrol edin. Emin olmadığınız durumlarda tahmin yapmak yerine, diğer hücrelere odaklanın.")
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding()
        }
    }
}

struct SectionCard<Content: View>: View {
    let title: String
    let content: Content
    @Environment(\.colorScheme) private var colorScheme
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(colorScheme == .dark ? .white : .primary)
            
            content
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white)
                        .shadow(color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.gray.opacity(0.2), radius: 5, x: 0, y: 3)
                )
        }
    }
}

struct RuleItem: View {
    let text: String
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(colorScheme == .dark ? .green : .green)
            
            Text(text)
                .lineSpacing(4)
                .foregroundColor(colorScheme == .dark ? .gray : .secondary)
        }
    }
}

struct StepItem: View {
    let number: Int
    let text: String
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(colorScheme == .dark ? Color.purple : Color.blue)
                )
            
            Text(text)
                .lineSpacing(4)
                .foregroundColor(colorScheme == .dark ? .gray : .secondary)
        }
    }
}

struct DifficultyItem: View {
    let level: String
    let description: String
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: difficultyIcon(for: level))
                .foregroundColor(difficultyColor(for: level))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(level)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(colorScheme == .dark ? .gray : .secondary)
                    .lineSpacing(2)
            }
        }
    }
    
    private func difficultyIcon(for level: String) -> String {
        switch level {
        case "Kolay":
            return "1.circle.fill"
        case "Orta":
            return "2.circle.fill"
        case "Zor":
            return "3.circle.fill"
        default:
            return "questionmark.circle.fill"
        }
    }
    
    private func difficultyColor(for level: String) -> Color {
        switch level {
        case "Kolay":
            return .green
        case "Orta":
            return .orange
        case "Zor":
            return .red
        default:
            return .gray
        }
    }
}

struct FeatureItem: View {
    let icon: String
    let text: String
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(colorScheme == .dark ? .purple : .blue)
            
            Text(text)
                .lineSpacing(4)
                .foregroundColor(colorScheme == .dark ? .gray : .secondary)
        }
    }
}

struct TipItem: View {
    let text: String
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.yellow)
            
            Text(text)
                .lineSpacing(4)
                .foregroundColor(colorScheme == .dark ? .gray : .secondary)
        }
    }
}

struct StrategyItem: View {
    let title: String
    let description: String
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(colorScheme == .dark ? .white : .primary)
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(colorScheme == .dark ? .gray : .secondary)
                .lineSpacing(2)
        }
        .padding(.leading, 26)
        .overlay(
            HStack {
                Image(systemName: "brain.fill")
                    .foregroundColor(colorScheme == .dark ? .purple : .blue)
                    .frame(width: 20)
                Spacer()
            }
        )
    }
}

struct BulletPoint: View {
    let text: String
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(alignment: .top) {
            Text("•")
                .font(.title2)
                .padding(.trailing, 5)
                .foregroundColor(colorScheme == .dark ? .purple : .blue)
            Text(text)
                .foregroundColor(colorScheme == .dark ? .gray : .secondary)
        }
    }
}

struct HowToPlayView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            HowToPlayView()
                .preferredColorScheme(.light)
                .previewDisplayName("Beyaz Mod")
            
            HowToPlayView()
                .preferredColorScheme(.dark)
                .previewDisplayName("Koyu Mod")
        }
    }
} 