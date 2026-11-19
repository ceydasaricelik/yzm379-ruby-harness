module DevamsizlikKontrol
  KURALLAR = {
    riskli: ->(ogrenci) { ogrenci.devamsizlik >= 3 },
    kaldi: ->(ogrenci) { ogrenci.devamsizlik >= 4 },
    erken_uyari: ->(ogrenci) { ogrenci.aktif? && ogrenci.devamsizlik == 2 }
  }.freeze
  SONUC_ONCELIGI = %i[kaldi riskli erken_uyari].freeze
  private_constant :KURALLAR, :SONUC_ONCELIGI

  def self.riskli?(ogrenci)
    KURALLAR.fetch(:riskli).call(ogrenci)
  end

  def self.kaldi?(ogrenci)
    KURALLAR.fetch(:kaldi).call(ogrenci)
  end

  def self.uygulanan_kurallar(ogrenci)
    KURALLAR.filter_map { |ad, kural| ad if kural.call(ogrenci) }
  end

  def self.sonuc(ogrenci)
    SONUC_ONCELIGI.find { |ad| KURALLAR.fetch(ad).call(ogrenci) } || :normal
  end
end
