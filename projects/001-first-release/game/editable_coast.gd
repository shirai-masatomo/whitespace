extends Node3D


## Saved Node transforms are authoritative. Animation only moves child visuals.
func _ready() -> void:
	if has_node("EditorPreviewLight"):
		$EditorPreviewLight.queue_free()


func platform_data() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for rock in $RocksAndOxygen.get_children():
		var data: Dictionary = rock.get_meta("gameplay").duplicate(true)
		data.position = rock.global_position
		data.origin = rock.global_position
		data["sway_direction"] = rock.global_basis.x.normalized()
		result.append(data)
	return result


func gardens() -> Array[Vector3]:
	var result: Array[Vector3] = []
	for plant in $OxygenGardens.get_children():
		result.append(plant.global_position)
	return result


func update_animals(elapsed: float) -> void:
	for i in range($Animals.get_child_count()):
		var animal: Node3D = $Animals.get_child(i)
		# Preserve the authored parent. Swim in its local frame, never world constants.
		for child in animal.get_children():
			if child is MeshInstance3D:
				if not child.has_meta("rest"):
					child.set_meta("rest", child.position)
				child.position = (
					child.get_meta("rest")
					+ Vector3(
						sin(elapsed * .12 + i) * 6,
						sin(elapsed * .6 + i) * .5,
						(cos(elapsed * .12 + i) - 1) * 4
					)
				)
