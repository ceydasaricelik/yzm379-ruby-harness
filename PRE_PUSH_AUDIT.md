# GitHub öncesi YZM379 teknik denetimi

## 1. Denetim tarihi ve kapsamı

20 Kasım 2026, Türkiye saati. Başlangıç commit'i `c325e29`, dal `main`, çalışma ağacı temiz ve uzak depo tanımsızdı. Denetim yalnızca yerel projede yapıldı. A ve B yeniden çalıştırılmadı. [Başlangıç kaydı](evidence/audit/baseline.json)

**UNVERIFIED · Orijinal şartname ve puan cetveli.** Proje envanterinde hocanın şartnamesi, slaytları veya kısa sınav dosyaları bulunamadı. Aşağıdaki değerlendirme, denetim talimatında verilen maddelere dayanıyor. Resmî kriterlerin tam metni ve ağırlıkları doğrulanamadı.

## 2. İncelenen dosyalar

- **PASS · Uygulama ve test** · [Öğrenci sınıfı](lib/ogrenci.rb), [kural motoru](lib/devamsizlik_kontrol.rb), [Minitest](test/ogrenci_test.rb) ve [sürüm dosyası](.ruby-version).
- **PASS · Harness** · [AGENTS.md](AGENTS.md), [CLAUDE.md](CLAUDE.md), [bin/kontrol](bin/kontrol), [Codex ayarı](.codex/hooks.json) ve [kanca betiği](.codex/hooks/kontrol.rb).
- **PASS · Deney ve raporlama** · A'nın üç oturumu, B'nin kabuk ve kanca kayıtları, özgün B anlık görüntüsü, eski kanca denemesi, JSON ölçümleri, ratchet ve README çapraz okundu. [A](evidence/a/events.jsonl) · [B](evidence/b/events.jsonl) · [Kanca ön denemesi](evidence/ratchet/hook/kontrol.jsonl) · [Ölçümler](evidence/measurements.json) · [Ratchet](RATCHET_LOG.md) · [README](README.md)
- **PASS · Git envanteri** · İzlenen teslim dosyaları, bağlantı ve çalıştırma kipleri, satır sonu ayarı, hariç tutulan yerel Ruby/CLI ve kanca çalışma dosyaları incelendi. Başlangıçtaki en büyük izlenen dosya 16.505 bayttı. [Git kuralları](.gitignore) · [Satır sonları](.gitattributes) · [Temiz klon](evidence/audit/clean-clone.log) · [Yayın taraması](evidence/audit/publication-scan.json)

## 3. Sıfır puan riskleri

