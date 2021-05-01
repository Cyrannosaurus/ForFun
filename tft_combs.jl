### A Pluto.jl notebook ###
# v0.14.4

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : missing
        el
    end
end

# ╔═╡ 8c507e7f-db98-4577-81f3-049a9f0d4a5a
using PlutoUI, Random, Base, DataStructures

# ╔═╡ 89f92704-e979-4fda-ba7a-d94c97f3e719
md"""
Searching through the space of all possible teams for the game [TFT] (https://teamfighttactics.leagueoflegends.com/) for the current season (Reckoning)

Goals:
- Determine the strongest team possible given a gold budget and level
- Determine the strongest team **within n neighbors** from a given team

Heuristics:
- Gold value of a team
- Total number of origins / classes that have requirements met

"""


# ╔═╡ 0a8c1284-c0ce-46d3-8d8c-a70f3913d853
begin
	struct Origin
		name :: String
		tiers :: Vector{Int}
	end
	Base.show(x::Origin) = x.name
end

# ╔═╡ cd6c7d08-bed2-401f-8113-2b34a3b3489f
# Instantiate the season's "Origins"
begin
	origins = [	Origin("Abomination", [2,3,4,5]),
				Origin("Coven", [3]),
				Origin("Dawnbringer", [2,4,6,8]),
				Origin("Draconic", [3,5]), 
				Origin("DragonSlayer", [2,4]), 
				Origin("Eternal", [1]), 
				Origin("Forgotten", [3,5,7]),
				Origin("Hellion", [3,6,9]), 
				Origin("Ironclad", [2,3]), 
				Origin("Nightbringer", [2,4,6,8]), 
				Origin("Redeemed", [3,6]), 
				Origin("Revenant", [2,4,9]), 
				Origin("Verdant", [2])
	]
	
end

# ╔═╡ 20f80f58-cf5c-4742-81fa-bd20645bbc5c
begin
	struct Class
		name :: String
		tiers :: Vector{Int}
	end
	Base.show(x::Class) = x.name
end

# ╔═╡ 8fb0c110-e91d-4c8b-a04a-1f46571914b2
# Instantiate the season's "Classes"
begin
	classes = [	Class("Assassin", [2,4,6]),
				Class("Brawler", [2,4]), 
				Class("Caretaker", [1]), 
				Class("Cavalier", [2,3,4]), 
				Class("Cruel", [1]), 
				Class("God-King", [1]), 
				Class("Invoker", [2,4]), 
				Class("Knight", [2,4,6]),
				Class("Legionnaire", [2,4,6,8]),
				Class("Mysitc", [2,3,4]),
				Class("Ranger", [2,4]),
				Class("Renewer", [2,4]),
				Class("Skrimisher", [3,6]),
				Class("Spellweaver", [2,4])
	]
end


# ╔═╡ cea19c9e-a88c-11eb-3129-b3d7617bd200

begin
	struct Champion
		name :: String 		   # The name of the champ
		origins :: Vector{Int} # Indexes into the global "origins" vector
		classes :: Vector{Int} # Indexes into the global "classes" vector
		cost :: Int 		   # The cost in gold of the champ
	end
	Base.show(x::Champion) = x.name
end

# ╔═╡ 2db624af-fb11-4961-8e39-77c1ad039887
md"""
Instead of storing the actual class and origin for each champion, we instead store the indexes that the champion's classes and origins are found at inside of the array that houses them all.

In this way, there is no repeat storage of origin and class data. If we had, for instance, ten champions that had the Dawnbringer origin, instead of storing ten Origin data structs, we store a single int.
"""


# ╔═╡ 3dca983c-7bcb-4d4a-984e-c11e3a971ef0
begin
# 	# Abomination
# 	kalista = Champion("Kalista", [1], [9], 1)
# 	brand = Champion("Brand", [1], [14], 2)
# 	nunu = Champion("Nunu", [1], [2], 3)
# 	karthus = Champion("Karthus", [1, 7], [10], 4)
	
# 	# Coven
# 	lissandra = Champion("Lissandra", [2], [12], 1)
# 	leblanc = Champion("LeBlanc", [2], [1], 2)
# 	morg = Champion("Morgana", [2, 10], [10], 3)
	
