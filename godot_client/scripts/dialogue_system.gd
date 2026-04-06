extends CanvasLayer

# 对话系统
# 管理NPC对话界面和对话流程（集成后端API）

signal dialogue_started(npc_id: String)
signal dialogue_ended(npc_id: String)

var is_dialogue_active = false
var current_npc = null
var current_dialogues = []
var current_index = 0
var use_backend_api = true

@onready var dialogue_box = $DialogueBox
@onready var npc_name_label = $DialogueBox/NPCName
@onready var dialogue_text = $DialogueBox/DialogueText
@onready var continue_indicator = $DialogueBox/ContinueIndicator
@onready var emotion_icon = $DialogueBox/EmotionIcon
@onready var api_client = get_tree().root.get_node_or_null("Main/APIClient")

# 对话配置（fallback when backend unavailable）
var dialogue_config = {
	"pierre": {
		"name": "Pierre",
		"greetings": [
			"欢迎来到我的杂货店！需要买点什么吗？",
			"今天的天气真不错，适合 farming。",
			"你好啊！我是Pierre，这里的店主。"
		],
		"topics": {
			"shop": "我这里出售各种种子和工具。需要什么尽管说！",
			"family": "我的女儿Abigail总是到处乱跑，真让人担心。",
			"town": "这个小镇虽然不大，但大家都很和睦。"
		}
	},
	"abigail": {
		"name": "Abigail",
		"greetings": [
			"嘿！你也喜欢冒险吗？",
			"我刚从墓地那边回来，那里超酷的！",
			"要不要一起去探索山洞？"
		],
		"topics": {
			"adventure": "我听说矿洞深处有神秘的东西...",
			"hobbies": "我喜欢玩电子游戏和吹笛子。",
			"father": "爸爸总是担心我，但我已经长大了！"
		}
	},
	"lewis": {
		"name": "Lewis镇长",
		"greetings": [
			"欢迎来到星露谷！我是这里的镇长Lewis。",
			"有什么需要帮助的吗？",
			"希望你在小镇过得愉快！"
		],
		"topics": {
			"town": "我们小镇虽然小，但每个人都很重要。",
			"events": "下个月有个节日活动，一定要参加哦！",
			"advice": "多和村民交流，他们会给你很多帮助。"
		}
	}
}

func _ready():
	print("对话系统初始化")
	dialogue_box.visible = false
	continue_indicator.visible = false

func start_dialogue(npc_id: String, player_message: String = ""):
	"""开始与NPC对话（支持后端API）"""
	is_dialogue_active = true
	current_npc = npc_id

	# Try backend API first if enabled
	if use_backend_api and api_client:
		await generate_backend_dialogue(npc_id, player_message)
		return

	# Fallback to local config
	if not dialogue_config.has(npc_id):
		print("未知NPC: ", npc_id)
		end_dialogue()
		return

	var npc_data = dialogue_config[npc_id]

	# 设置对话框
	npc_name_label.text = npc_data["name"]

	# 随机选择开场白
	var greetings = npc_data["greetings"]
	current_dialogues = [greetings[randi() % greetings.size()]]

	# 添加话题选项
	for topic_key in npc_data["topics"].keys():
		current_dialogues.append(npc_data["topics"][topic_key])

	current_index = 0
	show_current_dialogue()

	# 显示对话框
	dialogue_box.visible = true
	emit_signal("dialogue_started", npc_id)

	# 播放NPC情感音效
	play_emotion_sound("neutral")

func generate_backend_dialogue(npc_id: String, player_message: String):
	"""Generate dialogue via backend API"""
	var npc_data = dialogue_config.get(npc_id, {})
	var npc_name = npc_data.get("name", npc_id.capitalize())

	var context = {
		"time": get_tree().root.get_node_or_null("Main").game_state.time if get_tree().root.has_node("Main") else 8.0,
		"weather": "sunny"
	}

	var personality = {}
	if npc_data.has("personality"):
		personality = npc_data["personality"]

	var response = await api_client.get_npc_dialogue_sync(npc_id, npc_name, player_message, context, personality)

	if response.has("error"):
		print("Backend dialogue failed, using fallback: ", response.error)
		start_dialogue_fallback(npc_id)
	else:
		npc_name_label.text = npc_name
		current_dialogues = [response.get("dialogue", "...")]
		current_index = 0
		show_current_dialogue()
		dialogue_box.visible = true
		emit_signal("dialogue_started", npc_id)

		# Set emotion if available
		var emotion = response.get("emotion", "neutral")
		set_emotion_icon(emotion)

