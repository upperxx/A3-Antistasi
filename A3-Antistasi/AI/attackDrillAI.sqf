private _grupo = _this;
_objetivos = _grupo call A3A_fnc_enemyList;
_grupo setVariable ["objetivos",_objetivos];
_grupo setVariable ["tarea","Patrol"];
private _lado = side _grupo;
private _friendlies = if ((_lado == malos) or (_lado == buenos)) then {[_lado,civilian]} else {[_lado]};
_morteros = [];
_mgs = [];
_movable = [leader _grupo];
_baseOfFire = [leader _grupo];
_flankers = [];

{
if (alive _x) then
	{
	_result = _x call A3A_fnc_typeOfSoldier;
	_x setVariable ["maniobrando",false];
	if (_result == "Normal") then
		{
		_movable pushBack _x;
		_flankers pushBack _x;
		}
	else
		{
		if (_result == "StaticMortar") then
			{
			_morteros pushBack _x;
			}
		else
			{
			if (_result == "StaticGunner") then
				{
				_mgs pushBack _x;
				};
			_movable pushBack _x;
			_baseOfFire pushBack _x;
			};
		};
	};
} forEach (units _grupo);

if (count _morteros == 1) then
	{
	_morteros append ((units _grupo) select {_x getVariable ["typeOfSoldier",""] == "StaticBase"});
	if (count _morteros > 1) then
		{
		//_morteros spawn A3A_fnc_mortarDrill;
		_morteros spawn A3A_fnc_staticMGDrill;//no olvides borrar la otra función si esto funciona
		}
	else
		{
		_movable pushBack (_morteros select 0);
		_flankers pushBack (_morteros select 0);
		};
	};
if (count _mgs == 1) then
	{
	_mgs append ((units _grupo) select {_x getVariable ["typeOfSoldier",""] == "StaticBase"});
	if (count _mgs == 2) then
		{
		_mgs spawn A3A_fnc_staticMGDrill;
		}
	else
		{
		_movable pushBack (_mgs select 0);
		_flankers pushBack (_mgs select 0);
		};
	};

_grupo setVariable ["movable",_movable];
_grupo setVariable ["baseOfFire",_baseOfFire];
_grupo setVariable ["flankers",_flankers];
if (side _grupo == buenos) then {_grupo setVariable ["autoRearmed",time + 300]};
{
if (vehicle _x != _x) then
	{
	if !(vehicle _x isKindOf "Air") then
		{
		if ((assignedVehicleRole _x) select 0 == "Cargo") then
			{
			if (isNull(_grupo getVariable ["transporte",objNull])) then {_grupo setVariable ["transporte",vehicle _x]};
			};
		};
	};
} forEach units _grupo;

