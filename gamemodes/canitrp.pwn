#pragma warning disable 239
#pragma warning disable 214

#include <a_samp>
#undef MAX_PLAYERS
#define MAX_PLAYERS (50)
#include <crashdetect>
#define FIXES_Single 1
#define FIX_GetPlayerDialog 1
#define FIX_file_inc 1
#define FIX_random 1
#define FIX_HideMenuForPlayer_2 1
#define FIX_GameTextStyles 1
#define FIX_GetPlayerWeather 1
#define FIX_GetWeather 1
#define FIX_GetWorldTime 1
#include <fixes>
#include <sscanf2>
#include <streamer>
#define DEBUG
#include <nex-ac_ru.lang>
#include <nex-ac>
#include <timerfix.inc>
#include <kickfix.inc>
#include <mapfix.inc>
#include <a_mysql>
#define MYSQL_HOST "127.0.0.1"
#define MYSQL_USER "root"
#define MYSQL_PASSWORD "root"
#define MYSQL_DATABASE "samp_canitrp"
new MySQL:db_connection;
#include <bcrypt>
#define BCRYPT_COST (12)
#include <Pawn.Regex>
#include <Pawn.CMD>
#define NULL_CHAR (1)

main()
{
	print("\n");
	print(" Canit Role Play");
	print(" version 0.01");
	print(" developer: SOLN4R");
	print("\n");
}

new Text:td_server_logo_TD[2];

enum dialog_id 
{
	NO_RESPONSE,
	REG_GREETING,
	REG_PASSWORD,
	REG_GENDER,
	REG_SKIN_COLOR,
	AUTH_PASSWORD
}

enum virtual_world_id
{
	VW_MAIN
}

enum interior_id
{
	I_MAIN
}

enum player_data 
{
	bool:is_authorized,
	password_attempts,
	id,
	nickname[MAX_PLAYER_NAME + NULL_CHAR],
	password_hash[64 + NULL_CHAR],
	bool:gender,
	bool:skin_color,
	skin,
	reg_date[10 + NULL_CHAR],
	reg_ip[16 + NULL_CHAR],
	last_date[10 + NULL_CHAR],
	last_ip[16 + NULL_CHAR]
}
new player[MAX_PLAYERS][player_data];
new const CLEAR_PLAYER_DATA[player_data];

new authorization_timer[MAX_PLAYERS];

public OnGameModeInit()
{
	SetGameModeText("Role Play");
	DisableInteriorEnterExits();
    EnableStuntBonusForAll(0);
	ShowPlayerMarkers(PLAYER_MARKERS_MODE_STREAMED);
	AddPlayerClass(0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0, 0, 0, 0);
	LoadGlobalTextDraws();
	db_connection = mysql_connect(MYSQL_HOST, MYSQL_USER, MYSQL_PASSWORD, MYSQL_DATABASE);
	if(!mysql_errno(db_connection)) print(" [MySQL] Успешное подключение к базе данных.");
	else printf(" [MySQL] Неудачное подключение к базе данных (Код ошибки: %d).", mysql_errno(db_connection));
    mysql_log(ALL);
    mysql_set_charset("cp1251");
	return 1;
}

public OnGameModeExit()
{
	mysql_close(db_connection);
	return 1;
}

public OnPlayerConnect(playerid)
{
	player[playerid] = CLEAR_PLAYER_DATA;
	return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
	SetSpawnInfo(playerid, 0, 0, 869.3313, -1347.6652, 13.5646, 180.0, 0, 0, 0, 0, 0, 0);
	SpawnPlayer(playerid);
	return 1;
}

public OnPlayerRequestSpawn(playerid)
{
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	player[playerid] = CLEAR_PLAYER_DATA;
	return 1;
}

