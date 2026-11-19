# Ratchet günlüğü

## A koşusunda gözlenenler

### Görev mevcut yoklama kayıtlarını işleme isteği olarak yorumlandı

- **Gözlem ve kanıt** · A'nın `item_0` mesajı kayıt arayacağını belirtiyor. `item_2` ve `item_3` boş çalışma klasörünü gösteriyor. `item_6` yoklama dosyası veya saatleri istiyor. Dosya değişikliği olayı yok ve son envanter sıfır dosya gösteriyor. [A olayları](evidence/a/events.jsonl) · [A envanteri](evidence/a/snapshot.json)
- **Rehber** · İki Ruby kaynak dosyasının teslim edileceği ve uygulamanın metot sözleşmesi `AGENTS.md` içinde açık olarak belirtilir. [B sırasında kullanılan rehber](experiments/b/AGENTS.md) · [Güncel rehber](AGENTS.md)
- **Sensör** · Minitest iki uygulama dosyasını yükler ve API'yi çalıştırır. Boş A anlık görüntüsünün ayrı değerlendirme kopyası `LoadError` ve çıkış 1 verdi. [Sözleşme](experiments/b/test/ogrenci_test.rb) · [A test değerlendirmesi](evidence/a/assessment.log)
- **B karşılığı ve doğrulama** · B rehberi `item_9` ile okudu, iki dosyayı `item_10` ile ekledi. Sonraki kanca ve iki test çalıştırması 8 test ve 61 doğrulamayı geçti. [B olayları](evidence/b/events.jsonl) · [B kancası](evidence/b/kontrol.jsonl)

### Tam %30 için risk sınıflandırması teslim edilmedi

- **Gözlem ve kanıt** · A'nın son mesajı %30'u aşanları ve tam %30'da olanları ayrı ayrı belirteceğini söylüyor. `:riskli` kararı açıklanmadı. Çalıştırılacak kod oluşmadığı için operatör veya eşik davranışı gözlemlenemedi. [A olayları, `item_6`](evidence/a/events.jsonl)
- **Rehber** · Tam 3'te `riskli?` doğru, `kaldi?` yanlış ve `sonuc` değeri `:riskli` olmalıdır. 4 ve üzeri için her iki sorgu doğrudur. [B rehberi](experiments/b/AGENTS.md)
- **Sensör** · Sınır matrisi 2, 3 ve 4 için iki sorguyu ve sonucu ayrı ayrı doğrular. Minitest kanca üzerinden de çalışır. [B testi](experiments/b/test/ogrenci_test.rb) · [B kanca ayarı](experiments/b/.codex/hooks.json)
- **B karşılığı ve doğrulama** · B, tam 3'ü riskli ve 4'ü kalmış olarak uyguladı. Sınır matrisi otomatik ve manuel kontrollerde geçti. [Özgün kural motoru](experiments/b/lib/devamsizlik_kontrol.rb) · [B kancası](evidence/b/kontrol.jsonl) · [B açık testleri, `item_11` ve `item_12`](evidence/b/events.jsonl)

## Önleyici kurallar

- **Öğrenci durumu ve Ruby metotları** · A'da dil, monkey patch veya dinamik bilinmeyen metot davranışı gözlemlenemedi. Rehber Ruby 3.4, stdlib ve Minitest, sabit durum listesiyle `define_method`, doğal `NoMethodError` ve monkey patch yasağını belirler. Durum ve geçersiz girdi Minitest testleri B'de geçti. Denetim özgün B ve güncel Ruby kaynaklarını Prism ile inceleyip doğal metot çözümlemesini çalışırken doğruladı. [Rehber](AGENTS.md) · [B testleri](experiments/b/test/ogrenci_test.rb) · [Prism ve çalışma zamanı çıktısı](evidence/audit/recheck.log)
- **Erken uyarı ve tüm eşleşmeler** · Rehber tam 2 devamsızlıkta yalnızca aktif öğrenci için `:erken_uyari` öngörür. B'nin Minitest'i aktif ve aktif olmayan örnekleri geçirdi. GitHub öncesi denetim açık parametreli Hash/lambda kural motorunu ve tüm eşleşmeleri döndüren API'yi ekledi. Yeni Minitest, her öğrenci durumunda 4 devamsızlığın iki kuralı birlikte döndürdüğünü doğruladı. [B testi](experiments/b/test/ogrenci_test.rb) · [Güncel test](test/ogrenci_test.rb) · [Denetim çıktısı](evidence/audit/current-check.log)
- **Düzenleme sonrası kontrol** · Sensör kaynak ve test değişikliklerinde sözdizimini ve Minitest'i çalıştırır. Ön deneyde çıkış 1 ve 0 kaydedildi. B'nin uygulama düzenlemesinde çıkış 0 kaydedildi. Sonraki denetim, Minitest hatası için çıkış 2 sözleşmesini teslim köküne ekledi. [Ön deney](evidence/ratchet/hook/kontrol.jsonl) · [B kancası](evidence/b/kontrol.jsonl) · [Güncel kanca denetimi](evidence/audit/hook/kontrol.jsonl)

## Ölçüm dışı teknik denemeler

İlk masaüstü CLI denemesinde kabuk çağrıları `blocked by policy` verdi. Yanıt tam %30'u sınır içinde tarif etti ve risk durumunu belirtmedi. İkinci denemede kabuk kayıtlı Core uygulamasını başlatamadı. Bu oturumlar tanılama amacıyla arşivlendi. Denetim sensörü, farklı oturum kimliklerine sahip olduklarını ve ölçülen A/B token kayıtlarının yalnızca kendi oturumlarından geldiğini doğruladı. [İlk olaylar](evidence/a/initial/events.jsonl) · [İlk stderr](evidence/a/initial/stderr.log) · [İkinci stderr](evidence/a/desktop-elevated/stderr.log) · [Çapraz doğrulama](evidence/audit/recheck.log)
