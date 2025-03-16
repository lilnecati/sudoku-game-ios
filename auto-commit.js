const { exec } = require("child_process");
const fs = require("fs");

// 1 dakikalık zamanlayıcı (60000 ms)
const interval = 60000;

// Son commit durumunu kontrol etmek için bir değişken
let lastHash = "";

// Git komutlarını çalıştıran bir fonksiyon
function checkForChangesAndCommit() {
  console.log("Değişiklikler kontrol ediliyor...");

  // `git status --porcelain` ile değişiklikleri kontrol et
  exec("git status --porcelain", (error, stdout, stderr) => {
    if (error) {
      console.error(`Hata: ${error.message}`);
      return;
    }
    if (stderr) {
      console.error(`Git Hatası: ${stderr}`);
      return;
    }

    // Eğer değişiklik varsa stdout boş olmaz
    if (stdout.trim() !== "") {
      console.log("Değişiklikler bulundu, commit ve push işlemi yapılıyor...");

      // Değişiklikleri commit ve push et
      exec("git add . && git commit -m 'Auto commit' && git push", (commitError, commitStdout, commitStderr) => {
        if (commitError) {
          console.error(`Commit Hatası: ${commitError.message}`);
          return;
        }
        if (commitStderr) {
          console.error(`Git Commit Hatası: ${commitStderr}`);
          return;
        }
        console.log(`Başarılı: ${commitStdout}`);
      });
    } else {
      console.log("Değişiklik yok, 1 dakika bekleniyor...");
    }
  });
}

// Zamanlayıcıyı başlat
setInterval(checkForChangesAndCommit, interval);

console.log("Otomatik commit ve push işlemi başlatıldı. Her 1 dakikada bir kontrol edilecek.");