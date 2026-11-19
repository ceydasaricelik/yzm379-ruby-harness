# Ratchet günlüğü

## A koşusunda gözlenenler

1. **Görev yorumu ve eksik teslim.** A ajanı boş çalışma klasörünü komutla doğruladı (`item_3`), mevcut yoklama kayıtlarını aradı ve sonunda kullanıcıdan dosya veya veri istedi (`item_6`). Çalışma klasörünün son envanteri sıfır dosya gösteriyor. Uygulama, durum sorguları ve testler bu koşuda ortaya çıkmadı. Bu gözleme karşı B'nin [proje kuralları](AGENTS.md) bir Ruby uygulaması teslim edileceğini, dosya yollarını ve denetlenebilir metot sözleşmesini belirtiyor. [CLI olayları](evidence/a/events.jsonl) · [Dosya envanteri](evidence/a/snapshot.json)
2. **Sınır cevabı eksik kaldı.** A'nın son mesajı %30'u aşanları ve tam %30'da olanları ayrı ayrı belirteceğini söylüyor. Tam %30 için `riskli` kararı, 4 ve üzeri için `kaldı` kararı ve aktif öğrencide tam 2 için erken uyarı teslim edilmedi. Çalıştırılabilir kod olmadığı için sınır davranışı test edilemedi. [Minitest sözleşmesi](test/ogrenci_test.rb) bu kararları ayrı ayrı denetler. [A'nın son mesajı](evidence/a/events.jsonl)

## Önceki teknik denemeler

İlk masaüstü CLI denemesinin son cevabı tam %30'u sınır içinde tarif etti ve risk durumunu belirtmedi. Bu denemede kabuk çağrıları `blocked by policy` hatası verdi. Açık `elevated` ayarıyla ikinci denemede kabuk, kayıtlı Core uygulamasını başlatamadı. Bu iki deneme ortam tanılaması olarak korunuyor. Karşılaştırmadaki A ölçümü, kabuk komutu çalıştırabilen bağımsız CLI oturumundan alınmıştır. [İlk deneme](evidence/a/initial/events.jsonl) · [İlk stderr](evidence/a/initial/stderr.log) · [İkinci stderr](evidence/a/desktop-elevated/stderr.log)

Farklı dilde kaynak, gizli metot üretimi veya monkey patch gözlemlenmedi. Ruby 3.4, `define_method` ve ilgili yasaklar ödevin önceden belirlenmiş şartlarıdır. [Proje kuralları](AGENTS.md)
