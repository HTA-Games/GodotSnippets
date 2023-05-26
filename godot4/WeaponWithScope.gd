extends Node
class_name WeaponWithScope

"""
An implementation of a generic Weapon behaviour with a scope and dual firing modes.
No actual bullets are fired, only signals and behaviours are processed.

Note that in many cases, it may be better to use an AnimationTree state machine
to manage weapon behaviours. This script acts as a combination of rapid prototype
and reference.

Signals
	primary_fired
	secondary_fired
		Emitted when the weapon mode is fired.
	
	charged_primary_fired(pct_time, pct_ammo)
	charged_secondary_fired(pct_time, pct_ammo)
		Emitted when the weapon mode is ChargeAndRelease
		and the weapon is fired.
		
		pct_time is a value between 0.0 and 1.0, 
			where 0.0 is the firing mode's min_charge_time
			  and 1.0 is the firing_mode's max_charge_time
			This value will still count up even if no ammo is consumed.
		
		pct_ammo is a value between 0.0 and 1.0,
			where 0.0 is no ammo consumed
			  and 1.0 is the firing_mode's ammo_cost
			This value will reflect the weapon's actual ammo consumed.
			If the weapon overflows and can still consume ammo, it will
			tick up as normal.
			If the weapon overflows and is disabled, this will not
			tick up.
	
	
	scope_started
		When the player pressed the scope button, a timer
		is started to act as a warmup for the scope.
		This signal is emitted when the scope has finished warming up.
		
	scope_stopped
		When the player releases the scope button, a timer
		is started to act as a cooldown for the scope.
		This signal is emitted when the scope has finished warming up.
	
	reload_started
		Emitted when a reload cycle starts
	
	reload_occured
		Emitted when an individual reload finishes.
	
	reload_stopped
		Emitted when a reload cycle ends or is cancelled.
		For Shotgun-type reload modes, this occurs at the end of
		the reload cycle, not at the end of the individual reloads
	
	ammo_change(ammo, reserve)
		Emitted whenever the ammo count changes through the internal
		logic of the weapon.
		if ammo < 0, treat it as infinite
		if reserve < 0, treat it as infinite
	

Enumerations
	Firing Mode
		Automatic
			- When the player presses the FIRE action, the weapon fires.
			- The weapon will continue firing as long as the button is held.
		SemiAutomatic
			- When the player presses the FIRE action, the weapon fires.
			- The player must release the FIRE action before they can fire again
		ChargeAndRelease
			- When the player presses the FIRE action, the weapon charges,
			consuming ammo up to the ammo cost.
			- When the player releases the FIRE action, the weapon fires
		Disabled
			- The weapon will not perform any actions for this mode.
	
	ReloadMode
		FullClip
			- When a reload is triggered, any remaining ammo is moved to the reserve
			- When the reload is finished, the ammo is pulled from the reserve
		PreserveClip
			- Similar to FullClip, but ammo is not transferred from the reserve.
		Shotgun
			- When a reload is triggered, ammo is incrementally added from the reserve.
			- The full reload time is consumed per partial reload amount
		Energy
			- Behaves like Shotgun, but cannot be manually triggered.
			- Instead, it can only be triggered after waiting for the energy
			start delay timer to run out
			- Any action will reset the energy timer
		DumpAndRefill
			- When a reload is triggered, any remaining ammo is moved to the reserve
			- The weapon then reloads similar to shotgun
	
	OverflowMode
		FillFromReserve
			- When the weapon's clip is empty, pull the required ammo from the reserve
			- If the reserve is empty, the weapon will not be disabled
		IgnoreOverflow
			- When the weapon's clip is empty, the overflowed cost will be dropped
		Disable
			- If the cost is more than the weapon's clip, the weapon will be disabled
		DisableReserve
			- When the weapon's clip is empty, pull the required ammo from the reserve
			- If the reserve is empty, the weapon will be disabled


Parameters
	enabled
		If disabled, the weapon will not process inputs.
		Weapon timers will still continue to function.
	
	ammo_clip_size
		The amount of ammo in the weapon's clip
		When the player fires, ammo will be drawn from here
	
	ammo_reserve_size
		The amount of ammo in the weapon's reserve.
		When the player reloads, ammo will be drawn from here.
	
	
	fire_mode
		The type of firing behaviour for the primary/secondary mode
		See FiringMode
	
	fire_rate
		How many times per second the weapon should fire.
		If set to 0.0, the cooldown is disabled.
	
	
	min_charge_time
		When using the ChargeAndRelease fire mode, this is the minimum
		amount of time, in seconds, before the weapon registers as
		having accumulated 0.0 charge time and may fire.
		If the button is released before the min_charge_time, the weapon
		will continue charging until the minimum time has elapsed.
	
	
	max_charge_time
		When using the ChargeAndRelease fire mode, this is the amount
		of time, in seconds, that the weapon must be charged to reach
		1.0 (full) charge.
		If the button is released after the max_charge_time, the
		emitted charge_[weapon_mode]_fired signal will still emit 1.0
	
	
	max_overcharge_time
		The amount of time, in seconds that the weapon may be held
		after reaching full charge before automatically firing.
		If set to < 0.0, there is no limit on the charge time.
	
	
	ammo_cost
		The amount of ammo to consume when firing the weapon.
		For ChargeAndRelase mode, this is the total amount of ammo
		consumed when the weapon reaches full charge.
		
		If set to 0, no ammo will be consumed.
		For ChargeAndRelease, an ammo cost of 0 will always result
		in a 1.0 ammo cost pct
	
	
	overflow_mode
		Affects how the weapon should behave in the given firing mode
		when the clip does not have enough ammo for the weapon's consumption
		
		See OverflowMode
	
	
	scope_enabled
		If enabled, allows the weapon to enter into a Scoped state and 
		enables the secondary fire
		
	scope_warmup_time
		The amount of time to wait after the SCOPE action is pressed
		before treating the weapon as scoped.
		If set to 0, no delay will occur.
		When this timer runs out, the scope_started signal is emitted
	
	scope_cooldown_time
		The amount of time to wait after the SCOPE action is released 
		before treating the weapon as unscoped.
		If set to 0, no delay will occur.
		When this timer runs out, the scope_ended signal is emitted
	
	scope_post_start_delay
		The amount of time after the weapon becomes scoped before
		any actions are allowed to take place.
	
	scope_post_end_delay
		The amount of time after the weapon becomes unscoped before
		any actions are allowed to take place.
	
	
	reload_mode
		See ReloadMode
	
	reload_partial_amount
		When using Shotgun or Energy as the reload mode, affects
		how much ammo to replenish per reload cycle
	
	reload_reload_time
		Sets the time to complete a reload cycle.
		For FullClip, this is the total time from when the reload
		is triggered to when the reload is complete.
		For Shotgun and Energy, this is the amount of time between
		each partial reloads.
	
	reload_warmup_delay
		Sets the time to complete the first reload cycle.
		This amount is added on top of the reload_reload_time
	
	reload_post_delay
		Sets the amount of time after a reload action is
		complete before the weapon can be used again.
		This only occurs once perreload loop, when the weapon
		transitions back into an idle state
	
	reload_energy_start_delay
		When using Energy reload mode, affects how long to wait
		after an action is triggered before reloading can occur


Methods
	start_reload
		Forces the weapon to reload the way the player would if
		they pressed the RELOAD action
	
	cancel_reload
		Cancels the current reload action.
	
	reset_energy_timer
		Call this after performing any action that should reset
		the Energy mode's reload timer
	
	consume_ammo(amount, overflow_mode) -> bool
		Consumes ammo from the clip, if possible according to the 
		overflow mode.
		Returns true if ammo was consumed
	
	replenish_ammo(amount)
		Transfers ammo from the reserve into the clip.
		If amount is more than what's available in the reserve,
		only the amount available will be transferred.
	
	set_ammo(ammo, reserve)
		Forces a new ammo amount, emitting changed_ammo signals
	
	can_reload -> bool
		Returns true if the weapon's clip can be reloaded.
		May return false if the reserve is empty or if the clip is full.
	
	has_infinite_reserve -> bool
		Returns true if the weapon's ammo reserve is infinite
		(i.e., if ammo_reserve_size is < 0)
	
	has_infinite_ammo -> bool
		Returns true if the weapon's ammo clip is infinite
		(i.e., if ammo_clip_size is < 0)
	
	is_clip_empty -> bool
		Returns true if the weapon's ammo clip is exactly 0.
		If the ammo clip is infinite, this will always return false.
	
	is_clip_full -> bool
		Return true if the weapon's ammo clip is >= clip size
		If the ammo clip is infinite, this will always return true
	
	is_reserve_empty -> bool
		Returns true if the weapon has some reserve ammo
		If the reserve is infinte, this will always return false
	
	is_reloading -> bool
		returns True if the weapon is currently performing a reload cycle



Variables
	scoped :bool
		value is True if the player is holding the SCOPE action
		and the weapon is behaving according to the scoped state
	
	action_timer :float
		Acts as a cooldown for any action. While > 0.0, prevents
		any actions from occuring
	
	reload_timer :float
		Acts as a timer for the current reload cycle.
	
	scope_timer :float
		Acts as a cooldown for transitioning between the
		scoped and unscoped modes
	
	charge_time :float
		Amount of time that the weapon has been charging when
		used in the ChargeAndRelease mode. This value is uncapped.
	
	charge_ammo_consumed :float
		Amount of ammo that the weapon has consumed so far
		while charging in the ChargeAndRelease mode
	
	energy_reload_timer :float
		Amount of time before an Energy reload is triggered
	
	ammo :int
		Amount of ammo in the clip.
	
	reserve :int
		Amount of ammo in the reserve.

For use with Godot 4.x
"""