while {true} do
	{
	if !(isPlayer (leader _grupo)) then
		{
		_movable = _movable select {[_x] call A3A_fnc_canFight};
		_baseOfFire = _baseOfFire select {[_x] call A3A_fnc_canFight};
		_flankers = _flankers select {[_x] call A3A_fnc_canFight};
		_objetivos = _grupo call A3A_fnc_enemyList;
		_grupo setVariable ["objetivos",_objetivos];
		if !(_objetivos isEqualTo []) then
			{
			_aire = objNull;
			_tanques = objNull;
			{
			_eny = assignedVehicle (_x select 4);
			if (_eny isKindOf "Tank") then
				{
				_tanques = _eny;
				}
			else
				{
				if (_eny isKindOf "Air") then
					{
					if (count (weapons _eny) > 1) then
						{
						_aire = _eny;
						};
					};
				};
			if (!(isNull _aire) and !(isNull _tanques)) exitWith {};
			} forEach _objetivos;
			_lider = leader _grupo;
			_allNearFriends = allUnits select {(_x distance _lider < (distanciaSPWN/2)) and (side group _x in _friendlies)};
			{
			_unit = _x;
			{
			_objetivo = _x select 4;
			if (_lider knowsAbout _objetivo >= 1.4) then
				{
				_know = _unit knowsAbout _objetivo;
				if (_know < 1.2) then {_unit reveal [_objetivo,(_know + 0.2)]};
				};
			} forEach _objetivos;
			} forEach (_allNearFriends select {_x == leader _x}) - [_lider];
			_numNearFriends = count _allNearFriends;
			//_aire = objNull;
			//_tanques = objNull;
			_numObjetivos = count _objetivos;
			_tarea = _grupo getVariable ["tarea","Patrol"];
			_cercano = _grupo call A3A_fnc_enemigoCercano;
			_soldados = ((units _grupo) select {[_x] call A3A_fnc_canFight}) - [_grupo getVariable ["mortero",objNull]];
			_numSoldados = count _soldados;
			if !(isNull _aire) then
				{
				if (_allNearFriends findIf {(_x call A3A_fnc_typeOfSoldier == "AAMan") or (_x call A3A_fnc_typeOfSoldier == "StaticGunner")} == -1) then
					{
					if (_lado != buenos) then {[[getPosASL _lider,_lado,"Air",false],"A3A_fnc_patrolCA"] remoteExec ["A3A_fnc_scheduler",2]};
					};
				//_nuevaTarea = ["Hide",_soldados - (_soldados select {(_x call A3A_fnc_typeOfSoldier == "AAMan") or (_x getVariable ["typeOfSoldier",""] == "StaticGunner")})];
				_grupo setVariable ["tarea","Hide"];
				_tarea = "Hide";
				};
			if !(isNull _tanques) then
				{
				if (_allNearFriends findIf {_x call A3A_fnc_typeOfSoldier == "ATMan"} == -1) then
					{
					_mortero = _grupo getVariable ["morteros",objNull];
					if (!(isNull _mortero) and ([_mortero] call A3A_fnc_canFight)) then
						{
						if ({if (_x distance _tanques < 100) exitWith {1}} count _allNearFriends == 0) then {[_mortero,getPosASL _tanques,4] spawn A3A_fnc_mortarSupport};
						}
					else
						{
						if (_lado != buenos) then {[[getPosASL _lider,_lado,"Tank",false],"A3A_fnc_patrolCA"] remoteExec ["A3A_fnc_scheduler",2]};
						};
					};
				//_nuevaTarea = ["Hide",_soldados - (_soldados select {(_x getVariable ["typeOfSoldier",""] == "ATMan")})];
				_grupo setVariable ["tarea","Hide"];
				_tarea = "Hide";
				};
			if (_numObjetivos > 2*_numNearFriends) then
				{
				if !(isNull _cercano) then
					{
					if (_lado != buenos) then {[[getPosASL _lider,_lado,"Normal",false],"A3A_fnc_patrolCA"] remoteExec ["A3A_fnc_scheduler",2]};
					_mortero = _grupo getVariable ["morteros",objNull];
					if (!(isNull _mortero) and ([_mortero] call A3A_fnc_canFight)) then
						{
						if ({if (_x distance _cercano < 100) exitWith {1}} count _allNearFriends == 0) then {[_mortero,getPosASL _cercano,1] spawn A3A_fnc_mortarSupport};
						};
					};
				_grupo setVariable ["tarea","Hide"];
				_tarea = "Hide";
				};
			_transporte = _grupo getVariable ["transporte",objNull];
			if (isNull(_grupo getVariable ["transporte",objNull])) then
				{
				_exit = false;
				{
				_veh = vehicle _x;
				if (_veh != _x) then
					{
					if !(_veh isKindOf "Air") then
						{
						if ((assignedVehicleRole _x) select 0 == "Cargo") then
							{
							_grupo setVariable ["transporte",_veh];
							_transporte = _veh;
							_exit = true;
							};
						};
					};
				if (_exit) exitWith {};
				} forEach units _grupo;
				};
			if !(isNull(_transporte)) then
				{
				if !(_transporte isKindOf "Tank") then
					{
					_driver = driver (_transporte);
					if !(isNull _driver) then
						{
						[_driver]  allowGetIn false;
						};
					};
				(units _grupo select {(assignedVehicleRole _x) select 0 == "Cargo"}) allowGetIn false;
				};

			if (_tarea == "Patrol") then
				{
				if ((_cercano distance _lider < 150) and !(isNull _cercano)) then
					{
					_grupo setVariable ["tarea","Assault"];
					_tarea = "Assault";
					}
				else
					{
					if (_numObjetivos > 1) then
						{
						_mortero = _grupo getVariable ["morteros",objNull];
						if (!(isNull _mortero) and ([_mortero] call A3A_fnc_canFight)) then
							{
							if ({if (_x distance _cercano < 100) exitWith {1}} count _allNearFriends == 0) then {[_mortero,getPosASL _cercano,1] spawn A3A_fnc_mortarSupport};
							};
						};
					};
				};

			if (_tarea == "Assault") then
				{
				if (_cercano distance _lider < 50) then
					{
					_grupo setVariable ["tarea","AssaultClose"];
					_tarea = "AssaultClose";
					}
				else
					{
					if (_cercano distance _lider > 150) then
						{
						_grupo setVariable ["tarea","Patrol"];
						}
					else
						{
						if !(isNull _cercano) then
							{
							{
							[_x,_cercano] call A3A_fnc_fuegoSupresor;
							} forEach _baseOfFire select {(_x getVariable ["typeOfSoldier",""] == "MGMan") or (_x getVariable ["typeOfSoldier",""] == "StaticGunner")};
							if (sunOrMoon < 1) then
								{
								if !(haveNV) then
									{
									if (hayIFA) then
										{
										if (([_lider] call A3A_fnc_canFight) and ((typeOf _lider) in squadLeaders)) then {[_lider,_cercano] call A3A_fnc_useFlares}
										}
									else
										{
										{
										[_x,_cercano] call A3A_fnc_fuegoSupresor;
										} forEach _baseOfFire select {(_x getVariable ["typeOfSoldier",""] == "Normal") and (count (getArray (configfile >> "CfgWeapons" >> primaryWeapon _x >> "muzzles")) == 2)};
										};
									};
								};
							_mortero = _grupo getVariable ["morteros",objNull];
							if (!(isNull _mortero) and ([_mortero] call A3A_fnc_canFight)) then
								{
								if ({if (_x distance _cercano < 100) exitWith {1}} count _allNearFriends == 0) then {[_mortero,getPosASL _cercano,1] spawn A3A_fnc_mortarSupport};
								};
							};
						};
					};
				};

			if (_tarea == "AssaultClose") then
				{
				if (_cercano distance _lider > 150) then
					{
					_grupo setVariable ["tarea","Patrol"];
					}
				else
					{
					if (_cercano distance _lider > 50) then
						{
						_grupo setVariable ["tarea","Assault"];
						}
					else
						{
						if !(isNull _cercano) then
							{
							_flankers = _flankers select {!(_x getVariable ["maniobrando",false])};
							if (count _flankers != 0) then
								{
								{
								[_x,_x,_cercano] spawn A3A_fnc_cubrirConHumo;
								} forEach (_baseOfFire select {(_x getVariable ["typeOfSoldier",""] == "Normal")});
								if ([getPosASL _cercano] call A3A_fnc_isBuildingPosition) then
									{
									_ingeniero = objNull;
									_building = nearestBuilding _cercano;
									if !(_building getVariable ["asaltado",false]) then
										{
										{
										if ((_x call A3A_fnc_typeOfSoldier == "Engineer") and {_x != leader _x} and {!(_x getVariable ["maniobrando",true])} and {_x distance _cercano < 50}) exitWith {_ingeniero = _x};
										} forEach _baseOfFire;
										if !(isNull _ingeniero) then
											{
											[_ingeniero,_cercano,_building] spawn A3A_fnc_destroyBuilding;
											}
										else
											{
											[[_flankers,_cercano] call BIS_fnc_nearestPosition,_cercano,_building] spawn A3A_fnc_assaultBuilding;
											};
										};
									}
								else
									{
									[_flankers,_cercano] spawn A3A_fnc_doFlank;
									};
								};
							};
						};
					};
				};

			if (_tarea == "Hide") then
				{
				if ((isNull _tanques) and {isNull _aire} and {_numObjetivos <= 2*_numNearFriends}) then
					{
					_grupo setVariable ["tarea","Patrol"];
					}
				else
					{
					_movable = _movable select {!(_x getVariable ["maniobrando",false])};
					_movable spawn A3A_fnc_hideInBuilding;
					};
				};
			}
		else
			{
			if (_grupo getVariable ["tarea","Patrol"] != "Patrol") then
				{
				if (_grupo getVariable ["tarea","Patrol"] == "Hide") then {_grupo call A3A_fnc_recallGroup};
				_grupo setVariable ["tarea","Patrol"];
				};
			if (side _grupo == buenos) then
				{
				if (time >= _grupo getVariable ["autoRearm",time]) then
					{
					_grupo setVariable ["autoRearm",time + 120];
					{[_x] spawn A3A_fnc_autoRearm; sleep 1} forEach (_movable select {!(_x getVariable ["maniobrando",false])});
					};
				};
			if !(isNull(_grupo getVariable ["transporte",objNull])) then
				{
				(units _grupo select {vehicle _x == _x}) allowGetIn true;
				};
			};
		//diag_log format ["Tarea:%1.Movable:%2.Base:%3.Flankers:%4",_grupo getVariable "tarea",_grupo getVariable "movable",_grupo getVariable "baseOfFire",_grupo getVariable "flankers"];
		sleep 30;
		_movable =  (_grupo getVariable ["movable",[]]) select {alive _x};
		if ((_movable isEqualTo []) or (isNull _grupo)) exitWith {};
		_grupo setVariable ["movable",_movable];
		_baseOfFire = (_grupo getVariable ["baseOfFire",[]]) select {alive _x};
		_grupo setVariable ["baseOfFire",_baseOfFire];
		_flankers = (_grupo getVariable ["flankers",[]]) select {alive _x};
		_grupo setVariable ["flankers",_flankers];
		};
	};
