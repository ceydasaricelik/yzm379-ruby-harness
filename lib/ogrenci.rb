class Ogrenci
  DURUMLAR = %i[aktif donduruldu mezun].freeze

  attr_reader :ad, :durum, :devamsizlik

  def initialize(ad:, durum:, devamsizlik:)
    unless ad.is_a?(String) && !ad.strip.empty?
      raise ArgumentError, 'Ad boş olmayan bir metin olmalıdır.'
    end

    unless durum.is_a?(Symbol) && DURUMLAR.include?(durum)
      raise ArgumentError, 'Durum aktif, donduruldu veya mezun olmalıdır.'
    end

    unless devamsizlik.is_a?(Integer) && devamsizlik.between?(0, 10)
      raise ArgumentError, 'Devamsızlık 0 ile 10 arasında bir tam sayı olmalıdır.'
    end

    @ad = ad
    @durum = durum
    @devamsizlik = devamsizlik
  end

  DURUMLAR.each do |durum|
    define_method("#{durum}?") { @durum == durum }
  end
end
