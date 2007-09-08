class Mails < ActionMailer::Base

  helper :application
  
  FROM = "noreply@olimp.nsu.ru"
  
  def team_registration_confirmation(team, password_set)
    recipients team.email
    subject "Команда #{team.name} успешно зарегистрирована"
    body    :team => team, :password_set => password_set
    from    FROM
  end

  def team_password_notification(team, password_set, reason)
    recipients team.email
    subject "Пароль для команды #{team.name}"
    body    :team => team, :reason => reason, :password_set => password_set
    from    FROM
  end

  def jury_invitation(user, password_set, reason)
    recipients user.email
    subject "#{user.full_name}, вы стали членом жюри"
    body    :user => user, :reason => reason, :password_set => password_set
    from    FROM
  end

  def test_message(email)
    t = "Пробное сообщение на адрес #{email} в #{Time.now.strftime('%c')}"
    recipients email
    subject t
    body    :email => email, :text => t
    from    FROM
  end
    
end