public OnPlayerSpawn(playerid)
{
	if(!player[playerid][is_authorized])
	{
		SetPlayerColor(playerid, 0x9c9c9c20);
		TogglePlayerSpectating(playerid, true);
		InterpolateCameraPos(playerid, 898.8760, -1096.9336, 90.0401, 900.7601, -1097.0145, 90.0494, 60*1000);
		InterpolateCameraLookAt(playerid, 899.8809, -1096.9768, 90.0451, 901.7650, -1097.0577, 90.0544, 60*1000);
		TextDrawShowForPlayer(playerid, td_server_logo_TD[0]);
		TextDrawShowForPlayer(playerid, td_server_logo_TD[1]);
		SendClientMessage(playerid, 0x0c84ffff, "Добро пожаловать на Canit Role Play!");
		GetPlayerName(playerid, player[playerid][nickname], MAX_PLAYER_NAME);
		static const query_fmt_str[] = "SELECT `id`, `password_hash` FROM `players` WHERE `nickname` = '%s' LIMIT 1";
		new query_string[sizeof(query_fmt_str) + (-2 + MAX_PLAYER_NAME)];
		format(query_string, sizeof(query_string), query_fmt_str, player[playerid][nickname]);
		mysql_tquery(db_connection, query_string, "AuthenticationRouter", "i", playerid);
		return 1;
	}
	SetPlayerSkin(playerid, player[playerid][skin]);
	SetPlayerPos(playerid, 869.3313, -1347.6652, 13.5646);
	SetPlayerFacingAngle(playerid, 180.0);
	SetCameraBehindPlayer(playerid);
	SetPlayerColor(playerid, 0xffffff20);
	return 1;
}

forward AuthenticationRouter(playerid);
public AuthenticationRouter(playerid)
{
	new rows;
    cache_get_row_count(rows);
	if(!rows) return DLG_REG_GREETING(playerid);

	new year, month, day;
	getdate(year, month, day);
	format(player[playerid][last_date], 10 + NULL_CHAR, "%02d.%02d.%02d", day, month, year);
	GetPlayerIp(playerid, player[playerid][last_ip], 16 + NULL_CHAR);

	cache_get_value_name_int(0, "id", player[playerid][id]);
	cache_get_value_name(0, "password_hash", player[playerid][password_hash], 64 + NULL_CHAR);
	authorization_timer[playerid] = SetPlayerTimer(playerid, "AuthoriaztionTimer", 60*1000, 0);
	return DLG_AUTH_PASSWORD(playerid);
}

forward AuthoriaztionTimer(playerid);
public AuthoriaztionTimer(playerid)
{
	SendClientMessage(playerid, 0xf0523aff, "Время на авторизацию вышло!");
	AddLog(playerid, "не смог авторизоваться. Причина: время на авторизацию вышло.");
	return Kick(playerid);
}

public OnPlayerDeath(playerid, killerid, reason)
{
	return 1;
}

public OnVehicleSpawn(vehicleid)
{
	return 1;
}

public OnVehicleDeath(vehicleid, killerid)
{
	return 1;
}

public OnPlayerText(playerid, text[])
{
	return 0;
}

public OnPlayerEnterVehicle(playerid, vehicleid, ispassenger)
{
	return 1;
}

public OnPlayerExitVehicle(playerid, vehicleid)
{
	return 1;
}

public OnPlayerStateChange(playerid, newstate, oldstate)
{
	return 1;
}

public OnPlayerEnterCheckpoint(playerid)
{
	return 1;
}

public OnPlayerLeaveCheckpoint(playerid)
{
	return 1;
}

public OnPlayerEnterRaceCheckpoint(playerid)
{
	return 1;
}

public OnPlayerLeaveRaceCheckpoint(playerid)
{
	return 1;
}

public OnRconCommand(cmd[])
{
	return 1;
}

public OnObjectMoved(objectid)
{
	return 1;
}

public OnPlayerObjectMoved(playerid, objectid)
{
	return 1;
}

public OnPlayerPickUpPickup(playerid, pickupid)
{
	return 1;
}

public OnVehicleMod(playerid, vehicleid, componentid)
{
	return 1;
}

public OnVehiclePaintjob(playerid, vehicleid, paintjobid)
{
	return 1;
}

