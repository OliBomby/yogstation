/datum/game_mode
	var/list/zombie_infectees = list()

/datum/game_mode/zombies
	name = "zombies"
	config_tag = "zombies"
	antag_flag = BE_ZOMBIE

	required_players = 1
	required_enemies = 1
	recommended_enemies = 1

	restricted_jobs = list("Cyborg", "AI")

	var/carriers_to_make = 1
	var/list/carriers = list()

	var/zombies_to_win = 0
	var/escaped_zombies = 0

	var/players_per_carrier = 7


/datum/game_mode/zombies/pre_setup()
	carriers_to_make = max(round(num_players()/players_per_carrier, 1), 1)

	for(var/datum/mind/player in antag_candidates)
		for(var/job in restricted_jobs)//Removing robots from the list
			if(player.assigned_role == job)
				antag_candidates -= player

	for(var/j = 0, j < carriers_to_make, j++)
		if (!antag_candidates.len)
			break
		var/datum/mind/carrier = pick(antag_candidates)
		carriers += carrier
		carrier.special_role = "zombie"
		log_game("[carrier.key] (ckey) has been selected as a Zombie infection carrier")
		antag_candidates -= carrier

	if(!carriers.len)
		return 0
	return 1


/datum/game_mode/zombies/announce()
	world << "<B>The current game mode is - Zombie!</B>"
	world << "<B>One or more crewmembers have been infected with an unknown virus! Crew: Contain the outbreak. This infection can under no circumstances be. \
				allowed to leave the station. If the outbreak cannot be contained the station must be destroyed. Zombies: Eat brains and infect all crew members!</B>"


/datum/game_mode/zombies/proc/greet_carrier(var/datum/mind/carrier)
	carrier.current << "<B><span class = 'notice'>You are the infection patient zero!!</B>"
	carrier.current << "<b>You contracted an infection from your visit aboard a quarantined spacestation.</b>"
	carrier.current << "<b>Soon you will become a flesh eating zombie. Your sole purpose is to hunt for crew members to infect them.</b>"
	carrier.current << "<b>Eating brains will make you stronger, so make sure you crack open some heads for the delicious treats.</b>"
	carrier.current << "<b>Your mission will be deemed a success if any of the live infected zombies reach Centcom.</b>"
	return

/datum/game_mode/zombies/post_setup()
	for(var/datum/mind/carriermind in carriers)
		greet_carrier(carriermind)
		zombie_infectees += carriermind

		var/datum/disease/D = new /datum/disease/transformation/rage_virus
		D.holder = carriermind.current
		D.affected_mob = carriermind.current
		carriermind.current.viruses += D
	..()

/datum/game_mode/zombies/check_finished()
	return check_zombies_victory()

/datum/game_mode/zombies/proc/check_zombies_victory()
	var/total_humans = 0
	//var/total_zombies = 0
	for(var/mob/living/carbon/human/H in living_mob_list)
		if(H.client && !istype(H, /mob/living/carbon/human/zombie))
			total_humans++
	//for(var/mob/living/carbon/human/zombie/Z in living_mob_list)
	//	total_zombies++

	if(total_humans == 0)
		return 1
	else
		return 0

/datum/game_mode/proc/add_zombie(datum/mind/zombie_mind)
	if(!zombie_mind)
		return

	zombie_infectees |= zombie_mind
	zombie_mind.special_role = "Infected zombies"

/datum/game_mode/proc/remove_zombie(datum/mind/zombie_mind)
	if(!zombie_mind)
		return

	zombie_infectees.Remove(zombie_mind)
	zombie_mind.special_role = null


/datum/game_mode/zombies/declare_completion()
	if(check_zombies_victory())
		feedback_set_details("round_end_result","win - zombies win")
		feedback_set("round_end_result",escaped_zombies)
		world << "<span class='userdanger'><FONT size = 3>The zombies have infected the crew! UUUuuRRRRRRGGHHHHHHHHHhhhhh!!</FONT></span>"
	else
		feedback_set_details("round_end_result","loss - staff stopped the zombies")
		feedback_set("round_end_result",escaped_zombies)
		world << "<span class='userdanger'><FONT size = 3>The staff managed to contain the zombie outbreak!</FONT></span>"
