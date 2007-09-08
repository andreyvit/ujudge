module ProblemsHelper

  def error_row(object, method)
    return '' unless object.errors.on(method)
    content_tag(:tr,
      content_tag(:td, "&nbsp;") +
      content_tag(:td, object.errors.on(method)),
        :class => 'error_row')
  end
  
  def error_info(object, method)
    return '' unless object.errors.on(method)
    tag(:br) + content_tag(:span, object.errors.on(method),
        :class => 'form_error')
  end

end
