class String
  KEYBOARD = {
    :ru  => "йцукенгшщзхъфывапролджэячсмитьбю.",
    :en  => "qwertyuiop[]asdfghjkl;'zxcvbnm,./"
  }
  
  TRANSLITERATION = {}
  
  def self.add_trasliteration_rules_string(from, to, rules_string)
    rules = {}
    rules_string.split('/').collect do |rule|
      src, dsts = rule.split('=', 2)
      (rules[src] ||= []) << dsts.split(',') unless dsts.nil?
    end
    self.add_trasliteration_rules(from, to, rules)
  end
  
  def self.add_trasliteration_rules(from, to, rules)
    (TRANSLITERATION[[from, to]] ||= {}).update(rules)
  end
  
  add_trasliteration_rules_string :ru, :en, "а=a/б=b/в=v,w/г=g/д=d/е=e/ж=g,j,dj,dg"
  add_trasliteration_rules_string :ru, :en, "з=z/и=i/й=i,ij,j,y/к=k/л=l/м=m/н=n/о=o/п=p"
  add_trasliteration_rules_string :ru, :en, "р=r/с=s/т=t/у=u,y/ф=f/х=h/ц=c,ts/ч=c,ch/ш=sh/щ=sch,sh"
  add_trasliteration_rules_string :ru, :en, "ъ=,j,'/ы=i,y/ь=,'/э=a/ю=u,iu,yu,ju/я=a,ia,ya,ja"
  
  def transtype(from, to) 
    kfrom, kto = KEYBOARD[from], KEYBOARD[to]
    raise "unknown keyboard #{from}" if kfrom.nil?
    raise "unknown keyboard #{to}" if kto.nil?
    
    self.tr(kfrom, kto)
  end
  
  def transliterate(from, to)
  end
  
  def to_url_friendly(src_lang = :ru)
    self.transtype(src_lang, :en).gsub(/[^a-zA-Z0-9_]/, '_').gsub(/_{2,}/, '_')
  end
end
