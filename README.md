# Sudoku Oyunu

Modern ve kullanıcı dostu arayüze sahip bir Sudoku oyunu uygulaması.

## Özellikler

- Farklı zorluk seviyelerinde Sudoku bulmacaları (Kolay, Orta, Zor)
- Kullanıcı hesabı oluşturma ve giriş yapma
- Etkinlikler sayfası ve turnuvalara katılım
- Nasıl oynanır rehberi
- Hem açık hem de koyu tema desteği
- Özelleştirilebilir renk temaları
- Animasyonlu kullanıcı arayüzü
- Oyun süresi takibi ve istatistikler
- Otomatik kaydetme özelliği
- Notlar alma ve işaretleme sistemi
- Hata kontrolü ve ipucu sistemi
- UserDefaults ile ayarların kaydedilmesi

## Ekran Görüntüleri

- Ana Sayfa
- Oyun Ekranı
- Giriş Sayfası
- Kayıt Ol Sayfası
- Etkinlikler Sayfası
- Ayarlar Sayfası

## Nasıl Oynanır

Sudoku, 9x9'luk bir ızgarada oynanan bir sayı bulmaca oyunudur. Amaç, her satır, her sütun ve her 3x3'lük kutuda 1'den 9'a kadar olan sayıları birer kez kullanarak ızgarayı doldurmaktır.

1. Boş bir hücreye dokunun
2. Sayı seçin
3. Tüm hücreler doğru şekilde doldurulduğunda oyun tamamlanır

### İpuçları

- Önce kolay olan hücreleri doldurun
- Eleme yöntemini kullanın: bir sayının nereye gidebileceğini belirlemek için satır, sütun ve kutuları kontrol edin
- Not alma özelliğini kullanarak olası sayıları işaretleyin
- Çok zorlandığınızda ipucu sistemini kullanabilirsiniz

## Geliştirme

Bu uygulama SwiftUI kullanılarak geliştirilmiştir ve iOS 14.0 ve üzeri sürümlerde çalışır.

### Gereksinimler

- iOS 14.0+
- Xcode 12.0+
- Swift 5.3+

### Kullanılan Teknolojiler

- SwiftUI
- Combine
- UserDefaults
- Core Animation
- Core Graphics

### Kurulum

1. Projeyi klonlayın:
```
git clone https://github.com/lilnecati/SudokuGame.git
```

2. Xcode ile SudokuGame.xcodeproj dosyasını açın

3. Uygulamayı bir simülatörde veya gerçek cihazda çalıştırın

## Mimari

Uygulama MVVM (Model-View-ViewModel) mimarisi kullanılarak geliştirilmiştir:

- **Model**: Oyun verilerini ve mantığını içerir
- **View**: Kullanıcı arayüzünü oluşturur
- **ViewModel**: Model ve View arasında köprü görevi görür

## Gelecek Özellikler

- Çevrimiçi çok oyunculu mod
- Günlük meydan okumalar
- Liderlik tablosu
- Daha fazla tema seçeneği
- Gelişmiş ipucu sistemi
- Bulmaca oluşturucu
- Oyun içi başarılar
- iCloud senkronizasyonu

## Sorun Giderme

- **Uygulama açılmıyor**: Cihazınızın iOS 14.0 veya üzeri sürümü çalıştırdığından emin olun
- **Oyun kaydedilmiyor**: Cihazınızda yeterli depolama alanı olduğunu kontrol edin
- **Performans sorunları**: Arka planda çalışan uygulamaları kapatmayı deneyin

## İletişim

Necati Yıldırım  

Proje Bağlantısı: 

## Lisans

Bu proje MIT lisansı altında lisanslanmıştır - detaylar için [LICENSE](LICENSE) dosyasına bakın. 