class Numeric
  def bytes_to_kilobytes
    self / KILOBYTE
  end
  def bytes_to_megabytes
    self / KILOBYTE ** 2
  end
end
