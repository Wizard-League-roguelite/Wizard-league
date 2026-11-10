# DomAnim — CSS animations (@keyframes) and transitions. (Filled in by a later step.)
class_name DomAnim
extends RefCounted

var doc

func _init(doc_) -> void:
	doc = doc_

func tick() -> bool:
	return false

func style_changed(_n: DomNode, _old: Dictionary) -> void:
	pass
