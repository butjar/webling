-module(stream_ws_handler).
-behaviour(cowboy_websocket_handler).
-export([init/3,
		websocket_init/3,
		websocket_handle/3,
		websocket_info/3,
		websocket_terminate/3]).

-record(state, {
			streamer = none
		}).

-record(streamer, {
            pid,
            connected_listeners = [],
            stream_name,
            lat,
            long,
            desc
        }).

init({tcp, http}, _Req, _Opts) ->
    {upgrade, protocol, cowboy_websocket}.
 
websocket_init(_TransportName, Req, _Opts) ->
    State = #state{},
    {ok, Req, State}.
websocket_handle({text, <<"stop_streamer">>}, Req, State) ->
    NewState = State#state{streamer = none},
    noiseling_server:kill_streamer(State#state.streamer#streamer.pid),
    {reply, {text, <<"streamer_stopped">>}, Req, NewState};
websocket_handle({text, Msg}, Req, State) ->
    Struct = mochijson2:decode(Msg),
    {struct, JsonData} = Struct,
    case JsonData of
        [{<<"start_streamer">>, {struct,StreamerIoList}}] ->
        	StreamName = binary_to_list(proplists:get_value(<<"stream_name">>, StreamerIoList)),
        	Lat = binary_to_list(proplists:get_value(<<"lat">>, StreamerIoList)),
        	Long = binary_to_list(proplists:get_value(<<"lon">>, StreamerIoList)),
        	Desc = binary_to_list(proplists:get_value(<<"desc">>, StreamerIoList)),
    		{ok, {streamer, Streamer}} = noiseling_server:start_streamer(StreamName, Lat, Long, Desc),
    		NewState = State#state{streamer = Streamer},
    		{reply, {text, <<"streamer_started">>}, Req, NewState}
    end;
websocket_handle({binary, Data}, Req, State) ->
	case State#state.streamer of
		none -> true;
		Streamer ->
			Streamer#streamer.pid ! Data
	end,
	{ok, Req, State}.

websocket_info(_Info, Req, State) ->
    {ok, Req, State}.
 
websocket_terminate(_Reason, _Req, State) ->
	case State#state.streamer of
		none -> true;
		_Any -> ok = noiseling_server:kill_streamer(State#state.streamer#streamer.pid)
	end,
    ok.