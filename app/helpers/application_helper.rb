module ApplicationHelper
  def image_row_size(size)
    case size
    when 1 then 'col-12'
    when 2 then 'col-6'
    when 3 then 'col-4'
    else 'col-3'
    end
  end

  def peace_color(score)
    case
    when score <= 114 then 'badge-success'
    when score > 114 && score < 125 then 'badge-warning'
    when score > 125 then 'badge-danger'
    end
  end

  def todo_slice(size)
    case size
    when size % 3 == 0 then 3
    when size % 2 == 0 then 2
    when size % 1 == 0 then 1
    else 1
    end
  end

  def location_order(location)
    index = location.trip.locations.index(location)
    location.order.present? ? location.order : (index || 0) + 1
  end

  def currency(number)
    number_to_currency(number, precision: 0)
  end

  def chart_data(name, data)
    { name: name, data: normalize(data) }
  end

  # Normalize graphing data
  def normalize(data)
    values = data.values
    xMin,xMax = values.minmax
    dx = (xMax - xMin).to_f
    values.map! { |x| (x - xMin) / dx }
    data.each_with_index { |(key, value), index| data[key] = values[index] }
  end
end