# Scipt Config
const FIRE_ACTION := "primary_fire"
const SCOPE_ACTION := "secondary_fire"
const RELOAD_ACTION := "reload"


# warning-ignore:unused_signal
signal primary_fired
# warning-ignore:unused_signal
signal charged_primary_fired(pct_time, pct_ammo)
# warning-ignore:unused_signal
signal secondary_fired
# warning-ignore:unused_signal
signal charged_secondary_fired(pct_time, pct_ammo)

signal scope_started
signal scope_stopped

signal reload_started
signal reload_occured
signal reload_stopped

# Emitted when the ammot amount changes.
# If ammo < 0, ammo is infinite
# If reserve < 0, reserve is infinite
signal ammo_changed(ammo, reserve)


enum FiringMode {
	Automatic = 0,
	SemiAutomatic = 1,
	ChargeAndRelease = 2,
	Disabled = -1,
}


enum ReloadMode {
	FullClip = 0, # When pressed, empties clip, reloads, then refills clip
	PreserveClip = 1, # When pressed, reloads, then refills the clip
	Shotgun = 2, # When pressed, reloads, adding ammo in a cycle
	Energy = 3, # When ammo < max_ammo, reloads, adding ammo in a cycle
	DumpAndReill = 4, #when pressed, empties clip, then reloads like Shotgun
}


