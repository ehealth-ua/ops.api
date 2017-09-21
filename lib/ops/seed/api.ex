defmodule OPS.Seed.API do
  @primary_key false

  import Ecto.Query

  alias OPS.Seed.Schema, as: Seed

  def get_or_create_seed(date) do
    get_seed(date) || create_seed(date)
  end

  def get_seed(date) do
    seed_query = from s in Seed,
      where: fragment("date(?) = ?", s.inserted_at, date)

    SeedRepo.one(seed_query)
  end

  def create_seed(date) do
    payload = %Seed{
      hash: calculated_hash
    }

    SeedRepo.insert(payload)
  end
end