public OnVehicleRespray(playerid, vehicleid, color1, color2)
{
	return 1;
}

public OnPlayerSelectedMenuRow(playerid, row)
{
	return 1;
}

public OnPlayerExitedMenu(playerid)
{
	return 1;
}

public OnPlayerInteriorChange(playerid, newinteriorid, oldinteriorid)
{
	return 1;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	return 1;
}

public OnRconLoginAttempt(ip[], password[], success)
{
	return 1;
}

public OnPlayerUpdate(playerid)
{
	return 1;
}

public OnPlayerStreamIn(playerid, forplayerid)
{
	return 1;
}

public OnPlayerStreamOut(playerid, forplayerid)
{
	return 1;
}

public OnVehicleStreamIn(vehicleid, forplayerid)
{
	return 1;
}

public OnVehicleStreamOut(vehicleid, forplayerid)
{
	return 1;
}

public OnPlayerClickPlayer(playerid, clickedplayerid, source)
{
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	switch(dialogid)
	{
		case REG_GREETING:
		{
			if(!response) return Kick(playerid);
			return DLG_REG_PASSWORD(playerid);
		}
		case REG_PASSWORD:
		{
			if(!response) return DLG_REG_GREETING(playerid);

			if(!strlen(inputtext)) return DLG_REG_PASSWORD(playerid);

			static Regex:regex;
			if (!regex) regex = Regex_New("[A-Za-z0-9]+");
			if(!Regex_Check(inputtext, regex)) {
				PlayerPlaySound(playerid, 45400, 0.0, 0.0, 0.0);
				return DLG_REG_PASSWORD(playerid, "\n\n{f0523a} Вы ввели запрещенный символ!");
			}

			if(strlen(inputtext) < 6) {
				PlayerPlaySound(playerid, 45400, 0.0, 0.0, 0.0);
				return DLG_REG_PASSWORD(playerid, "\n\n{f0523a} Вы ввели слишком короткий пароль!");
			}

			if(strlen(inputtext) > 64) {
				PlayerPlaySound(playerid, 45400, 0.0, 0.0, 0.0);
				return DLG_REG_PASSWORD(playerid, "\n\n{f0523a} Вы ввели слишком длинный пароль!");
			}

			bcrypt_hash(inputtext, BCRYPT_COST, "RegistrationPasswordHashed", "d", playerid);
			return 1;
		}
		case REG_GENDER:
		{
			player[playerid][gender] = (response) ? (true) : (false);
			return DLG_REG_SKIN_COLOR(playerid);
		}
		case REG_SKIN_COLOR:
		{
			player[playerid][skin_color] = (response) ? (true) : (false);
			return REG_SKIN_SELECT(playerid);
		}
		case AUTH_PASSWORD:
		{
			if(!response)
			{
				AddLog(playerid, "вышел не авторизовавшись");
				return Kick(playerid);
			}

			if(!strlen(inputtext)) return DLG_AUTH_PASSWORD(playerid);

			static Regex:regex;
			if (!regex) regex = Regex_New("[A-Za-z0-9]+");
			if(!Regex_Check(inputtext, regex)) {
				PlayerPlaySound(playerid, 45400, 0.0, 0.0, 0.0);
				return DLG_AUTH_PASSWORD(playerid, "\n\n{f0523a} Вы ввели запрещенный символ!");
			}

			bcrypt_check(inputtext, player[playerid][password_hash],  "AuthorizationCheckPassword", "d", playerid);
		}
	}
	return 1;
}

stock DLG_REG_GREETING(playerid)
{
	static const fmt_str[] =
	"{E0E0E0}\
	Приветствуем лучшего среди лучших!\n\
    Никнейм: {F7E095}%s{E0E0E0}\n\
	Аккаунт {f0523a}не зарегистрирован{E0E0E0}.\n\
    Желаете начать процесс регистрации?";
    new string[sizeof(fmt_str) + (-2 + MAX_PLAYER_NAME)];
    format(string, sizeof(string), fmt_str, player[playerid][nickname]);
    ShowPlayerDialog(playerid, REG_GREETING, DIALOG_STYLE_MSGBOX, !"{0c84ff}Регистрация", string, !"{ffffff}Начать", !"{ffffff}Выйти");
	return 1;
}

