/*
 * Irresistible Gaming 2018
 * Developed by Night
 * Module: cnr\features\boom_box.pwn
 * Purpose: boombox related feature
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define DEFAULT_BOOMBOX_RANGE 		( 50.0 )

/* ** Variables ** */
enum E_BOOMBOX_DATA
{
	E_OBJECT,		Text3D: E_LABEL, 	E_MUSIC_AREA,
	E_URL[ 128 ],
	Float: E_X,		Float: E_Y,			Float: E_Z
};

static stock
	g_boomboxData					[ MAX_PLAYERS ] [ E_BOOMBOX_DATA ]
;

/* ** Hooks ** */
hook OnPlayerDisconnect( playerid, reason )
{
	p_UsingBoombox{ playerid } = false;
	p_Boombox{ playerid } = false;
	Boombox_Destroy( playerid );
	return 1;
}

hook OnPlayerEnterDynArea( playerid, areaid )
{
	foreach ( new i : Player )
	{
		if ( IsValidDynamicArea( g_boomboxData[ i ][ E_MUSIC_AREA ] ) )
		{
			if ( areaid == g_boomboxData[ i ][ E_MUSIC_AREA ] )
			{
				// start the music
				PlayAudioStreamForPlayer( i, g_boomboxData[ playerid ][ E_URL ], g_boomboxData[ playerid ][ E_X ], g_boomboxData[ playerid ][ E_Y ], g_boomboxData[ playerid ][ E_Z ] );
				SendServerMessage( i, "You are now listening to a nearby boombox!" );
				return 1;
			}
		}
	}
	return 1;
}

hook OnPlayerLeaveDynArea( playerid, areaid )
{
	foreach ( new i : Player )
	{
		if ( IsValidDynamicArea( g_boomboxData[ i ][ E_MUSIC_AREA ] ) )
		{
			if ( areaid == g_boomboxData[ i ][ E_MUSIC_AREA ] )
			{
				// stop the music
				StopAudioStreamForPlayer( i );
				SendServerMessage( i, "You stopped listening to a nearby boombox!" );
				return 1;
			}
		}
	}
	return 1;
}

hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	if ( ( dialogid == DIALOG_BOOMBOX_PLAY ) && response )
	{
		static
			Float: X, Float: Y, Float: Z, Float: Angle;

		if ( GetPlayerPos( playerid, X, Y, Z ) && GetPlayerFacingAngle( playerid, Angle ) )
		{
			Boombox_Create( playerid, inputtext, X, Y, Z, Angle );

			p_UsingBoombox{ playerid } = true;
			PlayAudioStreamForPlayer( playerid, g_boomboxData[ playerid ][ E_URL ], X, Y, Z, 30, 1 );
	    	SendServerMessage( playerid, "If the stream doesn't respond then it must be offline. Use "COL_GREY"/stopboombox"COL_WHITE" to stop the stream." );
		}
	}

	return 1;
}

/* ** Commands ** */
CMD:boombox( playerid, params[ ] )
{
	if ( ! GetPlayerBoombox( playerid ) )
		return SendError( playerid, "You can buy Boombox at Supa Save or a 24/7 store." );
	if ( IsPlayerInAnyVehicle(playerid) )
		return SendError( playerid, "You cannot use Boombox inside of a vehicle.");

	if ( strmatch( params, "play" ) )
	{
		if ( IsPlayerUsingBoombox( playerid ) ) return SendError( playerid, "You are already using Boombox." );

		ShowPlayerDialog( playerid, DIALOG_BOOMBOX_PLAY, DIALOG_STYLE_INPUT, ""COL_WHITE"Boombox", ""COL_WHITE"Enter the URL below, and streaming will begin.\n\n"COL_ORANGE"Please note, if there isn't a response. It's likely to be an invalid URL.", "Stream", "Back" );
	}
	else if ( strmatch( params, "stop" ) )
	{
		if ( ! IsPlayerUsingBoombox( playerid ) ) return SendError( playerid, "You are not using Boombox." );

		StopAudioStreamForPlayer( playerid );
		Boombox_Destroy( playerid );
		SendServerMessage( playerid, "You have removed your Boombox.");
		p_UsingBoombox{ playerid } = false;
	}
	else SendUsage( playerid, "/boombox [PLAY/STOP]" );
	return 1;
}

/* ** Functions ** */
stock IsPlayerUsingBoombox( playerid ) return p_UsingBoombox{ playerid };

stock GetPlayerBoombox( playerid ) return p_Boombox{ playerid };

stock Boombox_Destroy( playerid )
{
	g_boomboxData[ playerid ] [ E_X ] = 0.0;
	g_boomboxData[ playerid ] [ E_Y ] = 0.0;
	g_boomboxData[ playerid ] [ E_Z ] = 0.0;
	g_boomboxData[ playerid ] [ E_URL ][ 0 ] = '\0';

	DestroyDynamicObject( g_boomboxData[ playerid ] [ E_OBJECT ] );
	DestroyDynamic3DTextLabel( g_boomboxData[ playerid ] [ E_LABEL ] );
	DestroyDynamicArea( g_boomboxData[ playerid ] [ E_MUSIC_AREA ] );
	return 1;
}

stock Boombox_Create( playerid, szURL[ ], Float: X, Float: Y, Float: Z, Float: Angle, Float: fDistance = DEFAULT_BOOMBOX_RANGE )
{
	format( g_boomboxData[ playerid ][ E_URL ], 128, "%s", szURL );

	g_boomboxData[ playerid ] [ E_OBJECT ] = CreateDynamicObject( 2226, X, Y, Z - 0.92, 0, 0, 0, GetPlayerVirtualWorld( playerid ), GetPlayerInterior( playerid ), -1, Angle );
	g_boomboxData[ playerid ] [ E_LABEL ] = CreateDynamic3DTextLabel( sprintf( "Owner: %s(%d)", ReturnPlayerName( playerid ), playerid ), COLOR_GOLD, X, Y, Z+0.1, 10, .worldid = GetPlayerVirtualWorld( playerid ), .interiorid = GetPlayerInterior( playerid ) );
	g_boomboxData[ playerid ] [ E_MUSIC_AREA ] = CreateDynamicSphere( X, Y, Z, fDistance, .worldid = GetPlayerVirtualWorld( playerid ), .interiorid = GetPlayerInterior( playerid ) );
	return 1;
}