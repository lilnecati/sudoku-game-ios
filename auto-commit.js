const { exec } = require("child_process"); // Terminal komutlarını çalıştırmak için gerekli modül
const interval = 180000; // 3 dakikalık zaman aralığı (milisaniye cinsinden)

// Değişiklikleri kontrol eden ve commit/push işlemini yapan ana fonksiyon
function checkForChangesAndCommit() {
  console.log("Değişiklikler kontrol ediliyor...");

  // Git durumunu kontrol et
  exec("git status --porcelain", (error, stdout, stderr) => {
    if (error) {
      console.error(`Hata: ${error.message}`); // Git komutunda bir hata oluşursa logla
      return;
    }
    if (stderr) {
      console.error(`Git Hatası: ${stderr}`); // Git'in standart hata çıktısını logla
      return;
    }

    // Eğer değişiklik varsa (stdout boş değilse)
    if (stdout.trim() !== "") {
      console.log("Değişiklikler bulundu, commit ve push işlemi yapılıyor...");

      // Değişiklikleri commit ve push et
      exec("git add . && git commit -m 'Auto commit' && git push", (commitError, commitStdout, commitStderr) => {
        if (commitError) {
          console.error(`Commit Hatası: ${commitError.message}`); // Commit sırasında bir hata oluşursa logla
          return;
        }

        // Git'in push sırasında verdiği standart hata çıktısını kontrol et
        if (commitStdout.includes("To https://")) {
          console.log("Değişiklikler başarıyla uzak depoya gönderildi.");
        } else if (commitStderr) {
          console.error(`Git Commit Hatası: ${commitStderr}`); // Gerçek bir hata varsa logla
        } else {
          console.log("Başarılı: Commit ve push işlemi tamamlandı.");
        }
      });
    } else {
      console.log("Değişiklik yok, 3 dakika bekleniyor...");
    }
  });
}

// Belirtilen zaman aralığında (3 dakika) sürekli kontrol eden zamanlayıcı
setInterval(checkForChangesAndCommit, interval);

// Başlangıç mesajı
console.log("Otomatik commit ve push işlemi başlatıldı. Her 3 dakikada bir kontrol edilecek.");