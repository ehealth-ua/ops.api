defmodule OPS.Seed.API do
  @primary_key false

  import Ecto.Query

  alias OPS.Seed.Schema, as: Seed

  def get_or_create_seed(date) do
    Repo.transaction fn ->
      get_seed(date) || create_seed(date)
    end
  end

  def get_seed(date) do
    seed_query = from s in Seed,
      where: fragment("date(?) = ?", s.inserted_at, ^date)

    SeedRepo.one(seed_query)
  end

  def create_seed(date) do
    payload = %Seed{
      hash: calculated_hash(date)
    }

    SeedRepo.insert(payload)
  end

  def calculated_hash(date) do

  end
end
