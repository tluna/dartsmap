class Dartsshop < ActiveRecord::Base
  acts_as_gmappable
  attr_accessible :shopname, :address, :latitude, :longitude, :url
  #geocoded_by :address
  #after_validation :geocode
  @agent = Mechanize.new

  def search_addr(name)
    @latlons = Gecoder.search(name)
  end

  #
  # ページ数分のURLを取得します
  #
  def Dartsshop.get_list_data
    # 最初のページ
    hoge = @agent.get('http://search.dartslive.jp/list/?p=0')
    # 最後のページ
    max = hoge.link_with(:text => 'Last').uri.to_param[3..100].to_i
    urls = Array.new
    for i in 0..max
      urls << 'http://search.dartslive.jp/list/?p=' + i.to_s
    end
    return urls
  end

  #
  # 各ページごとの情報を保存します。(店舗名、URL、住所）
  #
  def Dartsshop.get_shop_data(urls)
    urls.each do |url|
      # スクレイピングするぞ！
      hoge = @agent.get(url)
      # お店の情報
      shopdata = hoge.search('/html/body/div/div/div[2]/div/div[5]').search('p/a')

      # お店のURLと名称
      shopurl = Array.new
      shopname = Array.new
      shopdata.each do |line|
        # お店のURL
        shopurl << 'http://search.dartslive.jp' + line['href']
        shopname << line.inner_text.to_s
      end

      # 踏み込んでみよう♪お店の住所
      shopaddress = Array.new
      hoge.search("/html/body/div/div/div[2]/div/div[5]").search("li[@class='address']").each do |line|
        shopaddress << line.inner_text.to_s
      end
      puts shopaddress.count
      sleep 10

      #名前とURL、住所を結合する
      shopinfo = Array.new
      for i in 0..shopname.count-1 do
        shopinfo[i] = {:shopaddress => shopaddress[i], :shopurl => shopurl[i], :shopname => shopname[i]}
      end

      #
      # 各々保存していく
      #
      shopinfo.each do |line|
        if (self.find(:all, :conditions => {:shopname => line[:shopname],:address => line[:shopaddress]}).empty?)
          shop = self.new(:shopname => line[:shopname], :address => line[:shopaddress], :url => line[:shopurl])
          shop.save
        end
      end
    end
  end

  #
  # 各メソッドを呼び出して情報を保存
  #
  def Dartsshop.get_shop_save
    self.get_shop_data self.get_list_data
  end


  def gmaps4rails_address
    "#{self.address}"
  end
  def Dartsshop.get_shop_latlon
    target_record = Dartsshop.find(:all, :conditions => {:latitude => nil, :longitude => nil})
    target_record.each do | shop |
      geo = Geocoder.search(shop.address)
      shop.update_attributes!(:latitude => geo[0].latitude)
      shop.update_attributes!(:longitude => geo[0].longitude)
    end
  end
end
