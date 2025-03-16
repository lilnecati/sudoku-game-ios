import SwiftUI

struct LoginView: View {
    @Binding var isLoggedIn: Bool
    @Binding var username: String
    @State private var password: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    private var primaryColor: Color {
        colorScheme == .dark ? Color.purple : Color.blue
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 25) {
                // Logo
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(primaryColor)
                    .padding(.top, 30)
                
                Text("Kullanıcı Girişi")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(primaryColor)
                
                VStack(spacing: 20) {
                    // Kullanıcı adı alanı
                    TextField("Kullanıcı Adı", text: $username)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white)
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(primaryColor.opacity(0.5), lineWidth: 1)
                        )
                    
                    // Şifre alanı
                    SecureField("Şifre", text: $password)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white)
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(primaryColor.opacity(0.5), lineWidth: 1)
                        )
                }
                .padding(.horizontal, 30)
                .padding(.top, 20)
                
                // Giriş butonu
                Button(action: {
                    login()
                }) {
                    Text("Giriş Yap")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 55)
                        .background(
                            LinearGradient(gradient: Gradient(colors: [primaryColor, primaryColor.opacity(0.8)]),
                                          startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(10)
                        .shadow(color: primaryColor.opacity(0.5), radius: 5, x: 0, y: 3)
                }
                .padding(.horizontal, 30)
                .padding(.top, 20)
                
                // Misafir olarak devam et
                Button(action: {
                    loginAsGuest()
                }) {
                    Text("Misafir Olarak Devam Et")
                        .font(.subheadline)
                        .foregroundColor(primaryColor)
                        .padding(.top, 15)
                }
                
                Spacer()
            }
            .padding()
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("Bilgi"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("Tamam"))
                )
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
            }
            .navigationTitle("Giriş")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func login() {
        // Basit bir doğrulama - gerçek uygulamada daha güvenli bir yöntem kullanılmalı
        if username.isEmpty || password.isEmpty {
            alertMessage = "Kullanıcı adı ve şifre boş olamaz."
            showingAlert = true
            return
        }
        
        // Demo amaçlı basit bir giriş kontrolü
        if username == "admin" && password == "1234" {
            isLoggedIn = true
            dismiss()
        } else {
            alertMessage = "Kullanıcı adı veya şifre hatalı."
            showingAlert = true
        }
    }
    
    private func loginAsGuest() {
        username = "Misafir"
        isLoggedIn = true
        dismiss()
    }
} 