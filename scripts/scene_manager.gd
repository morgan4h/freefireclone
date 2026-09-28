extends Node

# A function to easily change scenes by giving it the file path
func change_scene(path: String):
	get_tree().change_scene_to_file(path)
