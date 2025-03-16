import SwiftUI

struct HowToPlayView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        Text("Sudoku Nasıl Oynanır?")
                            .font(.title)
                            .bold()
                        
                        Text("Sudoku, 9x9'luk bir ızgarada oynanan bir bulmaca oyunudur. Oyunun amacı, her satır, sütun ve 3x3'lük kutuda 1'den 9'a kadar olan sayıları birer kez kullanarak ızgarayı doldurmaktır.")
                    }
                    
                    Group {
                        Text("Temel Kurallar:")
                            .font(.headline)
                        
                        BulletPoint(text: "Her satırda 1-9 arası rakamlar sadece bir kez kullanılabilir")
                        BulletPoint(text: "Her sütunda 1-9 arası rakamlar sadece bir kez kullanılabilir")
                        BulletPoint(text: "Her 3x3'lük kutuda 1-9 arası rakamlar sadece bir kez kullanılabilir")
                    }
                    
                    Group {
                        Text("Nasıl Oynanır:")
                            .font(.headline)
                        
                        BulletPoint(text: "Boş bir hücre seçin")
                        BulletPoint(text: "1-9 arası bir rakam seçin")
                        BulletPoint(text: "Eğer seçtiğiniz rakam kurallara uygunsa yerleştirilir")
                        BulletPoint(text: "Yanlış bir rakam seçerseniz hata sayınız artar")
                        BulletPoint(text: "Tüm hücreleri doğru şekilde doldurduğunuzda oyunu kazanırsınız")
                    }
                    
                    Group {
                        Text("İpuçları:")
                            .font(.headline)
                        
                        BulletPoint(text: "Önce kolay olan bölümlerden başlayın")
                        BulletPoint(text: "Emin olmadığınız hücreleri geçin")
                        BulletPoint(text: "Satır, sütun ve kutuları sürekli kontrol edin")
                        BulletPoint(text: "Acele etmeyin, mantıklı düşünün")
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct BulletPoint: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text("•")
                .font(.title2)
                .padding(.trailing, 5)
            Text(text)
        }
    }
}

struct HowToPlayView_Previews: PreviewProvider {
    static var previews: some View {
        HowToPlayView()
    }
} 