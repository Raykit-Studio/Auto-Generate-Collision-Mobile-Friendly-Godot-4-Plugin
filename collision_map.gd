@tool
extends EditorPlugin

var panel: Control
var dock_button: Button
var info_dialog: AcceptDialog

func _enter_tree():
	panel = Control.new()
	panel.custom_minimum_size = Vector2(0, 50)

	dock_button = Button.new()
	dock_button.text = "Generate Collision"
	dock_button.pressed.connect(_on_generate_pressed)
	dock_button.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.add_child(dock_button)

	add_control_to_bottom_panel(panel, "Auto Collision")

	info_dialog = AcceptDialog.new()
	info_dialog.title = "Auto Collision Generator"
	get_editor_interface().get_base_control().add_child(info_dialog)

func _exit_tree():
	if is_instance_valid(panel):
		remove_control_from_bottom_panel(panel)
		panel.queue_free()
	if is_instance_valid(info_dialog):
		info_dialog.queue_free()

func _on_generate_pressed():
	var root = get_editor_interface().get_edited_scene_root()
	if root == null:
		_tampil_info("Gak ada scene yang lagi dibuka. Buka scene dulu ya!")
		return

	var semua_mesh = _cari_semua_mesh(root)
	var jumlah_dibuat = 0
	var jumlah_dilewati = 0

	for mesh_node in semua_mesh:
		if _tambah_collision(mesh_node, root):
			jumlah_dibuat += 1
		else:
			jumlah_dilewati += 1

	var pesan = "Selesai!\n\n"
	pesan += "✅ %d collision baru dibuat\n" % jumlah_dibuat
	if jumlah_dilewati > 0:
		pesan += "⏭️ %d mesh dilewati (udah punya collision)" % jumlah_dilewati

	_tampil_info(pesan)

func _tampil_info(pesan: String):
	if is_instance_valid(info_dialog):
		info_dialog.dialog_text = pesan
		info_dialog.popup_centered()
	print(pesan)

func _cari_semua_mesh(node):
	var hasil = []
	for child in node.get_children():
		if child is MeshInstance3D:
			hasil.append(child)
		else:
			hasil += _cari_semua_mesh(child)
	return hasil

func _tambah_collision(mesh_node, scene_root):
	for child in mesh_node.get_children():
		if child is StaticBody3D:
			return false

	if mesh_node.mesh == null:
		return false

	var shape = mesh_node.mesh.create_trimesh_shape()
	if shape == null:
		return false

	var collision_shape = CollisionShape3D.new()
	collision_shape.shape = shape

	var static_body = StaticBody3D.new()
	static_body.name = "Tabrakan_" + mesh_node.name
	static_body.add_child(collision_shape)

	mesh_node.add_child(static_body)

	static_body.owner = scene_root
	collision_shape.owner = scene_root

	return true
