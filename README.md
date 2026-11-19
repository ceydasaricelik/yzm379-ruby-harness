# YZM379 Ruby Harness

Teslim tarihi 20 Kasım 2026, 23:59 (Türkiye saati).

## Kurulum ve doğrulama

Ruby 3.4 ve Minitest gerekir. Bu teslim Ruby 3.4.11, Minitest 5.25.4, Git 2.56.0 ve Codex CLI 0.169.1 ile doğrulandı. Minitest kurulumunuzda yoksa `gem install minitest -v 5.25.4` komutuyla ekleyin. Uygulama başka bir gem gerektirmez. [Ortam çıktısı](evidence/ratchet/environment.log) · [RubyInstaller arşivleri](https://rubyinstaller.org/downloads/archives/)

Bu Windows çalışma alanında kurulan taşınabilir Ruby'yi kullanmak için proje kökünde şu komutları çalıştırın. `.runtime/` yerel kurulum dizinidir ve Git'e dahil değildir.

```powershell
$env:PATH = (Resolve-Path .runtime/rubyinstaller-3.4.11-1-x64/bin).Path + ';' + $env:PATH
Remove-Item Env:GEM_HOME, Env:GEM_PATH -ErrorAction SilentlyContinue
ruby -v
```

Proje kökünden Minitest'i doğrudan ve sözdizimi denetimiyle birlikte çalıştırabilirsiniz. `bin/kontrol`, Ruby sürümünü doğrular, üç Ruby kaynak ve test dosyasını sözdizimi açısından denetler ve Minitest'in çıkış kodunu döndürür.

```sh
ruby -Ilib test/ogrenci_test.rb
ruby bin/kontrol
```

Her iki komut da teslim kopyasında **8 test, 61 doğrulama, 0 başarısızlık, 0 hata ve 0 atlama** ile geçti. [Minitest](evidence/final/minitest.log) · [Doğrulama komutu](evidence/final/kontrol.log)

## Mimari

- [`Ogrenci`](lib/ogrenci.rb) boş olmayan bir ad, `:aktif`, `:donduruldu` veya `:mezun` durumu ve 0–10 aralığında tam sayı devamsızlık alır. Geçersiz girdi `ArgumentError` üretir. `aktif?`, `donduruldu?` ve `mezun?` metotları, sınıf yüklenirken sabit durum listesinden `define_method` ile üretilir. Bilinmeyen bir sorgu Ruby'nin yerleşik `NoMethodError` istisnasını verir.
- [`DevamsizlikKontrol`](lib/devamsizlik_kontrol.rb) 3 ve üzerinde `riskli?`, 4 ve üzerinde `kaldi?` sorgusunu doğru döndürür. `sonuc` öncelik sırasıyla `:kaldi`, `:riskli`, aktif öğrencide tam 2 için `:erken_uyari` veya `:normal` döndürür.
- [Minitest sözleşmesi](test/ogrenci_test.rb) alt ve üst sınırları, tam %30'u, durum sorgularını, bilinmeyen metotları, geçersiz girdileri ve erken uyarının hangi durumlarda geçerli olduğunu kapsar.

```ruby
require_relative 'lib/ogrenci'
require_relative 'lib/devamsizlik_kontrol'

ogrenci = Ogrenci.new(ad: 'İpek', durum: :aktif, devamsizlik: 3)
DevamsizlikKontrol.sonuc(ogrenci) # => :riskli
```

## A/B Koşusu ve Ölçüm Raporu

İki bağımsız koşuda aynı Codex CLI çalıştırılabilir dosyası, `gpt-6.2-sol`, `medium` akıl yürütme düzeyi ve Windows `unelevated` modunda `workspace-write` kullanıldı. CLI kullanıcı yapılandırmasını ve yerel çalıştırma kurallarını devre dışı bıraktı. `project_root_markers=[]` her iki koşuda da çalışma dizinini proje yapılandırmasının kökü yaptı. A başlatıldığında boştu. B'ye proje kuralları, test, doğrulama komutu ve kanca verildi. B'nin proje kancaları oturum için ayrıca yetkilendirildi. [A başlatma ayarları](evidence/a/arguments.json) · [B başlatma ayarları](evidence/b/arguments.json)

Her iki ajanın aldığı temel görev cümlesi aynıdır.

> Öğrenci devamsızlık kontrolü yap, devamsızlık sınırı %30'dur.

Standart girdilerin SHA-256 değeri her iki koşuda da `3BE04E3149CCE236DD2ACDDBB7C12162B7C537BF6A286B27CBA0DC23A5A22126`. Codex oturum kayıtlarındaki kullanıcı mesajı her iki girdiyle birebir eşleşir. [A mesaj kaydı](evidence/a/model-prompt.jsonl) · [B mesaj kaydı](evidence/b/model-prompt.jsonl)

### A → Ratchet → B

1. **A** · `experiments/a` içinde boş klasörü doğrulayan ajan, yoklama kayıtlarını aradı ve kullanıcıdan veri istedi. İlk ve son anlık durumda uygulama dosyası yoktu. A kendi oturumunda test çalıştırmadı. Daha sonra koordinatör, boş anlık görüntüye karşı aynı test sözleşmesini ayrı bir klasörde çalıştırdı ve `lib/ogrenci.rb` bulunamadığı için `LoadError` aldı. [Olaylar](evidence/a/events.jsonl) · [Dosya envanteri](evidence/a/snapshot.json) · [A değerlendirmesi](evidence/a/assessment.log)
2. **Ratchet** · Gözlemlerden sonra [ratchet günlüğü](RATCHET_LOG.md), [AGENTS.md](AGENTS.md), [CLAUDE.md](CLAUDE.md) sembolik bağlantısı, [Minitest sözleşmesi](test/ogrenci_test.rb) ve [kanca](.codex/hooks.json) hazırlandı. B öncesi denemede otomatik kanca hem test hatasını hem geri alımdan sonraki başarıyı kaydetti. [Sembolik bağlantı doğrulaması](evidence/ratchet/symlink.log) · [Otomatik kontrol çıktıları](evidence/ratchet/hook/kontrol.jsonl)
3. **B** · `experiments/b` içinde başlangıçta `lib/` yoktu. A'dan uygulama kodu aktarılmadı. B ajanı iki dosyayı tek düzenlemede yazdı ve otomatik kanca ile iki manuel doğrulamayı geçti. Test başarısızlığı veya düzeltme turu oluşmadı. `git status` çağrısı, deney sırasında çalışma klasöründe Git deposu kurulmadığı için 1 döndürdü. Sonradan köke kopyalanan uygulama dosyaları B çıktısıyla aynı SHA-256 değerlerine sahip. B'nin başlangıç harness dosyaları aynı kaldı. [Önce](evidence/b/pre-run.json) · [Olaylar](evidence/b/events.jsonl) · [Kanca](evidence/b/kontrol.jsonl) · [Sonra](evidence/b/post-run.json)

Masaüstü CLI ile yapılan iki önceki A denemesinde Windows kabuk komutlarını başlatamadı. İki denemenin özgün JSONL ve stderr çıktıları korundu. A sütununa karşılaştırılabilir bağımsız CLI koşusunun verileri girdi. [İlk A denemesi](evidence/a/initial/events.jsonl) · [İlk stderr](evidence/a/initial/stderr.log) · [İkinci A denemesi](evidence/a/desktop-elevated/events.jsonl) · [İkinci stderr](evidence/a/desktop-elevated/stderr.log)

### Gerçek ölçümler

- **A** · 31,479 saniye, 1 CLI turu ve token kaydı bulunan 5 model yanıtı. 3 kabuk çağrısı, 0 dosya düzenleme olayı ve 2 MCP çağrısı. 113.116 girdi tokenı (102.016 önbellekten, 11.100 önbellek dışı), 350 çıktı tokenı, 113.466 toplam token. [A süreç kaydı](evidence/a/process.json) · [A token kayıtları](evidence/a/token-usage.jsonl)
- **B** · 49,863 saniye, 1 CLI turu ve token kaydı bulunan 5 model yanıtı. 9 kabuk çağrısı, 1 dosya düzenleme olayı ve 0 MCP çağrısı. 122.174 girdi tokenı (109.440 önbellekten, 12.734 önbellek dışı), 846 çıktı tokenı, 123.020 toplam token. [B süreç kaydı](evidence/b/process.json) · [B token kayıtları](evidence/b/token-usage.jsonl)

CLI turu bir kullanıcı isteminden `turn.completed` olayına kadar sürer. İçindeki tüm model yanıtları ve araç çağrıları ölçüme dahildir. Süre, CLI sürecinin başlangıcı ile bitişi arasındaki duvar saati süresidir. Hazırlık, masaüstü tanılama denemeleri, ayrı kanca denemesi ve koordinatörün son testleri ölçüm dışındadır. Önbellek kullanımı girdi tokenlarının içindedir. Ölçümler yerel Codex kullanım kayıtları ve CLI toplamlarıyla çapraz doğrulandı. [Makinece okunabilir ölçümler](evidence/measurements.json) · [Ölçüm betiği](evidence/measure.ps1) · [Başlatıcı](evidence/run-experiment.ps1)

## Düzenleme sonrası kanca

Codex'i proje kökünden Ruby 3.4 erişilebilirken başlatın. Proje yapılandırmasına güven verin, ardından Codex'in `/hooks` komutuyla [proje kancasını](.codex/hooks.json) inceleyip onaylayın. Kanca `SessionStart` olayında dosyaların parmak izlerini kaydeder. `PostToolUse` olayı sonrasında kabuk veya `apply_patch` çağrısı `lib/`, `test/` altındaki Ruby dosyalarını ya da `bin/kontrol` dosyasını değiştirdiyse kontrolü otomatik çalıştırır. Kontrolün sonucu modele bildirilir ve `.harness/<oturum-kimliği>/kontrol.jsonl` dosyasına yazılır. [Kanca betiği](.codex/hooks/kontrol.rb) · [Codex kanca belgeleri](https://learn.chatgpt.com/docs/hooks)

Kanıt denemesinde ajan yalnızca test verisini iki ayrı kabuk çağrısıyla değiştirdi. İlk değişiklikte Minitest beklenen 1 yerine 2 buldu ve otomatik kontrolün çıkış kodu 1 oldu. İkinci düzenleme değeri geri yükledi ve aynı kontrol 0 ile çıktı. B oturumunda kanca iki uygulama dosyası eklenir eklenmez 8 testi geçti. [Deneme olayları](evidence/ratchet/hook/events.jsonl) · [Başarısız ve başarılı çıktılar](evidence/ratchet/hook/kontrol.jsonl) · [B kanca çıktısı](evidence/b/kontrol.jsonl)

`CLAUDE.md`, `AGENTS.md` dosyasına göreli bir sembolik bağlantıdır. Windows'ta `Get-Item CLAUDE.md | Select-Object LinkType, Target` komutuyla, Git'te `git ls-files --stage CLAUDE.md` komutunun `120000` moduyla doğrulanabilir.

## Yapamadıklarım

- A oturumundan ilk kaynak kodu saklayamadım. Ajan kaynak dosya üretmedi. [A dosya envanteri](evidence/a/snapshot.json)
- Oturum başına parasal tutar CLI çıktısında bulunmadığı için maliyet hesaplanmadı. Ölçüm dosyasında `cost` alanları `null` olarak kaydedildi. [Ölçümler](evidence/measurements.json)
- Tek A/B çifti ve A'da teslim edilen kodun bulunmaması, süre veya token farkından genellenebilir verimlilik sonucu çıkarmaya yetmiyor.
- `experiments/a` yerelde boş kaldı. Git boş dizinleri kaydetmediği için yeni bir klonda A koşusu için bu dizini boş olarak yeniden oluşturun. Kanca kanıtı Codex araç düzenlemelerini kapsıyor. Codex dışındaki elle düzenlemeler doğrudan bir Codex araç olayı üretmez.