# 	# Dawnbringer
# 	gragas = Champion("Gragas", [3], [2], 1)
# 	kha = Champion("Kha'Zix", [3], [1], 1)
# 	soraka = Champion("Soraka", [3], [12], 2)
# 	nidalee = Champion("Nidalee", [3], [13], 3)
# 	riven = Champion("Riven", [3], [9], 3)
# 	karma = Champion("Karma", [3], [7], 4)
# 	garen = Champion("Garen", [3], [6, 8], 5)
	
# 	# Draconic
# 	udyr = Champion("Udyr", [4], [13], 1)
# 	sett = Champion("Sett", [4], [2], 2)
# 	ashe = Champion("Ashe", [4, 13], [11], 3)
# 	zyra = Champion("Zyra", [4], [14], 3)
# 	heimer = Champion("Heimerdinger", [4], [3, 12], 5)
	
# 	# Dragonslayer
# 	trundle = Champion("Trundle", [5], [13], 2)
# 	panth = Champion("Pantheon", [5], [13], 3)
# 	diana = Champion("Diana", [5, 10], [1], 4)
# 	morde = Champion("Mordekaiser", [5], [9], 4)
	
# 	# Eternal
# 	kindred = Champion("Kindred", [6], [10, 11], 5)
	
# 	# Forgotten
# 	warwick = Champion("Warwick", [7], [2], 1)
# 	vayne = Champion("Vayne", [7], [11], 1)
# 	hec = Champion("Hecarim", [7], [4], 2)
# 	thresh = Champion("Thresh", [7], [8], 2)
# 	vik = Champion("Viktor", [7], [14], 2)
# 	kat = Champion("Katarina", [7], [1], 3)
# 	draven = Champion("Draven", [7], [9], 4)
# 	# karthus = Champion("Karthus", [1, 7], [10], 4)
# 	viego = Champion("Viego", [7], [1, 13], 5)
	
# 	# Hellion
# 	ziggs = Champion("Ziggs", [8], [14], 1)
# 	kled = Champion("Keld", [8], [4], 1)
# 	poppy = Champion("Poppy", [8], [8],1)
# 	kennen = Champion("Kennen", [8], [13], 2)
# 	lulu = Champion("Lulu", [8], [10, 11], 3)
# 	teemo = Champion("Teemo", [8], [5, 7], 5)
	
# 	# Ironclad
# 	naut = Champion("Nautilus", [9], [8], 2)
# 	rell = Champion("Rell", [9, 11], [4], 4)
# 	jax = Champion("Jax", [9], [13], 4)
	
# 	# Nightbringer
# 	vlad = Champion("Vladimir", [10], [12], 1)
# 	sej = Champion("Sejuani", [10], [4], 2)
# 	leesin = Champion("Lee-Sin", [10], [13], 3)
# 	# morg = Champion("Morgana", [2, 10], [10], 3)
# 	yasuo = Champion("Yasuo", [10], [9], 3)
# 	aphelios = Champion("Aphelios", [10], [11], 4)
# 	# diana = Champion("Diana", [5, 10], [1], 4)
# 	darius = Champion("Darius", [10], [6, 8], 5)
	
# 	# Redeemed
# 	aatrox = Champion("Aatrox", [11], [9], 1)
# 	leona = Champion("Leona", [1], [8], 1)
# 	syndra = Champion("Syndra", [11], [7], 2)
# 	varus = Champion("Varus", [11], [11], 2)
# 	lux = Champion("Lux", [11], [10], 3)
# 	# rell = Champion("Rell", [9, 11], [4], 4)
# 	velkoz = Champion("Velkoz", [11], [14], 4)
# 	kayle = Champion("Kayle", [11, 13], [9], 5)
	
# 	# Revenant
# 	noct = Champion("Nocturne", [12], [1], 3)
# 	ivern = Champion("Ivern", [12], [7, 12], 4)
# 	voli = Champion("Volibear", [12], [2], 5)
	
