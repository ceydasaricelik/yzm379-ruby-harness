# YZM379 Ruby Harness

- Teslim edilecek uygulamayı `lib/ogrenci.rb` ve `lib/devamsizlik_kontrol.rb` içinde oluştur. Ruby 3.4 kullan. Bağımlılıklar Ruby standart kütüphanesi ve Minitest ile sınırlıdır.
- `Ogrenci.new(ad:, durum:, devamsizlik:)` boş olmayan bir String ad, `:aktif`, `:donduruldu`, `:mezun` durumlarından bir Symbol ve 0..10 aralığında bir Integer kabul eder. Geçersiz değerlerde `ArgumentError` fırlat. Alanlar `ad`, `durum`, `devamsizlik` ile okunur.
- `aktif?`, `donduruldu?`, `mezun?` sorgularını sabit durum listesinden `define_method` ile sınıf yüklenirken üret. Ruby'nin yerleşik bilinmeyen metot davranışını koru. `method_missing`, `respond_to_missing?`, monkey patch ve var olan Ruby sınıflarını yeniden açma yasaktır.
- `DevamsizlikKontrol.riskli?(ogrenci)` için eşik 3, `DevamsizlikKontrol.kaldi?(ogrenci)` için eşik 4 ve üzeridir. Tam 3 risklidir ve kalmış sayılmaz. 4 ve üzeri iki sorguda da doğrudur.
- `DevamsizlikKontrol.sonuc(ogrenci)` öncelik sırasıyla `:kaldi`, `:riskli`, sadece aktif öğrencinin tam 2 devamsızlığı için `:erken_uyari` veya `:normal` döndürür. İlk iki eşik bütün öğrenci durumlarında uygulanır.
- Mevcut `test/ogrenci_test.rb` sözleşmesini koru. Hatalarda uygulama kodunu düzelt. Proje kökünde `ruby -Ilib test/ogrenci_test.rb` ve `ruby bin/kontrol` komutlarını çalıştır. Kancanın raporladığı hataları incele ve teslimden önce her iki doğrulamayı geçir.
