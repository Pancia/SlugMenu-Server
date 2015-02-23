defmodule Slugmenu.RestServer do
  alias Slugmenu.Registry, as: SR
  alias Slugmenu.Bucket, as: SB
  use Urna

  @nine   "nine"
  @eight  "eight"
  @cowell "cowell"
  @porter "porter"
  @crown  "crown"

  def start_link(opts \\ []) do
    SR.create(SR, @nine)
    SR.create(SR, @eight)
    SR.create(SR, @cowell)
    SR.create(SR, @porter)
    SR.create(SR, @crown)

    HTTPoison.start()
    IO.puts "Accepting http requests on port #{opts[:port]}"
    Urna.start(Slugmenu.RestServer, port: opts[:port])
  end

  defp add_to_avg(rating, user, {len, avg, usr_ratings}) do
    if Map.has_key?(usr_ratings, user)do
      new_avg = avg + rating/len - (usr_ratings[user])/len
      {len, new_avg, Map.put(usr_ratings, user, rating)}
    else
      new_len = len+1
      new_avg = (avg*len/new_len) + rating/new_len
      {len+1, new_avg, Map.put(usr_ratings, user, rating)}
    end
  end

  defp get_rating!(bucket, food) do
    case SB.get(bucket, food) do
      {l, r, u} -> {l, r, u}
      _ -> SB.put_and_get(bucket, food, {0,-1,%{}})
    end
  end

  defp api_get_avg_rating(dh, food) do
    {:ok, bucket} = SR.lookup(SR, dh)
    {_len, rating, _usr_ratings} = get_rating!(bucket, food)
    IO.puts "GET dh: #{dh}, food: #{food}, rating: #{rating}"
    %{status: "ok",
      rating: rating}
  end

  defp api_post_rating(dh, food, rating, user) do
    {:ok, bucket} = SR.lookup(SR, dh)
    SB.update(bucket, food, fn old ->
      rating |> add_to_avg(user, old||{0,-1,%{}}) end)
    {_len, rating, _usr_ratings} = SB.get(bucket, food)
    IO.puts "POST dh: #{dh}, food: #{food}, rating: #{rating}"
    %{status: "ok",
      rating: rating}
  end

  #iex> HTTPoison.get! "localhost:8080/ratings/nine/pizza"
  #iex> HTTPoison.post!("localhost:8080/ratings/nine/pizza", "{\"rating\": 5, \"user\": \"pancia\"}", %{"Content-type" => "application/json"}).body
  namespace :ratings do
    resource :nine do
      get food do
        api_get_avg_rating(@nine, food)
      end

      post food do
        api_post_rating(@nine, food, params["rating"], params["user"])
      end
    end
    resource :eight do
      get food do
        api_get_avg_rating(@eight, food)
      end

      post food do
        api_post_rating(@eight, food, params["rating"], params["user"])
      end
    end
    resource :cowell do
      get food do
        api_get_avg_rating(@cowell, food)
      end

      post food do
        api_post_rating(@cowell, food, params["rating"], params["user"])
      end
    end
    resource :porter do
      get food do
        api_get_avg_rating(@porter, food)
      end

      post food do
        api_post_rating(@porter, food, params["rating"], params["user"])
      end
    end
    resource :crown do
      get food do
        api_get_avg_rating(@crown, food)
      end

      post food do
        api_post_rating(@crown, food, params["rating"], params["user"])
      end
    end
  end
end