stock DLG_REG_PASSWORD(playerid, error_message[] = "") 
{
	static const fmt_str[] =
	"{E0E0E0}\
	Придумайте и введите пароль от аккаунта.\n\
    Пароль будет запрашиваться при авторизации.\n\
    Рекомендуем использовать надежный пароль.\
	%s";
    new string[sizeof(fmt_str) + (-2 + 42 + NULL_CHAR)];
    format(string, sizeof(string), fmt_str, error_message);
    ShowPlayerDialog(playerid, REG_PASSWORD, DIALOG_STYLE_INPUT, !"{0c84ff}Регистрация", string, !"{ffffff}Далее", !"{ffffff}Назад");
	return 1;
}

forward RegistrationPasswordHashed(playerid);
public RegistrationPasswordHashed(playerid)
{
    new hash[BCRYPT_HASH_LENGTH];
    bcrypt_get_hash(hash);
	strmid(player[playerid][password_hash], hash, 0, BCRYPT_HASH_LENGTH);
    return DLG_REG_GENDER(playerid); 
}

stock DLG_REG_GENDER(playerid)
{
	ShowPlayerDialog(playerid, REG_GENDER, DIALOG_STYLE_MSGBOX, !"{0c84ff}Регистрация", !"{E0E0E0}Выберите пол персонажа.", !"{ffffff}Мужской", !"{ffffff}Женский");
	return 1;
}

stock DLG_REG_SKIN_COLOR(playerid)
{
	ShowPlayerDialog(playerid, REG_SKIN_COLOR, DIALOG_STYLE_MSGBOX, !"{0c84ff}Регистрация", !"{E0E0E0}Выберите цвет кожи персонажа.", !"{ffffff}Светлый", !"{ffffff}Темный");
	return 1;
}

stock REG_SKIN_SELECT(playerid)
{
	new men_skins[7] = { 78, 79, 134, 135, 137, 212, 230 };
	new woman_skins[2] = { 77, 201 };
	if(player[playerid][gender]) player[playerid][skin] = men_skins[random(7)];
	else player[playerid][skin] = player[playerid][skin] = woman_skins[random(2)];
	return REG_CREATE_ACCOUNT(playerid);
}

stock REG_CREATE_ACCOUNT(playerid)
{
	new year, month, day;
	getdate(year, month, day);
	format(player[playerid][reg_date], 10 + NULL_CHAR, "%02d.%02d.%02d", day, month, year);
	GetPlayerIp(playerid, player[playerid][reg_ip], 16 + NULL_CHAR);
	strmid(player[playerid][last_date], player[playerid][reg_date], 0, strlen(player[playerid][reg_date]));
	strmid(player[playerid][last_ip], player[playerid][reg_ip], 0, strlen(player[playerid][reg_ip]));

	static const query_fmt_str[] = "\
		INSERT INTO `players` (\
		`nickname`, `password_hash`,\
		`gender`, `skin_color`, `skin`, \
		`reg_date`, `reg_ip`, `last_date`, `last_ip`) \
		VALUES (\
		'%s', '%s',\
		'%d', '%d', '%d',\
		'%s', '%s', '%s', '%s')";
    new query_string[sizeof(query_fmt_str)
		+ (-2 + MAX_PLAYER_NAME) + (-2 + 64)
		+ (-2 + 1) + (-2 + 1) + (-2 + 1)
		+ (-2 + 10) + (-2 + 16) + (-2 + 10) + (-2 + 16)];
    format(query_string, sizeof(query_string), query_fmt_str,
		player[playerid][nickname], player[playerid][password_hash],
		player[playerid][gender], player[playerid][skin_color], player[playerid][skin],
		player[playerid][reg_date], player[playerid][reg_ip], player[playerid][last_date], player[playerid][last_ip]);
	mysql_tquery(db_connection, query_string, "CompletingRegistration", "i", playerid);
	return 1;
}

