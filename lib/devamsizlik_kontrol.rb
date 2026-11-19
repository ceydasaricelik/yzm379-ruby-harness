module DevamsizlikKontrol
  DEVAMSIZLIK_SINIRI = 3

  def self.riskli?(ogrenci)
    ogrenci.devamsizlik >= DEVAMSIZLIK_SINIRI
  end

  def self.kaldi?(ogrenci)
    ogrenci.devamsizlik > DEVAMSIZLIK_SINIRI
  end

  def self.sonuc(ogrenci)
    return :kaldi if kaldi?(ogrenci)
    return :riskli if riskli?(ogrenci)
    return :erken_uyari if ogrenci.aktif? && ogrenci.devamsizlik == 2

    :normal
  end
end
