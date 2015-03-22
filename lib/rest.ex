defmodule Slugmenu.RestServer do
  alias Slugmenu.Registry, as: SR
  alias Slugmenu.Bucket, as: SB
  use Urna
  use Timex

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
    :ets.new(:menu_cache, [:named_table, :public])
    IO.puts "Accepting http requests on port #{opts[:port]}"
    Urna.start(Slugmenu.RestServer, port: opts[:port])
  end


  # Mapping from dh to locationNum, see: get_html_menu
  @dh_to_url [nine: "30", eight: "30", cowell: "05", porter: "25", crown: "20"]
  @base_ucsc_dh_url "http://nutrition.sa.ucsc.edu/menuSamp.asp?myaction=read"

  defp attr_eq(html, attr, eq) do
    case Floki.attribute(html, attr) do
      [] -> false
      [x] -> x == eq
    end
  end

  defp valid_elem(html) do
    has_valid_with = attr_eq(html, "width", "30%")
                 || attr_eq(html, "width", "50%")
                 || attr_eq(html, "width", "100%")
    has_valid_valign = attr_eq(html, "valign", "top")
    has_valid_with && has_valid_valign
  end

  defp parse_meal(html) do
    Floki.find(html, ".menusamprecipes div span")
    |> Enum.map(fn ({_,_,text}) -> text end)
    |> List.flatten
  end

  defp fmt_dtdate(dtdate) do
    {dtdate,_} = Integer.parse(dtdate)
    Date.local
    |> Date.shift(days: dtdate)
    |> DateFormat.format!("%m/%d/%Y", :strftime)
  end

  defp parse_html_menu(html) do
    title = Floki.find(html, "title") |> Floki.text

    html_menu = Floki.find(html, "td") |> Enum.filter(&valid_elem/1)
    meal_names = Enum.map(html_menu, &(Floki.find(&1, ".menusampmeals") |> Floki.text))
    menus = html_menu |> Enum.map(&parse_meal/1)

    Stream.zip(meal_names, menus)
    |> Enum.map(fn {title,menu} -> Map.put(%{}, title, menu) end)
    |> List.foldr(%{}, &Dict.merge/2) |> Map.put(:title, title)
  end

  defp get_html_menu(dh_loc_num, dtdate) do
    final_ucsc_dh_url = @base_ucsc_dh_url
                        <> "&locationNum=#{dh_loc_num}"
                        <> "&dtdate=#{fmt_dtdate dtdate}"
    HTTPoison.get!(final_ucsc_dh_url).body
  end

  defp get_menu(dh_loc_num, dtdate, dh) do
    t = Time.now
    ets_menu_key = "#{dh_loc_num}-#{fmt_dtdate dtdate}"
    {found, menu} = case :ets.lookup(:menu_cache, ets_menu_key) do
      [] -> {false, get_html_menu(dh_loc_num, dtdate) |> parse_html_menu}
      [{_key,menu}] -> {true, menu}
    end
    menu = Dict.put(menu, "dh", Atom.to_string dh)
    if not found do
      :ets.insert(:menu_cache, {ets_menu_key, menu})
    end
    menu = Dict.put(menu, "elapsed", Time.elapsed(t, :msecs))
    menu
  end

  namespace :menu do
    resource :nine do
      get dtdate do
        get_menu(@dh_to_url[:nine], dtdate, :nine)
      end
    end
    resource :eight do
      get dtdate do
        get_menu(@dh_to_url[:eight], dtdate, :eight)
      end
    end
    resource :cowell do
      get dtdate do
        get_menu(@dh_to_url[:cowell], dtdate, :cowell)
      end
    end
    resource :porter do
      get dtdate do
        get_menu(@dh_to_url[:porter], dtdate, :porter)
      end
    end
    resource :crown do
      get dtdate do
        get_menu(@dh_to_url[:crown], dtdate, :crown)
      end
    end
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
    #TODO:? SB.put(bucket, "_last_mod_", Time.now(:msecs))
    {_len, rating, _usr_ratings} = SB.get(bucket, food)
    IO.puts "POST dh: #{dh}, food: #{food}, rating: #{rating}"
    %{status: "ok",
      rating: rating}
  end

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