# 	# Verdant
# 	# ashe = Champion("Ashe", [4, 13], [11], 3)
# 	taric = Champion("Taric", [13], [8], 4)
# 	# kayle = Champion("Kayle", [11, 13], [9], 5)
	
	champs = [
	# Abomination
	Champion("Kalista", [1], [9], 1),
	Champion("Brand", [1], [14], 2),
	Champion("Nunu", [1], [2], 3),
	Champion("Karthus", [1, 7], [10], 4),
	
	# Coven
	Champion("Lissandra", [2], [12], 1),
	Champion("LeBlanc", [2], [1], 2),
	Champion("Morgana", [2, 10], [10], 3),
	
	# Dawnbringer
	Champion("Gragas", [3], [2], 1),
	Champion("Kha'Zix", [3], [1], 1),
	Champion("Soraka", [3], [12], 2),
	Champion("Nidalee", [3], [13], 3),
	Champion("Riven", [3], [9], 3),
	Champion("Karma", [3], [7], 4),
	Champion("Garen", [3], [6, 8], 5),
	
	# Draconic
	Champion("Udyr", [4], [13], 1),
	Champion("Sett", [4], [2], 2),
	Champion("Ashe", [4, 13], [11], 3),
	Champion("Zyra", [4], [14], 3),
	Champion("Heimerdinger", [4], [3, 12], 5),
	
	# Dragonslayer
	Champion("Trundle", [5], [13], 2),
	Champion("Pantheon", [5], [13], 3),
	Champion("Diana", [5, 10], [1], 4),
	Champion("Mordekaiser", [5], [9], 4),
	
	# Eternal
	Champion("Kindred", [6], [10, 11], 5),
	
	# Forgotten
	Champion("Warwick", [7], [2], 1),
	Champion("Vayne", [7], [11], 1),
	Champion("Hecarim", [7], [4], 2),
	Champion("Thresh", [7], [8], 2),
	Champion("Viktor", [7], [14], 2),
	Champion("Katarina", [7], [1], 3),
	Champion("Draven", [7], [9], 4),
	# Champion("Karthus", [1, 7], [10], 4),
	Champion("Viego", [7], [1, 13], 5),
	
	# Hellion
	Champion("Ziggs", [8], [14], 1),
	Champion("Keld", [8], [4], 1),
	Champion("Poppy", [8], [8],1),
	Champion("Kennen", [8], [13], 2),
	Champion("Lulu", [8], [10, 11], 3),
	Champion("Teemo", [8], [5, 7], 5),
	
	# Ironclad
	Champion("Nautilus", [9], [8], 2),
	Champion("Rell", [9, 11], [4], 4),
	Champion("Jax", [9], [13], 4),
	
	# Nightbringer
	Champion("Vladimir", [10], [12], 1),
	Champion("Sejuani", [10], [4], 2),
	Champion("Lee-Sin", [10], [13], 3),
	# Champion("Morgana", [2, 10], [10], 3),
	Champion("Yasuo", [10], [9], 3),
	Champion("Aphelios", [10], [11], 4),
	# Champion("Diana", [5, 10], [1], 4),
	Champion("Darius", [10], [6, 8], 5),
	
	# Redeemed
	Champion("Aatrox", [11], [9], 1),
	Champion("Leona", [1], [8], 1),
	Champion("Syndra", [11], [7], 2),
	Champion("Varus", [11], [11], 2),
	Champion("Lux", [11], [10], 3),
	# rell = Champion("Rell", [9, 11], [4], 4),
	Champion("Velkoz", [11], [14], 4),
	Champion("Kayle", [11, 13], [9], 5),
	
	# Revenant
	Champion("Nocturne", [12], [1], 3),
	Champion("Ivern", [12], [7, 12], 4),
	Champion("Volibear", [12], [2], 5),
	
	# Verdant
	# Champion("Ashe", [4, 13], [11], 3),
	Champion("Taric", [13], [8], 4),
	# Champion("Kayle", [11, 13], [9], 5),
		]
end

# ╔═╡ f45fb5f4-73a9-4351-b606-d8d631df2f61
function counts(a::AbstractArray)::DefaultDict
	📖 = DefaultDict(0)
	foreach(x -> 📖[x] += 1, a)
	return 📖 # Return a dictionary containing the counts of each item in the array
end

# ╔═╡ 64b162e5-709c-44c6-9744-26ff8e1ed0e8
md"""
We want comparisons to be unordered, but to still distinguish between how many of a champ is on a team. To do this, we compare a dictionary of counts of champions instead of the vectors themselves.
"""

# ╔═╡ 55e041de-c0da-4623-a008-79987f786393
begin
	struct Team
		champs :: Vector{Int}
	end
	Base.show(x::Team) = foreach(y -> show(y), x.champs)
	Base.hash(x::Team) = hash(counts(x.champs))
end

# ╔═╡ fef9298d-fa8e-467f-88be-43d818ced3b7
md"""
Since a team is a combination of champions, we again have the ability to store indexes to champions as opposed to repeat-storing them for each team.
"""

# ╔═╡ dd6d2c81-35ea-44cb-92d0-2aea05118cd2
show(champs[4])