enum OverflowMode {
	FillFromReserve = 0, # When ammo < cost, fetch missing from reserve
	IgnoreOverflow = 1, # When ammo < cost, ignore the overflow completely
	Disable = -1, # When ammo < cost, disable the firing mode
	DisableReserveOnly = -2, # When ammo < cost, fetch from reserve, or disable if empty
}


@export var enabled := true # If false, does not process inputs

@export_group("Ammo", "ammo_")
@export var ammo_clip_size := 25 # If set <= 0, treated as infinite clip
@export var ammo_reserve_size := 400 # If set < 0, treated as infinite reserve


@export_group("Primary Fire", "primary_")
@export var primary_fire_mode :FiringMode = FiringMode.Automatic
@export var primary_fire_rate := 10.0
@export var primary_min_charge_time := 0.2
@export var primary_max_charge_time := 1.0
@export var primary_max_overcharge_time := 2.0
@export var primary_ammo_cost := 1
@export var primary_overflow_mode :OverflowMode = OverflowMode.FillFromReserve


@export_group("Secondary Fire", "secondary_")
@export var secondary_fire_mode :FiringMode = FiringMode.Automatic
@export var secondary_fire_rate := 10.0
@export var secondary_min_charge_time := 0.2
@export var secondary_max_charge_time := 1.0
@export var secondary_max_overcharge_time := 2.0
@export var secondary_ammo_cost := 1
@export var secondary_overflow_mode :OverflowMode = OverflowMode.FillFromReserve

@export_group("Scope", "scope_")
@export var scope_enabled := false
@export var scope_warmup_time := 0.0
@export var scope_cooldown_time := 0.0
@export var scope_post_start_delay := 0.5
@export var scope_post_end_delay := 0.25


@export_group("Reload", "reload_")
@export var reload_mode :ReloadMode = ReloadMode.FullClip
@export var reload_partial_amount := 1
@export var reload_reload_time := 2.5
@export var reload_warmup_time := 0.0
@export var reload_post_delay := 0.0
@export var reload_energy_start_delay := 1.0


var scoped := false
var action_timer := 0.0
var reload_timer := 0.0
var scope_timer := 0.0

var charge_time := 0.0
var charge_ammo_consumed := 0

