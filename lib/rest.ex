defmodule Slugmenu.RestServer do
  alias Slugmenu.Registry, as: SR
  alias Slugmenu.Bucket, as: SB
  use Urna

  @nine   "nine"
  @eight  "eight"
  @cowell "cowell"
  @porter "porter"
  @crown  "crown"

  def start_link do
    SR.create(SR, @nine)
    SR.create(SR, @eight)
    SR.create(SR, @cowell)
    SR.create(SR, @porter)
    SR.create(SR, @crown)

    :hackney.start
    IO.puts "Accepting rest requests on port 8080"
    Urna.start(Slugmenu.RestServer, port: 8080)
  end

  defp add_to_avg(item, {len, avg}) do
    new_len = len+1
    new_avg = (avg*len/new_len) + item/new_len
    {len+1, new_avg}
  end

  defp get_rating!(bucket, food) do
    case SB.get(bucket, food) do
      {l, r} -> {l, r}
      _ -> SB.put_and_get(bucket, food, {1, 2.5})
    end
  end

  defp api_get_rating(dh, food) do
    {:ok, bucket} = SR.lookup(SR, dh)
    {_len, rating} = get_rating!(bucket, food)
    %{status: "ok",
      rating: rating}
  end

  defp api_post_rating(dh, food, rating) do
    {:ok, bucket} = SR.lookup(SR, dh)
    SB.update(bucket, food, fn old ->
      rating |> add_to_avg(old||{1,2.5}) end)
      {_len, rating} = SB.get(bucket, food)
      %{status: "ok",
        rating: rating}
  end

  #iex> HTTPoison.get! "localhost:8080/ratings/nine/pizza"
  #iex> HTTPoison.post!("localhost:8080/ratings/nine/pizza", "{\"rating\": 5}", %{"Content-type" => "application/json"}).body
  namespace :ratings do
    resource :nine do
      get food do
        api_get_rating(@nine, food)
      end

      post food do
        api_post_rating(@nine, food, params["rating"])
      end
    end
    resource :eight do
      get food do
        api_get_rating(@eight, food)
      end

      post food do
        api_post_rating(@eight, food, params["rating"])
      end
    end
    resource :cowell do
      get food do
        api_get_rating(@cowell, food)
      end

      post food do
        api_post_rating(@cowell, food, params["rating"])
      end
    end
    resource :porter do
      get food do
        api_get_rating(@porter, food)
      end

      post food do
        api_post_rating(@porter, food, params["rating"])
      end
    end
    resource :crown do
      get food do
        api_get_rating(@crown, food)
      end

      post food do
        api_post_rating(@crown, food, params["rating"])
      end
    end
  end
end
