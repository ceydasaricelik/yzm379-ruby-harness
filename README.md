# YZM379 Ruby Harness

Teslim tarihi 20 Kasım 2026, 23:59 (Türkiye saati).

## Amaç ve kapsam

Bu proje, 10 derslik bir dönem için öğrenci devamsızlığını Ruby ile değerlendirir. Öğrenci modeli, üç bağımsız devamsızlık kuralı, Minitest doğrulamaları ve Codex düzenleme kancası içerir. Deney arşivi, rehbersiz bir görevin nasıl yorumlandığını ve önceden hazırlanmış proje rehberi ile testlerin sonraki koşudaki sonucunu kaydeder.

## Kurulum ve doğrulama

Ruby 3.4 ve Minitest gerekir. [`.ruby-version`](.ruby-version) doğrulamada kullanılan 3.4.11 yama sürümünü sabitler. Bu teslim Minitest 5.25.4, Git 2.56.0 ve Codex CLI 0.169.1 ile doğrulandı. Minitest kurulumunuzda yoksa `gem install minitest -v 5.25.4` komutuyla ekleyin. Uygulama başka bir gem gerektirmez. [Ortam çıktısı](evidence/ratchet/environment.log) · [RubyInstaller arşivleri](https://rubyinstaller.org/downloads/archives/)

Bu Windows çalışma alanında kurulan taşınabilir Ruby'yi kullanmak için proje kökünde şu komutları çalıştırın. `.runtime/` yerel kurulum dizinidir ve Git'e dahil değildir.

```powershell
$env:PATH = (Resolve-Path .runtime/rubyinstaller-3.4.11-1-x64/bin).Path + ';' + $env:PATH
Remove-Item Env:GEM_HOME, Env:GEM_PATH -ErrorAction SilentlyContinue
ruby -v
```

Proje kökünden Minitest'i doğrudan veya sözdizimi denetimiyle birlikte çalıştırabilirsiniz. `bin/kontrol`, Ruby 3.4'ü doğrular, iki kaynak dosyayı ve test dosyasını denetler. Başarıda 0, Minitest başarısızlığında 2, sürüm, sözdizimi veya süreç başlatma hatasında 1 döndürür.

```sh
ruby -Ilib test/ogrenci_test.rb
ruby bin/kontrol
```

PowerShell'de uzantısız Ruby betiğini `ruby bin/kontrol` ile çalıştırın. Git Bash'te Ruby 3.4 `PATH` üzerindeyken `./bin/kontrol` doğrudan çalışır. İki kabukta da testler **9 test, 76 doğrulama, 0 başarısızlık, 0 hata ve 0 atlama** ile geçti. [Çalışma ağacı çıktısı](evidence/audit/current-check.log) · [Temiz klon çıktısı](evidence/audit/clean-clone.log)

## Mimari

### Öğrenci sınıfı

`Ogrenci` boş olmayan bir ad, `:aktif`, `:donduruldu` veya `:mezun` durumu ve 0–10 aralığında tam sayı devamsızlık alır. Geçersiz girdi `ArgumentError` üretir. `aktif?`, `donduruldu?` ve `mezun?` metotları, sınıf yüklenirken sabit durum listesinden `define_method` ile üretilir. Bilinmeyen bir sorgu Ruby'nin yerleşik `NoMethodError` istisnasını verir. [Öğrenci sınıfı](lib/ogrenci.rb)

### Kural motoru

Kurallar açık öğrenci parametresi alan lambdalarla bir Hash'te tanımlanır. `riskli?` 3 ve üzeri, `kaldi?` 4 ve üzeri için doğrudur. Aktif öğrencide tam 2 devamsızlık `:erken_uyari` üretir. `uygulanan_kurallar` eşleşmelerin tamamını verir. `sonuc` tek durum döndürür ve önceliği sırasıyla `:kaldi`, `:riskli`, `:erken_uyari` ve `:normal` olarak uygular. [Kural motoru](lib/devamsizlik_kontrol.rb)

```ruby
require_relative 'lib/ogrenci'
require_relative 'lib/devamsizlik_kontrol'

ogrenci = Ogrenci.new(ad: 'İpek', durum: :aktif, devamsizlik: 4)
DevamsizlikKontrol.uygulanan_kurallar(ogrenci) # => [:riskli, :kaldi]
DevamsizlikKontrol.sonuc(ogrenci)             # => :kaldi
```

### Minitest

Testler alt ve üst sınırları, tam %30'u, durum sorgularını, bilinmeyen metotları, geçersiz girdileri, erken uyarıyı ve 4 devamsızlıkta kuralların birlikte döndüğünü kapsar. [Minitest sözleşmesi](test/ogrenci_test.rb)

## AGENTS.md rehberi ve Ratchet

Proje rehberi uygulama sözleşmesini, yasaklı Ruby tekniklerini ve doğrulama komutlarını tanımlar. Ratchet günlüğü her A gözlemini ilgili kural, sensör ve B doğrulamasıyla ilişkilendirir. [Rehber](AGENTS.md) · [Ratchet günlüğü](RATCHET_LOG.md)

## A/B Koşusu ve Ölçüm Raporu

İki bağımsız koşuda aynı Codex CLI çalıştırılabilir dosyası, `gpt-6.2-sol`, `medium` akıl yürütme düzeyi ve Windows `unelevated` modunda `workspace-write` kullanıldı. CLI kullanıcı yapılandırmasını ve yerel çalıştırma kurallarını devre dışı bıraktı. `project_root_markers=[]` her iki koşuda da çalışma dizinini proje yapılandırmasının kökü yaptı. A başlatıldığında boştu. B'ye proje kuralları, test, doğrulama komutu ve kanca verildi. B'nin proje kancaları oturum için ayrıca yetkilendirildi. [A başlatma ayarları](evidence/a/arguments.json) · [B başlatma ayarları](evidence/b/arguments.json)

Her iki ajanın aldığı temel görev cümlesi aynıdır.

> Öğrenci devamsızlık kontrolü yap, devamsızlık sınırı %30'dur.

Standart girdilerin SHA-256 değeri her iki koşuda da `3BE04E3149CCE236DD2ACDDBB7C12162B7C537BF6A286B27CBA0DC23A5A22126`. Codex oturum kayıtlarındaki kullanıcı mesajı her iki girdiyle birebir eşleşir. [A mesaj kaydı](evidence/a/model-prompt.jsonl) · [B mesaj kaydı](evidence/b/model-prompt.jsonl)

### A → Ratchet → B

1. **A** · `experiments/a` içinde boş klasörü doğrulayan ajan, yoklama kayıtlarını aradı ve kullanıcıdan veri istedi. İlk ve son anlık durumda uygulama dosyası yoktu. A kendi oturumunda test çalıştırmadı. Daha sonra koordinatör, boş anlık görüntüye karşı aynı test sözleşmesini ayrı bir klasörde çalıştırdı ve `lib/ogrenci.rb` bulunamadığı için `LoadError` aldı. [Olaylar](evidence/a/events.jsonl) · [Dosya envanteri](evidence/a/snapshot.json) · [A değerlendirmesi](evidence/a/assessment.log)
2. **Ratchet** · Gözlemlerden sonra [ratchet günlüğü](RATCHET_LOG.md), [AGENTS.md](AGENTS.md), [CLAUDE.md](CLAUDE.md) sembolik bağlantısı, [Minitest sözleşmesi](test/ogrenci_test.rb) ve [kanca](.codex/hooks.json) hazırlandı. B öncesi denemede otomatik kanca hem test hatasını hem geri alımdan sonraki başarıyı kaydetti. [Sembolik bağlantı doğrulaması](evidence/ratchet/symlink.log) · [Otomatik kontrol çıktıları](evidence/ratchet/hook/kontrol.jsonl)
3. **B** · `experiments/b` içinde başlangıçta `lib/` yoktu. A'dan uygulama kodu aktarılmadı. B ajanı `AGENTS.md` içeriğini okudu, iki dosyayı tek düzenlemede yazdı ve otomatik kanca ile iki manuel doğrulamayı 8 test ve 61 doğrulamayla geçti. B'de test başarısızlığı veya düzeltme turu oluşmadı. `git status` çağrısı, çalışma klasörü henüz Git deposu olmadığı için 1 döndürdü. Özgün B uygulaması ve harness, arşivdeki SHA-256 değerleriyle eşleşir. Sonraki GitHub öncesi denetim, teslim köküne bağımsız kural listesi, ek test, sürüm dosyası ve çıkış kodu sözleşmesini ekledi. [Önce](evidence/b/pre-run.json) · [Olaylar](evidence/b/events.jsonl) · [Kanca](evidence/b/kontrol.jsonl) · [Sonra](evidence/b/post-run.json) · [Denetim raporu](PRE_PUSH_AUDIT.md)

Masaüstü CLI ile yapılan iki önceki A denemesinde Windows kabuk komutlarını başlatamadı. İki denemenin özgün JSONL ve stderr çıktıları korundu. A sütununa karşılaştırılabilir bağımsız CLI koşusunun verileri girdi. [İlk A denemesi](evidence/a/initial/events.jsonl) · [İlk stderr](evidence/a/initial/stderr.log) · [İkinci A denemesi](evidence/a/desktop-elevated/events.jsonl) · [İkinci stderr](evidence/a/desktop-elevated/stderr.log)

### Gerçek ölçümler

- **A** · 31,479 saniye, 1 CLI turu ve token kaydı bulunan 5 model yanıtı. 3 kabuk çağrısı, 0 dosya düzenleme olayı ve 2 MCP çağrısı. 113.116 girdi tokenı (102.016 önbellekten, 11.100 önbellek dışı), 350 çıktı tokenı, 113.466 toplam token. [A süreç kaydı](evidence/a/process.json) · [A token kayıtları](evidence/a/token-usage.jsonl)
- **B** · 49,863 saniye, 1 CLI turu ve token kaydı bulunan 5 model yanıtı. 9 kabuk çağrısı, 1 dosya düzenleme olayı ve 0 MCP çağrısı. 122.174 girdi tokenı (109.440 önbellekten, 12.734 önbellek dışı), 846 çıktı tokenı, 123.020 toplam token. [B süreç kaydı](evidence/b/process.json) · [B token kayıtları](evidence/b/token-usage.jsonl)

B toplamda **9.554 token (%8,42) daha fazla** kullandı. CLI turu ve model yanıtı sayıları eşit kaldı. A'nın uygulama teslim etmemesi ve tek bir A/B çifti bulunması, bu farkı üretkenlik veya maliyet verimliliği ölçüsü olarak kullanmayı engeller. [Bağımsız yeniden hesaplama](evidence/audit/recheck.log)

CLI turu bir kullanıcı isteminden `turn.completed` olayına kadar sürer. İçindeki tüm model yanıtları ve araç çağrıları ölçüme dahildir. Süre, CLI sürecinin başlangıcı ile bitişi arasındaki duvar saati süresidir. Hazırlık, masaüstü tanılama denemeleri, ayrı kanca denemesi ve koordinatörün son testleri ölçüm dışındadır. Önbellek kullanımı girdi tokenlarının içindedir. Ölçümler yerel Codex kullanım kayıtları ve CLI toplamlarıyla çapraz doğrulandı. `pwsh -File evidence/measure.ps1` ölçümleri arşivlenmiş kayıtlarla yeniden hesaplar. [Makinece okunabilir ölçümler](evidence/measurements.json) · [Ölçüm betiği](evidence/measure.ps1) · [Başlatıcı](evidence/run-experiment.ps1)

## Düzenleme sonrası kanca

Codex'i proje kökünden Ruby 3.4 erişilebilirken başlatın. Proje yapılandırmasına güven verin, ardından Codex'in `/hooks` komutuyla [proje kancasını](.codex/hooks.json) inceleyip onaylayın. Kanca `SessionStart` olayında dosyaların parmak izlerini kaydeder. `PostToolUse` olayı sonrasında kabuk veya `apply_patch` çağrısı `lib/`, `test/` altındaki Ruby dosyalarını ya da `bin/kontrol` dosyasını değiştirdiyse kontrolü otomatik çalıştırır. Kontrolün sonucu modele bildirilir ve `.harness/<oturum-kimliği>/kontrol.jsonl` dosyasına yazılır. [Kanca betiği](.codex/hooks/kontrol.rb) · [Codex kanca belgeleri](https://learn.chatgpt.com/docs/hooks)

Kanıt denemesinde ajan yalnızca test verisini iki ayrı kabuk çağrısıyla değiştirdi. İlk değişiklikte Minitest beklenen 1 yerine 2 buldu ve otomatik kontrolün çıkış kodu 1 oldu. İkinci düzenleme değeri geri yükledi ve aynı kontrol 0 ile çıktı. B oturumunda kanca iki uygulama dosyası eklenir eklenmez 8 testi geçti. [Deneme olayları](evidence/ratchet/hook/events.jsonl) · [Başarısız ve başarılı çıktılar](evidence/ratchet/hook/kontrol.jsonl) · [B kanca çıktısı](evidence/b/kontrol.jsonl)

Denetim ayrıca temiz bir Windows klonunda kontrollü bir eşik hatasıyla güncel kancayı çalıştırdı. Kanca testleri kendiliğinden çalıştırır ve hata çıktısını ajana iletir. Kodu düzeltmek için ajanın ayrı bir düzenleme yapması gerekir. [Denetim kancası olayları](evidence/audit/hook/events.jsonl) · [Denetim kancası sonuçları](evidence/audit/hook/kontrol.jsonl)

`CLAUDE.md`, `AGENTS.md` dosyasına göreli bir sembolik bağlantıdır. Windows'ta sembolik bağlantı oluşturma yetkisi varken klon için `git clone -c core.symlinks=true <depo> <hedef>` kullanın. Bağlantı PowerShell'de `Get-Item CLAUDE.md | Select-Object LinkType, Target` komutuyla, Git'te `git ls-files --stage CLAUDE.md` komutunun `120000` moduyla doğrulanabilir. [Temiz klon çıktısı](evidence/audit/clean-clone.log)

## Deneyin sınırlılıkları

A için arşivlenen kullanıcı mesajı tek cümledir ve başlatma ayarları proje kökü aramasını kapatır. Arşiv, modelin tüm sistem bağlamını ve deney anındaki global talimat dosyası envanterini içermez. A koda ulaşmadığı için eşik davranışı ve kod kalitesi doğrudan A/B karşılaştırmasına elverişli değildir. B'de test hatası oluşmadığı için B'nin testten sonra onarım yaptığına dair ölçüm yoktur. Kanca hata ve başarı denemeleri A/B sayılarının dışındadır.

## Yapamadıklarım

- A oturumundan ilk kaynak kodu saklayamadım. Ajan kaynak dosya üretmedi. [A dosya envanteri](evidence/a/snapshot.json)
- Oturum başına parasal tutar CLI çıktısında bulunmadığı için maliyet hesaplanmadı. Ölçüm dosyasında `cost` alanları `null` olarak kaydedildi. [Ölçümler](evidence/measurements.json)
- `experiments/a` yerelde boş kaldı. Git boş dizinleri kaydetmediği için yeniden üretim amacıyla yeni klonda bu dizini boş olarak oluşturun. Codex dışındaki düzenlemeler doğrudan bir Codex araç olayı üretmez.
- Public GitHub yayını bekliyor. [GitHub öncesi denetim](PRE_PUSH_AUDIT.md)
