extends RefCounted
## Bake solid rendered triangles into root space; soft fronds/tentacles stay soft.
const SOFT := ["kelp", "oxygen_algae", "tentacle", "fish", "bubble", "sunshaft", "water"]


static func build(root: Node3D, platform: int = -1) -> void:
	var faces := PackedVector3Array()
	collect(root, Transform3D.IDENTITY, faces)
	if faces.is_empty():
		return
	var body := StaticBody3D.new()
	body.name = "SolidGeometry"
	body.collision_layer = 3
	body.collision_mask = 0
	body.set_meta("platform", platform)
	var shape := CollisionShape3D.new()
	var triangles := ConcavePolygonShape3D.new()
	triangles.set_faces(faces)
	triangles.backface_collision = true
	shape.shape = triangles
	body.add_child(shape)
	root.add_child(body)


static func collect(node: Node3D, transform: Transform3D, faces: PackedVector3Array) -> void:
	if node is MeshInstance3D:
		var material: Material = node.material_override
		if material is ShaderMaterial:
			var shader_name: String = material.shader.resource_path.get_file().get_basename()
			if shader_name in SOFT:
				return
		for point in node.mesh.get_faces():
			faces.append(transform * point)
	for child in node.get_children():
		if child is Node3D and not child is CollisionObject3D:
			collect(child, transform * child.transform, faces)
