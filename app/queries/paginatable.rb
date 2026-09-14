module Paginatable
  DEFAULT_PER_PAGE = 20
  MAX_PER_PAGE = 50
  INVALID_PAGINATION_MESSAGE =
    "Pagination values must be positive integers and per_page cannot exceed #{MAX_PER_PAGE}"

  class InvalidPagination < StandardError; end

  private

  def paginate(page:, per_page:)
    @page = parse_positive_integer(page)
    @per_page = parse_per_page(per_page)
  end

  def page
    @page
  end

  def per_page
    @per_page
  end

  def pagination_offset
    (page - 1) * per_page
  end

  def pagination_meta(total_count)
    {
      current_page: page,
      per_page: per_page,
      total_pages: (total_count.to_f / per_page).ceil,
      total_count: total_count
    }
  end

  def parse_positive_integer(value)
    return value.to_i if value.to_s.match?(/\A[1-9]\d*\z/)

    raise InvalidPagination, INVALID_PAGINATION_MESSAGE
  end

  def parse_per_page(value)
    parsed_value = parse_positive_integer(value)
    return parsed_value if parsed_value <= MAX_PER_PAGE

    raise InvalidPagination, INVALID_PAGINATION_MESSAGE
  end
end
