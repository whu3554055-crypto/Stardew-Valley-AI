extends Area2D

# 可互动对象基类
# 所有可互动的环境元素都继承此类

@export var interact_type: String = "default"
@export var interact_name: String = "物体"
@export var interaction_text: String = "按 E 互动"

func _ready():
	# 默认碰撞区域大小
	$CollisionShape2D.shape.size = Vector2(48, 48)

func interact():
	# 重写此方法实现具体互动逻辑
	print("与 ", interact_name, " 互动")
