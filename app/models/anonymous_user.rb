class AnonymousUser
  def allow?(perm)
    false
  end
  
  def full_name
    "анонимный пользователь"
  end
end