# ╔═╡ 51eeb6dd-40b0-4210-b982-191769fe7ac2
show(Team(Vector(rand(1:length(champs), 5))))

# ╔═╡ 692015ed-ece7-4b58-aae6-ce8e43d96975
sizeof(origins) + sizeof(classes) + sizeof(champs)
# Easily fits into L1 cache

# ╔═╡ 53414cf8-d31c-433a-8621-597e4e52b50f
@bind gold Slider(1:100, default = 10)

# ╔═╡ 2b6040c7-535a-4438-ae58-64c3483edd3b
@bind level Slider(1:12, default = 2)

# ╔═╡ e583ccd1-9373-40bc-bd05-6d2ef39d7670
function neighbors(team::Team) :: Vector{Team}
	neighbor_list ::  Vector{Team} = Vector()
	
	for i_to_remove ∈ range(1, length = length(team.champs))
		for i ∈ range(1, length = length(champs))
			
			team_champs = deepcopy(team.champs)
			team_champs = deleteat!(team_champs, i_to_remove)
			
			push!(team_champs, i)
			team′ = Team(team_champs)
			
			# if (issetequal(team.champs, team′.champs)) 
			# 	continue
			# else
			# 	push!(neighbor_list, team′)
			# end
			push!(neighbor_list, team′)
			
		end
	end
	
	return neighbor_list
end

# ╔═╡ 7cc99e22-8793-4960-a927-b3499244e54e
neighbors(Team(rand(1:length(champs), level)))

# ╔═╡ f2397836-3bc5-4291-bd40-cc0148114bac
function evaluate(team::Team) :: Int
	total_gold_value = 0
	
	for champ_index in team.champs
		total_gold_value += champs[champ_index].cost
	end
	if (total_gold_value > gold)
		return 0
	end
	return total_gold_value
end

# ╔═╡ 821a699f-4525-42e6-8191-d03e37aa6fb2
# Original version
# Trouble is, it has an expensive neighbor function and then randomly samples just one
# neighbor. If that neighbor doesn't get selected, it regenerates all the same neighbors in the next loop. Could use memoization.

# function anneal(steps::Int = 5_000_000, λ::Float64 = .0005) 
	
# 	team = Team(Vector(rand(1:length(champs), level)))

# 	for i in 1:steps
# 		t = (1 - λ)^i
# 		if (t ≈ 0)
# 			return team
# 		end
		
# 		team′ = rand(neighbors(team))
		
# 		∇R = evaluate(team′) - evaluate(team)
# 		if (∇R > 0)
# 			team = team′
# 		elseif (rand() < ℯ^(∇R/t))
# 			team = team′
# 		end
# 	end
	
# 	return team
# end

# ╔═╡ 9b6f73d7-fa24-496a-86fc-e6458cf58b61
# Requires that the global optimum(s) are a few neighbors away. Maybe this should be run after another optimization algorithm.

function anneal(initial::Team, steps::Int = 10_000_000, k::Int = level * 40) 
	
	team = deepcopy(initial)
	prev_team = nothing
	n = nothing
	current_score = evaluate(team)
	
	for i in 1:steps
		t = (steps / (i^2))
		
		if (t ≈ 0)
			return team
		end
		
		if team ≠ prev_team
			n = neighbors(team)
			current_score = evaluate(team)
		end
		
		for neighbor in rand(n, k)
			∇R = evaluate(neighbor) - current_score
			
			if (∇R > 0)
				team = neighbor
				break
			elseif (rand() < ℯ^(∇R/t))
				team = neighbor
				break
			end
			
		end
		prev_team = team
	end
	
	return team
end

# ╔═╡ d2b2e1c0-c765-4414-bf3f-33ff8fb244bf
function rand_team() :: Team
	return Team(rand(1:length(champs), level))
end

# ╔═╡ 748fe735-fc6c-4d44-9333-ae177837803f
function show_team(team::Team)::Vector{Champion}
	output = []
	for champ in team.champs
		push!(output, champs[champ])
	end
	return output
end

# ╔═╡ 3abfb686-a213-4e70-9d8d-3c92603b6946
# begin
# 	trial₁ = anneal(rand_team())
# 	show_team(trial₁)
# end