func start_dialogue_fallback(npc_id: String):
	"""Fallback to local dialogue when backend unavailable"""
	if not dialogue_config.has(npc_id):
		print("未知NPC: ", npc_id)
		end_dialogue()
		return

	var npc_data = dialogue_config[npc_id]
	npc_name_label.text = npc_data["name"]
	var greetings = npc_data["greetings"]
	current_dialogues = [greetings[randi() % greetings.size()]]
	current_index = 0
	show_current_dialogue()
	dialogue_box.visible = true
	emit_signal("dialogue_started", npc_id)

func set_emotion_icon(emotion: String):
	"""Set emotion icon based on detected emotion"""
	if emotion_icon:
		match emotion:
			"happy":
				emotion_icon.modulate = Color(1, 1, 0.5, 1)
			"sad":
				emotion_icon.modulate = Color(0.7, 0.7, 1, 1)
			"angry":
				emotion_icon.modulate = Color(1, 0.7, 0.7, 1)
			_:
				emotion_icon.modulate = Color(1, 1, 1, 1)

func show_current_dialogue():
	"""显示当前对话内容"""
	if current_index < current_dialogues.size():
		dialogue_text.text = current_dialogues[current_index]
		continue_indicator.visible = current_index < current_dialogues.size() - 1
	else:
		end_dialogue()

func advance_dialogue():
	"""推进到下一句对话"""
	if not is_dialogue_active:
		return

	current_index += 1

	if current_index >= current_dialogues.size():
		end_dialogue()
	else:
		show_current_dialogue()
		# 播放打字音效
		play_type_sound()

func end_dialogue():
	"""结束对话"""
	is_dialogue_active = false
	dialogue_box.visible = false
	emit_signal("dialogue_ended", current_npc)
	current_npc = null
	current_dialogues.clear()
	current_index = 0

func _input(event):
	if event.is_action_pressed("interact") and is_dialogue_active:
		advance_dialogue()
		get_tree().set_input_as_handled()

func play_emotion_sound(emotion: String):
	"""播放情感音效"""
	var sound_path = "res://assets/audio/emotions/" + emotion + ".wav"
	if ResourceLoader.exists(sound_path):
		var audio = AudioStreamPlayer.new()
		audio.stream = load(sound_path)
		audio.volume_db = -10
		add_child(audio)
		audio.play()
		# 播放完后自动清理
		await audio.finished
		audio.queue_free()

func play_type_sound():
	"""播放打字音效（简化版）"""
	# TODO: 实现快速的打字音效
	pass

# 对话UI组件创建函数
func create_dialogue_ui():
	"""动态创建对话UI（如果不存在）"""
	if not has_node("DialogueBox"):
		var box = PanelContainer.new()
		box.name = "DialogueBox"
		box.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		box.custom_minimum_size = Vector2(800, 150)
		box.position.y = -160

		# 背景样式
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0, 0, 0, 0.85)
		style.border_width_left = 3
		style.border_width_right = 3
		style.border_width_top = 3
		style.border_width_bottom = 3
		style.border_color = Color(0.8, 0.8, 1, 1)
		box.add_theme_stylebox_override("panel", style)

		# NPC名字标签
		var name_label = Label.new()
		name_label.name = "NPCName"
		name_label.position = Vector2(20, 10)
		name_label.add_theme_font_size_override("font_size", 20)
		name_label.add_theme_color_override("font_color", Color(1, 1, 0.5, 1))
		box.add_child(name_label)

		# 对话文本
		var text = Label.new()
		text.name = "DialogueText"
		text.position = Vector2(20, 45)
		text.size = Vector2(760, 80)
		text.autowrap_mode = TextServer.AUTOWRAP_WORD
		text.add_theme_font_size_override("font_size", 16)
		text.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		box.add_child(text)

		# 继续提示
		var indicator = Label.new()
		indicator.name = "ContinueIndicator"
		indicator.text = "▼"
		indicator.position = Vector2(750, 110)
		indicator.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))

		# 闪烁动画
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(indicator, "modulate:a", 0.3, 0.5)
		tween.tween_property(indicator, "modulate:a", 1.0, 0.5)

		box.add_child(indicator)

		add_child(box)

		dialogue_box = box
		npc_name_label = name_label
		dialogue_text = text
		continue_indicator = indicator
