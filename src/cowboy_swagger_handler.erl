%%% @doc Cowboy Swagger Handler. This handler exposes a GET operation
%%%      to enable `swagger.json' to be retrieved from embedded
%%%      Swagger-UI (located in `priv/swagger' folder).
-module(cowboy_swagger_handler).

%% Trails
-behaviour(trails_handler).
-export([trails/0, trails/1]).

-type route_match() :: '_' | iodata().
-export_type([route_match/0]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Trails
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% @hidden
%% @doc Implements `trails_handler:trails/0' callback. This function returns
%%      trails routes for both: static content (Swagger-UI) and this handler
%%      that returns the `swagger.json'.
-spec trails() -> trails:trails().
trails() -> trails(#{}).
-spec trails(cowboy_swagger_json_handler:options()) -> trails:trails().
trails(Options) ->
  StaticFiles =
    case application:get_env(cowboy_swagger, static_files) of
      {ok, Val} -> Val;
      _         -> filename:join(cowboy_swagger_priv(), "swagger")
    end,
  Redirect = trails:trail(
    "/api-docs",
    cowboy_swagger_redirect_handler,
    {file, StaticFiles ++ "/index.html"},
    #{get => #{hidden => true}}),
  Static = trails:trail(
    "/api-docs/[...]",
    cowboy_static,
    {dir, StaticFiles, [{mimetypes, cow_mimetypes, all}]},
    #{get => #{hidden => true}}),
  MD = #{get => #{hidden => true}},
  Handler1 = trails:trail(
    "/api-docs/apps/gmc", cowboy_swagger_json_handler, Options, MD),
  Handler2 = trails:trail(
    "/api-docs/apps/butler_server", cowboy_swagger_json_handler, Options, MD),
  Handler3 = trails:trail(
    "/api-docs/apps/pick", cowboy_swagger_json_handler, Options, MD),
  [Redirect, Handler1, Handler2, Handler3, Static].

%% @private
-spec cowboy_swagger_priv() -> string().
cowboy_swagger_priv() ->
  case code:priv_dir(cowboy_swagger) of
    {error, bad_name} ->
      case code:which(cowboy_swagger_handler) of
        cover_compiled -> "../../priv"; % required for tests to work
        BeamPath -> filename:join([filename:dirname(BeamPath) , ".." , "priv"])
      end;
    Path -> Path
  end.