var energy_reload_timer := 0.0

var ammo := 0
var reserve := 0


func _ready() -> void:
	set_ammo(ammo_clip_size, ammo_reserve_size)
	action_timer = 0.0
	reload_timer = 0.0
	charge_time = 0.0
	charge_ammo_consumed = 0


func _process(delta :float) -> void:
	
	if energy_reload_timer > 0.0:
		energy_reload_timer -= delta
	
	if action_timer > 0.0:
		action_timer -= delta
	elif enabled:
		if reload_timer > 0.0:
			_process_reload(delta)
		
		elif _wants_reload():
			start_reload()
		
		elif scoped:
			if scope_enabled and !is_charging() and !Input.is_action_pressed(SCOPE_ACTION):
				if scope_cooldown_time > 0.0:
					scope_timer -= delta / scope_cooldown_time
					if scope_timer <= 0.0:
						scoped = false
						scope_timer = 0.0
						action_timer = scope_post_end_delay
						emit_signal("scope_stopped")
				else:
					scope_timer = 0.0
					scoped = false
					action_timer = scope_post_end_delay
					emit_signal("scope_stopped")
			else:
				scope_timer = 0.0
				if _is_weapon_triggered(secondary_fire_mode):
					_process_weapon_fire(delta,
						secondary_fire_mode, secondary_fire_rate, 
						secondary_min_charge_time, secondary_max_charge_time, secondary_max_overcharge_time,
						secondary_ammo_cost, secondary_overflow_mode, "secondary_fired")
				elif is_clip_empty():
					start_reload()
		else:
			if scope_enabled and !is_charging() and Input.is_action_pressed(SCOPE_ACTION):
				if scope_warmup_time > 0.0:
					scope_timer += delta / scope_warmup_time
					if scope_timer >= 1.0:
						scoped = true
						scope_timer = 1.0
						action_timer = scope_post_start_delay
						emit_signal("scope_started")
				else:
					scope_timer = 1.0
					scoped = true
					action_timer = scope_post_start_delay
					emit_signal("scope_started")
			else:
				scope_timer = 1.0
				if _is_weapon_triggered(primary_fire_mode):
					_process_weapon_fire(delta,
						primary_fire_mode, primary_fire_rate,
						primary_min_charge_time, primary_max_charge_time, primary_max_overcharge_time,
						primary_ammo_cost, primary_overflow_mode, "primary_fired")
				elif is_clip_empty():
					start_reload()



func _is_weapon_triggered(mode :int) -> bool:
	if action_timer > 0.0:
		return false
	
	match mode:
		FiringMode.Automatic:
			return Input.is_action_pressed(FIRE_ACTION) and !is_clip_empty()
		FiringMode.SemiAutomatic:
			return Input.is_action_just_pressed(FIRE_ACTION) and !is_clip_empty()
		FiringMode.ChargeAndRelease:
			if is_charging():
				return true
			else:
				return Input.is_action_pressed(FIRE_ACTION) and !is_clip_empty()
		FiringMode.Disabled:
			return false
		_:
			return false



func _process_weapon_fire(delta :float, fire_mode :int, fire_rate :float,
		min_charge :float, max_charge :float, overcharge_time :float,
		ammo_cost :int, overflow_mode :int, fire_signal :String) -> void:
	
	reset_energy_timer()
	
	match fire_mode:
		FiringMode.ChargeAndRelease:
			print(charge_time)
			if (overcharge_time < 0.0 or charge_time < max_charge + overcharge_time) and \
					(Input.is_action_pressed(FIRE_ACTION) or charge_time < min_charge):
				
				charge_time += delta
				
				var required_ammo :int
				if charge_time < max_charge:
					required_ammo = int(remap(charge_time, 0.0, max_charge, min(ammo_cost, 1), ammo_cost)) - charge_ammo_consumed
				else:
					required_ammo = ammo_cost - charge_ammo_consumed
				
				if required_ammo > 0:
					if consume_ammo(required_ammo, overflow_mode):
						charge_ammo_consumed += required_ammo
					elif ammo > 0:
						required_ammo = ammo
						if consume_ammo(required_ammo, overflow_mode):
							charge_ammo_consumed += ammo
			
			else:
				action_timer = 1.0 / fire_rate if fire_rate > 0.0 else 0.0
				emit_signal(fire_signal)
				emit_signal(str("charged_", fire_signal),
					clamp(remap(charge_time, min_charge, max_charge, 0.0, 1.0), 0.0, 1.0),
					float(charge_ammo_consumed) / ammo_cost if ammo_cost > 0 else 1.0)
				charge_ammo_consumed = 0
				charge_time = 0.0
		
		
		FiringMode.Automatic, FiringMode.SemiAutomatic:
			if consume_ammo(ammo_cost, overflow_mode):
				action_timer = 1.0 / fire_rate if fire_rate > 0.0 else 0.0
				emit_signal(fire_signal)



