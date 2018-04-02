defimpl Ecto.LoggerJSON.StructParser, for: Decimal do
  def parse(value), do: Decimal.to_string(value)
end
