const { exec } = require("child_process");
const fs = require("fs");

const interval = 100000;

let lastHash = "";

function checkForChangesAndCommit() {
  console.log("Değişiklikler kontrol ediliyor...");
  exec("git status --porcelain", (error, stdout, stderr) => {
    if (error) {
      console.error(`Hata: ${error.message}`);
      return;
    }
    if (stderr) {
      console.error(`Git Hatası: ${stderr}`);
      return;
    }

    if (stdout.trim() !== "") {
      console.log("Değişiklikler bulundu, commit ve push işlemi yapılıyor...");

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

setInterval(checkForChangesAndCommit, interval);

console.log("Otomatik commit ve push işlemi başlatıldı. Her 1 dakikada bir kontrol edilecek.");