require 'pg'
require 'pry'
require 'sinatra'

def db_connection
  begin
    connection = PG.connect(dbname: 'movies')

    yield(connection)

  ensure
    connection.close
  end
end

get '/' do

  erb :index
end

get '/actors' do
  @query = params["actor_query"]

  if params["actor_query"]
    sql = "SELECT name, cast_members.character FROM actors
    JOIN cast_members ON cast_members.actor_id = actors.id
    WHERE actors.name ILIKE '%#{@query}%'
    ORDER BY name ASC"
  else
    sql = "SELECT name FROM actors ORDER BY name ASC"
  end

  @result =  db_connection do |conn|
    conn.exec(sql)
  end
  @result = @result.to_a

  erb :'/actors/index'
end

get '/actors/:id' do

  @actor = params[:id]

  sql = "SELECT movies.title FROM movies
  JOIN cast_members ON cast_members.movie_id = movies.id
  JOIN actors ON actors.id = cast_members.actor_id
  WHERE actors.name = $1"

  @result =  db_connection do |conn|
    conn.exec(sql,[@actor])
  end
  @result = @result.to_a

  erb :'/actors/show'
end

get '/movies' do

   @page = params[:page] ? params[:page].to_i : 1
   @order = params["order"] || "movies.title"
   @query = params["query"]

  if @page && @page != 1
    @offsetby = (@page.to_i - 1)*20 - 1
  else
    @offsetby = 0
  end

if params["query"]
  sql = "SELECT movies.title, movies.year, movies.rating, genres.name, studios.name FROM movies
  JOIN genres ON genres.id = movies.genre_id
  JOIN studios ON studios.id = movies.studio_id
  WHERE movies.title ILIKE '%#{@query}%'
  ORDER BY #{@order} ASC
  LIMIT 20 OFFSET #{@offsetby}"

else

  sql = "SELECT movies.title, movies.year, movies.rating, genres.name, studios.name FROM movies
  JOIN genres ON genres.id = movies.genre_id
  JOIN studios ON studios.id = movies.studio_id
  ORDER BY #{@order} ASC
  LIMIT 20 OFFSET #{@offsetby}"
end
  @result =  db_connection do |conn|
    conn.exec(sql)
  end
  @result = @result.to_a

  erb :'/movies/index'
end


get '/movies/:id' do

  @movie = params[:id]

  sql_genre = "SELECT movies.title, genres.name FROM movies
  JOIN genres ON movies.genre_id = genres.id
  WHERE movies.title = $1"

  @result_genre = db_connection do |conn|
    conn.exec(sql_genre, [@movie])
  end
  @result_genre = @result_genre.to_a


  sql_studio = "SELECT movies.title, studios.name FROM movies
  JOIN studios ON movies.studio_id = studios.id
  WHERE movies.title = $1"

  @result_studio = db_connection do |conn|
    conn.exec(sql_studio, [@movie])
  end
  @result_studio = @result_studio.to_a

  sql = "SELECT movies.title, actors.name, cast_members.character FROM movies
  JOIN cast_members ON cast_members.movie_id = movies.id
  JOIN actors ON actors.id = cast_members.actor_id
  WHERE movies.title = $1"

  @result =  db_connection do |conn|
    conn.exec(sql,[@movie])
  end
  @result = @result.to_a

  erb :'/movies/show'
end