- **PASS · Ruby 3.4** · Uygulama Ruby kaynak dosyalarından çalıştı. Başlangıçta eksik olan `.ruby-version`, denenen 3.4.11 değeriyle eklendi ve Git'e alındı. [Sürüm dosyası](.ruby-version) · [Temiz klon çıktısı](evidence/audit/clean-clone.log)
- **PASS · Otomatik test** · Temiz klonda Minitest ve doğrulama komutları 9 test ve 76 doğrulamayı geçti. [Temiz klon çıktısı](evidence/audit/clean-clone.log)
- **PASS · Yasaklı Ruby davranışları** · Prism, güncel ve özgün B uygulamasında yalnızca iki uygulama türünün tanımlandığını doğruladı. AST incelemesinde bilinmeyen metot yakalayıcıları, standart sınıf açma veya dinamik sınıf değiştirme çağrısı bulunmadı. Çalışma zamanında `method_missing` sahibi `BasicObject`, durum metotlarının sahibi `Ogrenci` çıktı. [Denetim betiği](evidence/audit/recheck.rb) · [Çalıştırma çıktısı](evidence/audit/recheck.log)
- **PASS · Tam 3** · Test tablosunda 3 için doğru `riskli?`, yanlış `kaldi?` ve `:riskli` sonucu açıkça bekleniyor. Geçici eşik hatası bu testi gerçekten düşürdü. [Sınır testi](test/ogrenci_test.rb#L52) · [Geçici hata çıktısı](evidence/audit/hook/kontrol.jsonl)
- **PASS · Ratchet ve Git tutarlılığı** · Ratchet'teki A iddiaları ham olaylarla eşleşiyor. Geçmiş kanıtlarda ve özgün B kopyasında denetim başlangıcına göre fark yok. [Ratchet](RATCHET_LOG.md) · [Arşiv kontrolü](evidence/audit/archive-integrity.log)
- **PENDING · Public GitHub deposu** · Yayın bu aşamada bekliyor. [Başlangıç Git kaydı](evidence/audit/baseline.json)

## 4. 85 puan kriterleri

- **PASS · Öğrenci modeli** · Ad, üç Symbol durum ve 0–10 Integer devamsızlık doğrulandı. Geçersiz değerler `ArgumentError` verir. Sabit durum listesindeki üç `define_method` sorgusunda `respond_to?` ve durum sonuçları, bilinmeyen sorguda doğal `NoMethodError` sınandı. [Model](lib/ogrenci.rb) · [Testler](test/ogrenci_test.rb) · [Sonuç](evidence/audit/current-check.log)
- **PASS · Üç kural** · Açık öğrenci parametreli Hash/lambda kuralları kullanılır. 3 riskli, 4 ve üzeri kalmış, tam 2 yalnızca aktif öğrencide erken uyarıdır. 4'te `[:riskli, :kaldi]` birlikte döner. Risk ve kalma eşikleri üç durumda aynıdır. [Kural motoru](lib/devamsizlik_kontrol.rb) · [Eşzamanlı kural testi](test/ogrenci_test.rb#L80) · [Sonuç](evidence/audit/current-check.log)
- **PASS · Temel teslim dosyaları** · Versiyon, test, rehber, çalıştırılabilir kontrol ve sembolik bağlantı Git tarafından izleniyor. [Temiz klon metadata ve çalıştırma çıktısı](evidence/audit/clean-clone.log)

## 5. 100 puan kriterleri

- **PASS · Rehber ve sensör** · Kısa proje rehberi, sınır ve yasaklar, yürütülebilir sözdizimi ve test sensörü ile kaynak düzenlemesi sonrasında otomatik geri bildirim hazır. [AGENTS.md](AGENTS.md) · [Kanca ayarı](.codex/hooks.json) · [Canlı hata ve başarı](evidence/audit/hook/kontrol.jsonl)
- **PASS · Ratchet izlenebilirliği** · Her A gözlemi ilgili rehber, sensör ve B doğrulamasıyla bağlandı. Önleyici kurallar ayrı bölümde yer alıyor. [Ratchet](RATCHET_LOG.md)
- **PARTIAL · Karşılaştırmalı çıktı** · Aynı istem ve çalışma ayarlarıyla ayrı koşular ve sayılabilir sonuçlar doğrulandı. A uygulama üretmediği için kod kalitesi, sınır davranışı veya düzeltme sayısı üzerinden eşdeğer teslim karşılaştırması yapılamıyor. [A olayları](evidence/a/events.jsonl) · [B olayları](evidence/b/events.jsonl) · [Ölçüm kontrolü](evidence/audit/recheck.log)
- **PENDING · Yayın** · Public GitHub yayını bekliyor. Öğretim elemanının A'nın teslim üretmediği durumda deney kanıtını nasıl puanlayacağı resmî cetvel olmadan belirlenemiyor.

## 6. A koşusunun geçerliliği

- **PASS · Başlangıç ve çıktı** · Asıl A'nın ilk başarılı kabuk listelemesi (`item_2`) boş çıktı verdi. `item_3` çalışma yolunu doğruladı. Kaynak düzenleme olayı yok ve son envanter sıfır dosya gösteriyor. Ajan yoklama kaydı bulamayınca toplam ders ve devamsızlık saatlerini istedi. [Olaylar](evidence/a/events.jsonl) · [Envanter](evidence/a/snapshot.json)
- **PASS · Kullanıcı istemi ve proje kökü** · Arşivlenen model mesajı ve standart girdi yalnızca belirtilen Türkçe cümleyle birebir eşleşiyor. `project_root_markers=[]` üst dizin keşfini kapatır. `--ignore-user-config` ve `--ignore-rules` kullanıldı. [Mesaj](evidence/a/model-prompt.jsonl) · [Argümanlar](evidence/a/arguments.json) · [Çapraz doğrulama](evidence/audit/recheck.log)
- **UNVERIFIED · Global talimatların yokluğu** · Arşiv, deney anındaki global talimat dosyalarının envanterini ve modelin tam sistem bağlamını saklamıyor. Kaynaklarda üst proje kuralının aktarıldığına dair işaret bulunmadı. Başlatma argümanları yalnızca kaydedilen katmanları doğruluyor. [Koşu bağlamı](evidence/a/run-context.json) · [Argümanlar](evidence/a/arguments.json)
- **PASS · Ölçüm sınırı** · Masaüstü denemelerinden biri politika reddi, diğeri kayıtlı Core başlatma hatası verdi. Karşılaştırmada bunlardan sonra normal kabuk erişimi olan bağımsız CLI koşusu kullanıldı. Bu koşudaki tek sıfır dışı kabuk kodu, boş dizinde sonuç bulamayan `rg --files` çağrısına aitti. Tanılamalar farklı oturum kimlikleriyle arşivlendi ve ölçüme dahil edilmedi. [İlk stderr](evidence/a/initial/stderr.log) · [İkinci stderr](evidence/a/desktop-elevated/stderr.log) · [Asıl A](evidence/a/events.jsonl) · [Oturum ayrımı](evidence/audit/recheck.log)

## 7. Ratchet doğruluğu

**PASS · Gözlem ve önleyici koruma.** A'da veri işleme yorumu, kaynak kodun yokluğu ve tam %30 için `:riskli` sınıflandırmasının teslim edilmemesi gözlendi. A'da Ruby operatörü, `method_missing`, monkey patch veya farklı bir programlama dili kullanımına dair uygulama kanıtı oluşmadı. Denetim, her gözleme rehber ve sensör ekleyip B'deki karşılığıyla ilişkilendirdi. [A son mesajı ve dosya olayları](evidence/a/events.jsonl) · [Ratchet](RATCHET_LOG.md) · [Özgün B testleri](experiments/b/test/ogrenci_test.rb)

## 8. B koşusunun geçerliliği

- **PASS · Temiz başlangıç** · `lib_exists=false`. Rehber, sembolik bağlantı, test, kontrol ve iki kanca dosyasının başlangıç SHA-256 değerleri özgün B kopyasıyla eşleşti. [B ön envanteri](evidence/b/pre-run.json) · [Doğrulama](evidence/audit/recheck.log)
- **PASS · Aynı temel koşullar** · A/B kullanıcı metinleri birebir eşleşiyor. CLI çalıştırılabilir dosyası, model, `medium` akıl yürütme, onay ve sandbox ayarları aynı. B proje kancasını etkinleştirmek için proje güveni seçenekleri kullandı. [A bağlamı](evidence/a/run-context.json) · [B bağlamı](evidence/b/run-context.json) · [B argümanları](evidence/b/arguments.json)
- **PASS · Rehber okuma ve testler** · `item_9` rehber içeriğini, `item_10` iki dosya eklemesini gösteriyor. İlk doğrulama kancada, son doğrulama komutlarda gerçekleşti. Üçü de **8 test, 61 doğrulama, 0 başarısızlık** bildirdi. Kullanıcıdan ek girdi alınmadı. [B olayları](evidence/b/events.jsonl) · [B ilk kontrolü](evidence/b/kontrol.jsonl)
- **UNVERIFIED · B'de hatadan onarım** · B'nin doğrulamaları ilk seferde geçti. B'de onarım olayı oluşmadı. Ayrı denetim kanca koşusu aşağıda belgelendi. [B kanca çıktısı](evidence/b/kontrol.jsonl)

## 9. Hook doğrulaması

- **PASS · Komut ve çıkış kodları** · Temiz Windows klonunda PowerShell'den `ruby bin/kontrol`, Git Bash'ten `./bin/kontrol` başarıda 0 döndürdü. Sözdizimi bozuk bir geçici kaynak 1, Minitest eşik hatası 2 döndürdü. [Temiz klon](evidence/audit/clean-clone.log) · [Sözdizimi hatası](evidence/audit/syntax-exit.log) · [Test hatası ve başarı](evidence/audit/hook/kontrol.jsonl)
- **PASS · Yeni Windows oturumu ve ajan geri bildirimi** · Ayrı Codex oturumu temiz klondan başlatıldı. Ajan bir düzenlemede risk eşiğini geçici olarak 4'e çıkardı. `PostToolUse` kaynağı otomatik algıladı. Ajan üç Minitest hata adını ve beklenen/gerçek değerleri bildirip ayrı bir düzenlemeyle eşiği 3'e geri aldı. Kanca tekrar çalıştı ve **9 test, 76 doğrulama** geçti. Dosyanın SHA-256 değeri ve temiz Git durumu işlem sonunda yeniden doğrulandı. [Araç olayları ve ajan mesajları](evidence/audit/hook/events.jsonl) · [Kanca çıktısı](evidence/audit/hook/kontrol.jsonl) · [Geri alma](evidence/audit/hook/restoration.log)
- **PASS · Kullanım sınırı** · Rehber yeni oturumda proje ve kanca güveninin nasıl verileceğini açıklıyor. Kanca testleri otomatik tetikler. Kod düzeltmesini ajan ayrı bir araç çağrısıyla yapar. Codex dışındaki kaydetme işlemleri kendi başlarına bu olayı tetiklemez. [Kanca kurulumu](README.md#düzenleme-sonrası-kanca) · [Codex ayarı](.codex/hooks.json)

## 10. Minitest sonuçları

**PASS · 9 test, 76 doğrulama, 0 başarısızlık, 0 hata, 0 atlama.** Başlangıçtaki 8 test ve 61 doğrulama 0, 1, 2, 3, 4 ve 10 senaryolarını, aralık ve tip dışı değerleri, üç durum sorgusunu, `respond_to?` davranışını, bilinmeyen metodu ve erken uyarıyı koruyordu. Eklenen test, tüm durumlarda iki kuralın birlikte döndüğünü ve boş/tekil sonuçları sınar. Eski beklentiler korunmuştur. [Başlangıç çıktısı](evidence/audit/baseline-check.log) · [Testler](test/ogrenci_test.rb) · [Güncel sonuç](evidence/audit/current-check.log)

## 11. Token ve tur doğrulaması

- **PASS · A** · 1 CLI turu, 5 benzersiz model yanıtı, 113.116 girdi (102.016 önbellekli, 11.100 önbelleksiz) ve 350 çıktı tokenı. Toplam **113.466**. [Olaylar](evidence/a/events.jsonl) · [Kullanım](evidence/a/token-usage.jsonl)
- **PASS · B** · 1 CLI turu, 5 benzersiz model yanıtı, 122.174 girdi (109.440 önbellekli, 12.734 önbelleksiz) ve 846 çıktı tokenı. Toplam **123.020**. [Olaylar](evidence/b/events.jsonl) · [Kullanım](evidence/b/token-usage.jsonl)
- **PASS · Toplama ve fark** · Yanıt başına kullanım toplamı, son kümülatif kayıt ve CLI tur toplamıyla eşleşti. Her iki koşuda önbelleğe yazılan girdi ve akıl yürütme çıktısı 0. Önbellekli girdiler girdi toplamına dahildir. B toplamda 9.554 token (%8,42) daha fazla kullandı. Tur sayıları eşittir. Tanılama ve kanca denemelerinin kimlikleri ayrı. [Yeniden hesaplama](evidence/audit/recheck.log) · [Arşivlenen ölçümler](evidence/measurements.json)
- **UNVERIFIED · Parasal maliyet** · CLI tutar bildirmedi. `cost` iki koşuda da `null`. A'nın kod üretmemesi nedeniyle token farkı tek başına üretkenlik veya maliyet verimliliği göstergesi değildir. [Ölçümler](evidence/measurements.json)

## 12. Yapılan düzeltmeler

- **KRİTİK · PASS** · Eksik Ruby sürüm dosyası eklendi ve Git'te doğrulandı. [Sürüm](.ruby-version) · [Klon](evidence/audit/clean-clone.log)
- **YÜKSEK · PASS** · Açık parametreli Hash/lambda kuralları ve tüm eşleşmeler için API eklendi. Minitest hatasına çıkış 2 verilmesi sağlandı. [Kural motoru](lib/devamsizlik_kontrol.rb) · [Doğrulama](bin/kontrol) · [Canlı kanca](evidence/audit/hook/kontrol.jsonl)
- **ORTA · PASS** · Çoklu kural testi, Windows ve Git Bash çalıştırma adımları, kanıt çapraz doğrulaması ve özgün B ile güncel teslim ayrımı eklendi. [Test](test/ogrenci_test.rb) · [README](README.md) · [Çapraz doğrulama betiği](evidence/audit/recheck.rb)
- **DÜŞÜK · PASS** · Yerel bağlantılar ve Git kipleri kontrol edildi. Kaynak ve harness düzeltmeleri `7e9aa53` commit'inde yer alıyor. Özgün deney kayıtları, ölçümleri ve B kopyası korunuyor. [Arşiv fark kontrolü](evidence/audit/archive-integrity.log)

## 13. Açık kalan sorunlar

- **PENDING · Public GitHub yayını.** Yerel aşama tamamlandı. Uzak depoya gönderim yapılmadı.
- **PARTIAL · Yayın verisi.** Gizli anahtar ve erişim tokenı biçimlerine yönelik yerel taramada eşleşme yok. Ham çıktılar Windows kullanıcı profili yolları ve deney oturum kimlikleri içeriyor. Bunlar korunmuş deney metadata'sıdır. Public yayın bu bilgileri de görünür kılar. [Yayın taraması](evidence/audit/publication-scan.json)
- **UNVERIFIED · Resmî şartname, A'nın tam sistem bağlamı, B'de doğal hata sonrası onarım ve parasal fiyat.** Bunların kanıt sınırları ilgili bölümlerde belirtilmiştir.

## 14. GitHub öncesi teslim kararı

**PASS · Teknik olarak yerel teslim ve sonraki push için hazır.** Kod, testler, bağlantı ve kanca temiz klonda doğrulandı. [Temiz klon çıktısı](evidence/audit/clean-clone.log) · [Kanca çıktısı](evidence/audit/hook/kontrol.jsonl)

**PENDING · Public yayına geçiş.** Verilen denetim maddelerine göre teknik 0 puan riskleri giderildi ve proje yerel olarak **85 puan kategorisine aday**. Yerel harness ve kanıt maddeleri 100 puan kategorisini destekliyor. 100 puan ihtimali public yayının tamamlanmasına ve öğretim elemanının kod üretmeyen A koşusunu kabul etmesine bağlı. Resmî puan cetveli ve değerlendirme kararı doğrulanamadığı için bu bir not garantisi değildir.