func _wants_reload() -> bool:
	match reload_mode:
		ReloadMode.Energy:
			return energy_reload_timer <= 0.0 and can_reload()
		_:
			return Input.is_action_just_pressed(RELOAD_ACTION)


func _process_reload(delta :float) -> void:
	reload_timer -= delta
	
	if Input.is_action_just_pressed(FIRE_ACTION) and !is_clip_empty():
		cancel_reload()
	
	elif reload_timer <= 0.0:
		match reload_mode:
			
			ReloadMode.FullClip, ReloadMode.PreserveClip:
				replenish_ammo(ammo_clip_size)
				action_timer = reload_post_delay
				emit_signal("reload_occured")
				emit_signal("reload_stopped")
				
			ReloadMode.Shotgun, ReloadMode.Energy, ReloadMode.DumpAndReill:
				replenish_ammo(reload_partial_amount)
				if can_reload():
					reload_timer = reload_reload_time
					emit_signal("reload_occured")
				else:
					action_timer = reload_post_delay
					reset_energy_timer()
					emit_signal("reload_stopped")




func start_reload():
	if !can_reload():
		return
	
	if energy_reload_timer > 0.0:
		return
	
	# Cancel charge
	charge_ammo_consumed = 0
	charge_time = 0.0
	
	reload_timer = reload_reload_time + reload_warmup_time
	match reload_mode:
		ReloadMode.FullClip, ReloadMode.DumpAndReill:
			set_ammo(0, reserve+ammo)
		_:
			pass
	
	emit_signal("reload_started")


func cancel_reload() -> void:
	if is_reloading():
		reload_timer = 0.0
		action_timer = reload_post_delay
		reset_energy_timer()
		emit_signal("reload_stopped")



func reset_energy_timer():
	if reload_mode == ReloadMode.Energy:
		energy_reload_timer = reload_energy_start_delay
	else:
		energy_reload_timer = 0.0




func consume_ammo(cost :int, overflow_mode :int) -> bool:
	if has_infinite_ammo():
		return true
	
	elif cost <= ammo:
		set_ammo(ammo-cost, reserve)
		return true
	
	else:
		match overflow_mode:
			OverflowMode.IgnoreOverflow:
				set_ammo(0, reserve)
				return true
				
			OverflowMode.FillFromReserve:
				cost -= ammo
				set_ammo(0, reserve - cost)
				return true
				
			OverflowMode.Disable:
				return false
			
			OverflowMode.DisableReserveOnly:
				if reserve > cost:
					set_ammo(0, reserve - cost)
					return true
				else:
					return false
				
			_:
				return true


func replenish_ammo(amount :int) -> void:
	var new_amount := ammo + amount
	if new_amount > ammo_clip_size:
		new_amount = ammo_clip_size
	
	var diff := new_amount - ammo
	if diff > reserve and !has_infinite_reserve():
		diff = reserve
	
	set_ammo(ammo+diff, reserve-diff)


func set_ammo(new_ammo :int, new_reserve :int) -> void:
	ammo = new_ammo
	reserve = new_reserve
	
	if ammo < 0:
		ammo = 0
	if reserve < 0:
		reserve = 0
	
	emit_signal("ammo_changed",
		-1 if has_infinite_ammo() else ammo,
		-1 if has_infinite_reserve() else reserve)



func can_reload() -> bool:
	if is_clip_full() or is_reserve_empty():
		return false
	else:
		return true



func has_infinite_reserve() -> bool:
	return ammo_reserve_size < 0



func has_infinite_ammo() -> bool:
	return ammo_clip_size <= 0



func is_clip_empty() -> bool:
	return ammo <= 0 and !has_infinite_ammo()



func is_clip_full() -> bool:
	return has_infinite_ammo() or ammo >= ammo_clip_size



func is_reserve_empty() -> bool:
	return !has_infinite_reserve() and reserve <= 0


func is_reloading() -> bool:
	return reload_timer > 0.0


func is_charging() -> bool:
	return charge_time > 0.0
