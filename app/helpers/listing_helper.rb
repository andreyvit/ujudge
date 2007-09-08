
module ListingHelper
  def listing_column_checkbox(col, options = {})
    html_options = { "type" => "checkbox", "name" => "show[#{col.unique_id}]",
      "id" => "show_#{col.unique_id}", "value" => "1" }.update(options.stringify_keys)
    html_options["checked"] = "checked" if col.show?
    tag :input, html_options
  end
end