# ╔═╡ 49864fc3-2dd8-49dd-9594-e5d9ec67e2e2
function hill_climb(initial::Team, max_plateau = 5) 
	# do
	team = initial
	plateau_steps = 0
	
	while (true) 

		# Pick the best scoring neighbor
		next = pop!(sort!(neighbors(team), by=evaluate))
		
		score₁ = evaluate(team)
		score₂ = evaluate(next)
		
		# If its better, go to it
		if (score₁ < score₂)
			return team
		elseif (score₁ == score₂)
			if (plateau_steps < max_plateau)
				team = next
				plateau_steps += 1
			else
				return team
			end
		else
			team = next
			plateau_steps = 0
		end
	end
	

end

# ╔═╡ dc05b3e6-96ad-4eb5-8eba-f1ee919d859d
function restart(search_alg, runs :: Int = 10)
	
	best = rand_team()
	
	for trial in runs
		team = search_alg(rand_team())
		if (evaluate(team) > evaluate(best))
			best = team
		end
	end
	return best
end

# ╔═╡ 749bac4d-6b56-477b-898d-14e80e639409
show_team(restart(hill_climb, 1000000000))

# ╔═╡ eddc783d-f6d4-4eb3-bd52-0353748b8438
# show_team(anneal(restart(hill_climb, 10000000)))

# ╔═╡ c4e40341-9645-470a-8612-6b2d0df0b564


# ╔═╡ 46db2091-0ad7-499c-9f49-cc51366f7a6f
function search() 
	# do
	frontier :: Vector{Team} = [rand_team()]
	seen :: Set{UInt} = Set()
	best = rand_team()
	best_score = evaluate(best)
	
	while (length(frontier) ≠ 0) 
		team = pop!(frontier)
		# println(team)
		score = evaluate(team)
		if (score > best_score)
			best_score = score
			best = team
		end
		
		push!(seen, hash(team))
		
		for neighbor ∈ neighbors(team)
			if ((hash(neighbor) ∉ seen) && (neighbor ∉ frontier))
				push!(frontier, neighbor)
			end
		end
	end
	return best
end

# ╔═╡ Cell order:
# ╟─89f92704-e979-4fda-ba7a-d94c97f3e719
# ╠═8c507e7f-db98-4577-81f3-049a9f0d4a5a
# ╠═0a8c1284-c0ce-46d3-8d8c-a70f3913d853
# ╟─cd6c7d08-bed2-401f-8113-2b34a3b3489f
# ╠═20f80f58-cf5c-4742-81fa-bd20645bbc5c
# ╟─8fb0c110-e91d-4c8b-a04a-1f46571914b2
# ╠═cea19c9e-a88c-11eb-3129-b3d7617bd200
# ╟─2db624af-fb11-4961-8e39-77c1ad039887
# ╟─3dca983c-7bcb-4d4a-984e-c11e3a971ef0
# ╠═f45fb5f4-73a9-4351-b606-d8d631df2f61
# ╟─64b162e5-709c-44c6-9744-26ff8e1ed0e8
# ╠═55e041de-c0da-4623-a008-79987f786393
# ╟─fef9298d-fa8e-467f-88be-43d818ced3b7
# ╠═dd6d2c81-35ea-44cb-92d0-2aea05118cd2
# ╠═51eeb6dd-40b0-4210-b982-191769fe7ac2
# ╠═692015ed-ece7-4b58-aae6-ce8e43d96975
# ╠═53414cf8-d31c-433a-8621-597e4e52b50f
# ╠═2b6040c7-535a-4438-ae58-64c3483edd3b
# ╠═e583ccd1-9373-40bc-bd05-6d2ef39d7670
# ╠═7cc99e22-8793-4960-a927-b3499244e54e
# ╠═f2397836-3bc5-4291-bd40-cc0148114bac
# ╟─821a699f-4525-42e6-8191-d03e37aa6fb2
# ╠═9b6f73d7-fa24-496a-86fc-e6458cf58b61
# ╟─d2b2e1c0-c765-4414-bf3f-33ff8fb244bf
# ╟─748fe735-fc6c-4d44-9333-ae177837803f
# ╠═3abfb686-a213-4e70-9d8d-3c92603b6946
# ╠═49864fc3-2dd8-49dd-9594-e5d9ec67e2e2
# ╠═dc05b3e6-96ad-4eb5-8eba-f1ee919d859d
# ╠═749bac4d-6b56-477b-898d-14e80e639409
# ╠═eddc783d-f6d4-4eb3-bd52-0353748b8438
# ╠═c4e40341-9645-470a-8612-6b2d0df0b564
# ╠═46db2091-0ad7-499c-9f49-cc51366f7a6f
