extends Area2D

func take_damage(amount: int):
	if get_parent() and get_parent().has_method("take_damage"):
		# Calculate half damage, rounding up (e.g. 15 -> 8)
		var half_dmg = (amount / 2) + (amount % 2)
		get_parent().take_damage(half_dmg)
