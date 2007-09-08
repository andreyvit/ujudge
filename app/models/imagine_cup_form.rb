class ImagineCupForm < Form
  def samsung?(team)
    false
  end
  
  def create_data!(team)
    r = ImagineCupRec.new
    r.team_id = team.id
    r.save!
    team.form_data = "IC07RUXN" + sprintf("%03d", r.id)
  end
  
  def render_data(team)
    %Q!Вам также необходимо зарегистрироваться на сервере Imagine Cup по адресу <a href="http://www.imaginecup.com/Registration/Default.aspx">http://www.imaginecup.com/Registration/</a>. При регистрации укажите Referral Code: #{team.form_data}.! 
  end
end
