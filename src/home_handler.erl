-module(home_handler).
-export([init/3]).
-export([handle/2,terminate/3]).
-behaviour(cowboy_http_handler).

init({tcp,http}, Req, []) ->
	{ok, Req, undefined_state}.

handle(Req, St) ->
	erlydtl:compile("./priv/templates/home.dtl", home_template),

	{ok,Body} = home_template:render(),

	{ok,Reply} = cowboy_req:reply(200,[], Body, Req),

	{ok,Reply,St}.	%% never reached

terminate(_What, _Req, _St) ->
	ok.

%%EOF
