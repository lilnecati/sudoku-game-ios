import SwiftUI

struct Event: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let date: Date
    let imageSystemName: String
}

struct EventsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    private var primaryColor: Color {
        colorScheme == .dark ? Color.purple : Color.blue
    }
    
    // Örnek etkinlikler
    private let events = [
        Event(
            title: "Sudoku Turnuvası",
            description: "Aylık Sudoku turnuvasına katılın ve ödüller kazanın! Tüm zorluk seviyelerinde yarışmalar olacak.",
            date: Calendar.current.date(byAdding: .day, value: 5, to: Date())!,
            imageSystemName: "trophy.fill"
        ),
        Event(
            title: "Yeni Zorluk Seviyesi",
            description: "Çok yakında 'Uzman' zorluk seviyesi geliyor! Kendinizi en zorlu Sudoku bulmacalarıyla test edin.",
            date: Calendar.current.date(byAdding: .day, value: 10, to: Date())!,
            imageSystemName: "star.fill"
        ),
        Event(
            title: "Günlük Meydan Okuma",
            description: "Her gün yeni bir Sudoku meydan okuması ile becerilerinizi geliştirin ve ödüller kazanın.",
            date: Date(),
            imageSystemName: "calendar.badge.clock"
        )
    ]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(events) { event in
                    EventRow(event: event, primaryColor: primaryColor)
                }
            }
            .navigationTitle("Etkinlikler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
            }
            .background(
                colorScheme == .dark ? Color.black : Color.white
            )
        }
    }
}

struct EventRow: View {
    let event: Event
    let primaryColor: Color
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: event.imageSystemName)
                    .font(.system(size: 24))
                    .foregroundColor(primaryColor)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(primaryColor.opacity(0.2))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.headline)
                        .foregroundColor(primaryColor)
                    
                    Text(dateFormatter.string(from: event.date))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            
            Text(event.description)
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(3)
                .padding(.leading, 4)
            
            // Katıl butonu
            Button(action: {
                // Etkinliğe katılma işlemi
            }) {
                Text("Katıl")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(primaryColor)
                    )
            }
            .padding(.top, 5)
            .padding(.bottom, 5)
        }
        .padding(.vertical, 8)
    }
} 