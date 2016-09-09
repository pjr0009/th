module CategoryViewUtils

  module_function

  # Returns an array that contains the hierarchy of categories and listing shapes
  #
  # An xample of a returned tree:
  #
  # [
  #   {
  #     "label" => "item",
  #     "id" => id,
  #     "subcategories" => [
  #       {
  #         "label" => "tools",
  #         "id" => id,
  #         "listing_shapes" => [
  #           {
  #             "label" => "sell",
  #             "id" => id
  #           }
  #         ]
  #       }
  #     ]
  #   },
  #   {
  #     "label" => "services",
  #     "id" => "id"
  #   }
  # ]
  def category_tree(categories:, shapes:)
    categories.map { |c|
      {
        id: c[:id],
        label: c[:name],
        listing_shapes: embed_shape(c[:listing_shape_ids], shapes),
        subcategories: category_tree(
          categories: c[:children],
          shapes: shapes
        )
      }
    }

  end

  # private

  def embed_shape(ids, shapes)
    shapes.select { |s|
      ids.include? s[:id]
    }.map { |s|
      {
        id: s[:id],
        label: I18n.translate(s[:name_tr_key])
      }
    }
  end
 

  def sort_num_or_nil(a, b)
    if a.nil?
      1
    elsif b.nil?
      -1
    else
      a <=> b
    end
  end
end