forward CompletingRegistration(playerid);
public CompletingRegistration(playerid)
{
	player[playerid][id] = cache_insert_id();
	player[playerid][is_authorized] = true;
	TogglePlayerSpectating(playerid, false);
	SendClientMessage(playerid, 0x33CC66FF, "Аккаунт зарегистрирован.");
	SendClientMessage(playerid, 0x33CC66FF, "Желаем приятной игры и хорошего настроеня!");
	AddLog(playerid, "зарегистрировался");
	return 1;
}

stock DLG_AUTH_PASSWORD(playerid, error_message[] = "") 
{
	static const fmt_str[] =
	"{E0E0E0}\
	Мы рады снова приветствовать Вас!\n\
    Никнейм: {F7E095}%s{E0E0E0}\n\
	Аккаунт {33CC66}зарегистрирован{E0E0E0}.\n\
    Введите пароль:%s";
    new string[sizeof(fmt_str) + (-2 + MAX_PLAYER_NAME) + (-2 + 40)];
    format(string, sizeof(string), fmt_str, player[playerid][nickname], error_message);
    ShowPlayerDialog(playerid, AUTH_PASSWORD, DIALOG_STYLE_PASSWORD, !"{0c84ff}Авторизация", string, !"{ffffff}Далее", !"{ffffff}Выйти");
	return 1;
}

forward AuthorizationCheckPassword(playerid);
public AuthorizationCheckPassword(playerid)
{
    new bool:match = bcrypt_is_equal();
	if(!match)
	{
		player[playerid][password_attempts]++;
		PlayerPlaySound(playerid, 45400, 0.0, 0.0, 0.0);
		if(player[playerid][password_attempts] >= 3)
		{
			SendClientMessage(playerid, 0xf0523aff, "Вы превысили допустимое количество ввода пароля!");
			AddLog(playerid, "не смог авторизоваться. Причина: неверный пароль.");
			return Kick(playerid);
		}
		return DLG_AUTH_PASSWORD(playerid, "\n\n{f0523a}Вы ввели неверный пароль!");
	}
	KillTimer(authorization_timer[playerid]);
	static const query_fmt_str[] = "SELECT * FROM `players` WHERE `nickname` = '%s' LIMIT 1";
	new query_string[sizeof(query_fmt_str) + (-2 + MAX_PLAYER_NAME)];
	format(query_string, sizeof(query_string), query_fmt_str, player[playerid][nickname]);
	mysql_tquery(db_connection, query_string, "CompletingAuthorization", "i", playerid);
    return 1;
}

forward CompletingAuthorization(playerid);
public CompletingAuthorization(playerid)
{
	cache_get_value_name_int(0, "gender", player[playerid][gender]);
	cache_get_value_name_int(0, "skin_color", player[playerid][skin_color]);
	cache_get_value_name_int(0, "skin", player[playerid][skin]);
	cache_get_value_name(0, "reg_date", player[playerid][reg_date], 10 + NULL_CHAR);
	cache_get_value_name(0, "reg_ip", player[playerid][reg_ip], 16 + NULL_CHAR);

	
	player[playerid][is_authorized] = true;
	TogglePlayerSpectating(playerid, false);

	static const query_fmt_str[] = "UPDATE `players` SET `last_date` = '%s', `last_ip` = '%s' WHERE `id` = %d LIMIT 1";
    new query_string[sizeof(query_fmt_str) + (-2 + 10) + (-2 + 16) + (-2 + 12)];
    format(query_string, sizeof(query_string), query_fmt_str, player[playerid][last_date], player[playerid][last_ip], player[playerid][id]);
    mysql_tquery(db_connection, query_string);

	AddLog(playerid, "авторизовался");
	return 1;
}


