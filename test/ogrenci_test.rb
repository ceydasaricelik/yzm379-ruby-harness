require 'minitest/autorun'
require_relative '../lib/ogrenci'
require_relative '../lib/devamsizlik_kontrol'

class OgrenciTest < Minitest::Test
  def test_alanlar_okunabilir
    ogrenci = Ogrenci.new(ad: 'İpek', durum: :aktif, devamsizlik: 0)

    assert_equal 'İpek', ogrenci.ad
    assert_equal :aktif, ogrenci.durum
    assert_equal 0, ogrenci.devamsizlik
  end

  def test_durum_sorgulari
    sorgular = { aktif: :aktif?, donduruldu: :donduruldu?, mezun: :mezun? }

    sorgular.each_key do |durum|
      ogrenci = yeni_ogrenci(0, durum)
      sorgular.each do |sorgulanan_durum, metot|
        assert_respond_to ogrenci, metot
        assert_equal(durum == sorgulanan_durum, ogrenci.public_send(metot))
      end
    end
  end

  def test_bilinmeyen_sorgu_no_method_error_verir
    ogrenci = yeni_ogrenci(0)

    refute_respond_to ogrenci, :silindi?
    hata = assert_raises(NoMethodError) { ogrenci.silindi? }
    assert_equal :silindi?, hata.name
  end

  def test_gecersiz_adlar
    [nil, 12, '', " \t\n"].each do |ad|
      assert_raises(ArgumentError) do
        Ogrenci.new(ad: ad, durum: :aktif, devamsizlik: 0)
      end
    end
  end

  def test_gecersiz_durumlar
    [nil, :silindi, 'aktif'].each do |durum|
      assert_raises(ArgumentError) { yeni_ogrenci(0, durum) }
    end
  end

  def test_gecersiz_devamsizliklar
    [-1, 11, 3.0, '3', nil, true].each do |devamsizlik|
      assert_raises(ArgumentError) { yeni_ogrenci(devamsizlik) }
    end
  end

  def test_riskli_ve_kaldi_esiklerinin_tam_sinirlari
    beklentiler = {
      0 => [false, false, :normal],
      1 => [false, false, :normal],
      2 => [false, false, :erken_uyari],
      3 => [true, false, :riskli],
      4 => [true, true, :kaldi],
      10 => [true, true, :kaldi]
    }

    beklentiler.each do |devamsizlik, (riskli, kaldi, sonuc)|
      ogrenci = yeni_ogrenci(devamsizlik)
      assert_equal riskli, DevamsizlikKontrol.riskli?(ogrenci), "devamsızlık=#{devamsizlik}"
      assert_equal kaldi, DevamsizlikKontrol.kaldi?(ogrenci), "devamsızlık=#{devamsizlik}"
      assert_equal sonuc, DevamsizlikKontrol.sonuc(ogrenci), "devamsızlık=#{devamsizlik}"
    end
  end

  def test_aktif_olmayan_ogrencilerde_erken_uyari_verilmez
    %i[donduruldu mezun].each do |durum|
      assert_equal :normal, DevamsizlikKontrol.sonuc(yeni_ogrenci(2, durum))
      assert_equal :riskli, DevamsizlikKontrol.sonuc(yeni_ogrenci(3, durum))
      assert_equal :kaldi, DevamsizlikKontrol.sonuc(yeni_ogrenci(4, durum))
    end
  end

  def test_uygulanan_kurallar_bagimsiz_ve_es_zamanli_degerlendirilir
    %i[aktif donduruldu mezun].each do |durum|
      assert_empty DevamsizlikKontrol.uygulanan_kurallar(yeni_ogrenci(1, durum))
      assert_equal [:riskli], DevamsizlikKontrol.uygulanan_kurallar(yeni_ogrenci(3, durum))
      assert_equal %i[riskli kaldi], DevamsizlikKontrol.uygulanan_kurallar(yeni_ogrenci(4, durum))
    end

    assert_equal [:erken_uyari], DevamsizlikKontrol.uygulanan_kurallar(yeni_ogrenci(2))
    assert_empty DevamsizlikKontrol.uygulanan_kurallar(yeni_ogrenci(2, :mezun))
  end

  private

  def yeni_ogrenci(devamsizlik, durum = :aktif)
    Ogrenci.new(ad: 'Deniz', durum: durum, devamsizlik: devamsizlik)
  end
end