stock AddLog(playerid, action[])
{
	new
		day, month, year,
		hour, minute, second,
		date[10 + NULL_CHAR],
		time[8 + NULL_CHAR],
		current_ip[16 + NULL_CHAR],
		title[5 + NULL_CHAR] = "Игрок"; 

	getdate(year, month, day);
	gettime(hour,minute,second);
	format(date, 10 + NULL_CHAR, "%02d.%02d.%02d", day, month, year);
	format(time, 8 + NULL_CHAR, "%02d:%02d:%02d", hour, minute, second);
	GetPlayerIp(playerid, current_ip, 16 + NULL_CHAR);

	static const fmt_str[] = "%s %s[%d] %s.";
    new string[sizeof(fmt_str) + (-2 + 5) + (-2 + MAX_PLAYER_NAME) + (-2 + 12) + (-2 + 256)];
    format(string, sizeof(string), fmt_str, title, player[playerid][nickname], player[playerid][id], action);

	static const query_fmt_str[] =
		"INSERT INTO `logs` (`date`, `time`, `log`, `ip`) VALUES ('%s', '%s', '%s', '%s')";
	new query_string[sizeof(query_fmt_str) + (-2 + 10) + (-2 + 8) + (-2 + 294) + (-2 + 16)];
	format(query_string, sizeof(query_string), query_fmt_str, date, time, string, current_ip);
    mysql_tquery(db_connection, query_string);
	return 1;
}

stock LoadGlobalTextDraws()
{
	td_server_logo_TD[0] = TextDrawCreate(589.0000, 12.0000, "CANIT");
	TextDrawLetterSize(td_server_logo_TD[0], 0.4000, 1.6000);
	TextDrawAlignment(td_server_logo_TD[0], 1);
	TextDrawColor(td_server_logo_TD[0], 8126463);
	TextDrawBackgroundColor(td_server_logo_TD[0], 255);
	TextDrawFont(td_server_logo_TD[0], 1);
	TextDrawSetProportional(td_server_logo_TD[0], true);
	TextDrawSetShadow(td_server_logo_TD[0], 1);

	td_server_logo_TD[1] = TextDrawCreate(591.5000, 26.0000, "ROLE_PLAY");
	TextDrawLetterSize(td_server_logo_TD[1], 0.1976, 0.8657);
	TextDrawAlignment(td_server_logo_TD[1], 1);
	TextDrawColor(td_server_logo_TD[1], -1);
	TextDrawBackgroundColor(td_server_logo_TD[1], 255);
	TextDrawFont(td_server_logo_TD[1], 1);
	TextDrawSetProportional(td_server_logo_TD[1], true);
	TextDrawSetShadow(td_server_logo_TD[1], 1);
}

//! TEMP
public OnPlayerClickMap(playerid, Float:fX, Float:fY, Float:fZ)
{
	SetPlayerPos(playerid, fX, fY, fZ);
	return 1;
}

cmd:veh(playerid, params[]) {
	if(sscanf(params, "iii", params[0], params[1], params[2])) return SendClientMessage(playerid, -1, !"[CMD]: Используйте /veh [carid] [color1] [color2]");
	if(params[0] < 400 || params[0] > 611) return SendClientMessage(playerid, 0xbfbfbfff, !"[Ошибка]: ИД транспорта должен быть от 400 до 611.");
	if(params[1] < 0 || params[1] > 255 || params[2] < 0 || params[2] > 255) return SendClientMessage(playerid, 0xbfbfbfff, !"[Ошибка]: Цвета транспорта должны быть от 0 до 255.");
	new Float:pos_x_veh, Float:pos_y_veh, Float:pos_z_veh, Float:rot_veh;
	GetPlayerPos(playerid, pos_x_veh, pos_y_veh, pos_z_veh);
	GetPlayerFacingAngle(playerid, rot_veh);
	new vehid;
	vehid = AddStaticVehicleEx(params[0], pos_x_veh, pos_y_veh, pos_z_veh, rot_veh, params[1], params[2], -1);
	PutPlayerInVehicle(playerid, vehid, 0);
	return SendClientMessage(playerid, -1, !"[Информация]: Вы успешно создали транспорт.");
}

//! TEMP