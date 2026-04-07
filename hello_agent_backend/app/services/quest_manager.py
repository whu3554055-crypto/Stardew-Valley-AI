"""
Enhanced Quest System - AI-powered quest generation and management

Provides:
- AI-generated daily quests
- Quest chains and prerequisites
- Seasonal event quests
- NPC relationship-driven quests
- Dynamic rewards system
- Quest progress tracking
"""

import logging
import json
from typing import Optional, List, Dict, Any
from datetime import datetime, timedelta

from ..db.repository import db_repo
from llm.router import LLMRouter

logger = logging.getLogger(__name__)


class QuestManager:
    """
    Manages all quest-related operations with AI enhancement
    
    Features:
    - AI-generated personalized quests
    - Quest chains (prerequisite -> follow-up)
    - Seasonal and event-based quests
    - Relationship-driven special quests
    - Dynamic reward calculation
    - Progress tracking and completion
    """
    
    def __init__(self):
        self.llm_router = LLMRouter()
        
        # Quest templates for different categories
        self.quest_templates = {
            "farming": [
                "种植并收获{count}个{crop}",
                "为{npc_name}的农田浇水",
                "清理{count}块杂草丛生的土地"
            ],
            "gathering": [
                "收集{count}个{resource}",
                "在{location}寻找稀有物品",
                "为{npc_name}采集草药"
            ],
            "social": [
                "与{npc_name}聊天提升友谊",
                "送给{npc_name}喜欢的礼物",
                "参加{location}的社交活动"
            ],
            "exploration": [
                "探索{location}的新区域",
                "发现{count}个隐藏地点",
                "绘制{location}的地图"
            ],
            "combat": [
                "在{location}击败{count}个怪物",
                "收集{count}个怪物掉落物",
                "保护{npc_name}免受怪物侵扰"
            ]
        }
        
        # Seasonal events
        self.seasonal_events = {
            "spring": [
                {"name": "春耕节", "quests": ["planting_festival"]},
                {"name": "花舞会", "quests": ["flower_dance"]}
            ],
            "summer": [
                {"name": "夏日垂钓大赛", "quests": ["fishing_contest"]},
                {"name": "月光水母舞会", "quests": ["jellyfish_dance"]}
            ],
            "fall": [
                {"name": "丰收祭", "quests": ["harvest_festival"]},
                {"name": "万灵节", "quests": ["spirit_eve"]}
            ],
            "winter": [
                {"name": "冰雪节", "quests": ["ice_festival"]},
                {"name": "星夜庆典", "quests": ["feast_of_winter_star"]}
            ]
        }
    
    async def generate_daily_quest(self, npc_id: str, player_id: str, 
                                   season: str, day: int) -> Dict[str, Any]:
        """
        Generate a personalized daily quest using AI
        
        Args:
            npc_id: Quest giver NPC
            player_id: Player receiving quest
            season: Current season
            day: Current day
            
        Returns:
            Generated quest data
        """
        try:
            # Get NPC info
            npc = await db_repo.get_npc(npc_id)
            if not npc:
                return {"success": False, "error": "NPC not found"}
            
            # Get player's relationship with NPC
            relationship = await db_repo.get_relationship(npc_id, player_id)
            friendship_level = relationship['level'] if relationship else 0
            
            # Get world state
            world_state = await db_repo.get_current_world_state()
            weather = world_state['weather'] if world_state else "sunny"
            
            # Build AI prompt
            prompt = f"""
你是一位游戏任务设计师。请为NPC {npc['name']} 生成一个日常任务。

NPC信息：
- 职业：{npc.get('occupation', 'unknown')}
- 性格特征：{npc.get('personality', {}).get('traits', ['friendly'])}
- 位置：{npc.get('location', 'unknown')}
- 与玩家友谊等级：{friendship_level}

当前环境：
- 季节：{season}
- 日期：第{day}天
- 天气：{weather}

要求：
1. 任务应该符合NPC的职业和性格
2. 难度与友谊等级匹配（等级越高任务越有趣）
3. 考虑当前季节和天气
4. 任务应该在10-20分钟内可完成
5. 奖励包括金币和友谊值

返回JSON格式：
{{
    "title": "任务标题（简洁有趣）",
    "description": "任务详细描述（2-3句话）",
    "objectives": ["目标1", "目标2"],
    "rewards": {{"gold": 数量, "friendship": 数量}},
    "difficulty": "easy/medium/hard",
    "estimated_time_minutes": 估计时间
}}

只返回JSON，不要有其他文字。
"""
            
            # Call LLM to generate quest
            response = await self.llm_router.chat_completion(
                messages=[{"role": "user", "content": prompt}],
                task_type="quest_generation"
            )
            
            # Parse JSON response
            try:
                quest_data = json.loads(response.content)
            except json.JSONDecodeError:
                logger.warning("LLM returned invalid JSON, using fallback")
                quest_data = self._generate_fallback_quest(npc, season, day)
            
            # Add metadata
            quest_data['npc_id'] = npc_id
            quest_data['assigned_to'] = player_id
            quest_data['season'] = season
            quest_data['day'] = day
            quest_data['status'] = 'active'
            quest_data['created_at'] = datetime.now().isoformat()
            
            # Save to database
            quest_id = f"quest_{npc_id}_{player_id}_{season}_{day}"
            success = await db_repo.create_quest(
                quest_id=quest_id,
                title=quest_data['title'],
                description=quest_data['description'],
                assigned_to=player_id,
                assigned_by=npc_id,
                reward_gold=quest_data['rewards']['gold']
            )
            
            if success:
                # Persist objectives/progress for automatic verification.
                await db_repo.transactional_update([
                    (
                        "UPDATE quests SET objectives = ?, progress = ? WHERE id = ?",
                        (
                            json.dumps(quest_data.get("objectives", []), ensure_ascii=False),
                            json.dumps({}, ensure_ascii=False),
                            quest_id,
                        ),
                    ),
                ])
                logger.info(f"Generated daily quest: {quest_data['title']}")
                quest_data['id'] = quest_id
                quest_data['success'] = True
            else:
                quest_data['success'] = False
                quest_data['error'] = "Failed to save quest"
            
            return quest_data
            
        except Exception as e:
            logger.error(f"Failed to generate daily quest: {e}")
            return {
                "success": False,
                "error": str(e),
                **self._generate_fallback_quest(
                    await db_repo.get_npc(npc_id) if npc_id else None,
                    season, day
                )
            }
    
    def _generate_fallback_quest(self, npc: Dict, season: str, day: int) -> Dict[str, Any]:
        """Generate a simple fallback quest when AI fails"""
        if not npc:
            return {
                "title": "日常任务",
                "description": "完成一些日常活动",
                "objectives": ["与村民交谈"],
                "rewards": {"gold": 50, "friendship": 10},
                "difficulty": "easy",
                "estimated_time_minutes": 5
            }
        
        # Simple template-based quest
        templates = [
            {
                "title": f"{npc['name']}的请求",
                "description": f"{npc['name']}需要你的帮助。",
                "objectives": [f"与{npc['name']}交谈"],
                "rewards": {"gold": 50, "friendship": 15},
                "difficulty": "easy",
                "estimated_time_minutes": 5
            },
            {
                "title": f"{season}季收集",
                "description": f"收集一些{season}季的资源。",
                "objectives": ["收集木材 x10", "收集石头 x5"],
                "rewards": {"gold": 100, "friendship": 20},
                "difficulty": "medium",
                "estimated_time_minutes": 15
            }
        ]
        
        import random
        return random.choice(templates)
    
    async def generate_quest_chain(self, npc_id: str, player_id: str,
                                  chain_length: int = 3) -> List[Dict[str, Any]]:
        """
        Generate a chain of connected quests
        
        Args:
            npc_id: Quest giver
            player_id: Player
            chain_length: Number of quests in chain
            
        Returns:
            List of quest definitions
        """
        chain = []
        previous_quest_id = None
        
        for i in range(chain_length):
            # Generate quest with reference to previous
            quest = await self.generate_daily_quest(npc_id, player_id, "spring", 1)
            
            if i > 0:
                quest['prerequisites'] = [previous_quest_id]
                quest['chain_position'] = i + 1
                quest['chain_total'] = chain_length
                if quest.get("id"):
                    await db_repo.transactional_update(
                        [
                            (
                                "UPDATE quests SET prerequisites = ? WHERE id = ?",
                                (json.dumps([previous_quest_id], ensure_ascii=False), quest["id"]),
                            )
                        ]
                    )
            
            chain.append(quest)
            previous_quest_id = quest.get('id')
        
        return chain
    
    async def get_seasonal_quests(self, season: str) -> List[Dict[str, Any]]:
        """Get special seasonal event quests"""
        events = self.seasonal_events.get(season, [])
        seasonal_quests = []
        
        for event in events:
            event_quest = {
                "event_name": event['name'],
                "quests": [],
                "duration_days": 7,
                "special_rewards": True
            }
            
            # Generate event-specific quests
            for quest_type in event['quests']:
                quest = self._create_event_quest(quest_type, season)
                event_quest['quests'].append(quest)
            
            seasonal_quests.append(event_quest)
        
        return seasonal_quests
    
    def _create_event_quest(self, quest_type: str, season: str) -> Dict[str, Any]:
        """Create a special event quest"""
        event_quests = {
            "planting_festival": {
                "title": "春耕节种植比赛",
                "description": "在春耕节期间种植最多的作物",
                "objectives": ["种植防风草 x20", "种植土豆 x15"],
                "rewards": {"gold": 500, "friendship": 50, "item": "rare_seed"},
                "time_limit_days": 7
            },
            "flower_dance": {
                "title": "花舞会邀请",
                "description": "邀请一位村民参加花舞会",
                "objectives": ["友谊等级达到3心", "赠送鲜花礼物"],
                "rewards": {"gold": 200, "friendship": 100},
                "time_limit_days": 5
            },
            "fishing_contest": {
                "title": "夏日垂钓大赛",
                "description": "钓到最重的鱼",
                "objectives": ["钓到传说鱼类", "总重量超过50kg"],
                "rewards": {"gold": 1000, "friendship": 75, "item": "iridium_rod"},
                "time_limit_days": 3
            },
            "harvest_festival": {
                "title": "丰收祭展示",
                "description": "展示你最好的农作物",
                "objectives": ["提交金星品质作物 x5"],
                "rewards": {"gold": 800, "friendship": 60},
                "time_limit_days": 1
            }
        }
        
        return event_quests.get(quest_type, {
            "title": f"{season}季活动",
            "description": "参与季节性活动",
            "objectives": ["完成活动任务"],
            "rewards": {"gold": 300, "friendship": 30}
        })
    
    async def complete_quest(self, quest_id: str, player_id: str) -> Dict[str, Any]:
        """
        Complete a quest and distribute rewards
        
        Args:
            quest_id: Quest to complete
            player_id: Player completing quest
            
        Returns:
            Completion result with rewards
        """
        try:
            # Get quest details
            quest = await db_repo.get_quest(quest_id)
            if not quest:
                return {"success": False, "error": "Quest not found"}
            
            if quest['status'] == 'completed':
                return {"success": False, "error": "Quest already completed"}
            
            # Mark as completed
            success = await db_repo.complete_quest(quest_id)
            if not success:
                return {"success": False, "error": "Failed to complete quest"}
            
            # Distribute rewards
            progress = json.loads(quest.get("progress", "{}")) if quest.get("progress") else {}
            completed_objectives = sum(1 for val in progress.values() if bool(val))
            has_chain_bonus = bool(json.loads(quest.get("prerequisites", "[]")) if quest.get("prerequisites") else [])
            reward_multiplier = 1.0
            if has_chain_bonus:
                reward_multiplier = 1.0 + min(completed_objectives * 0.05, 0.25)
            rewards = {
                "gold": int(quest.get('reward_gold', 0) * reward_multiplier),
                "friendship": 0,
                "items": []
            }
            
            # Update player gold
            player = await db_repo.get_player(player_id)
            if player:
                new_gold = player['gold'] + rewards['gold']
                await db_repo.update_player_gold(player_id, new_gold)
            
            # Update friendship with quest giver
            if quest.get('assigned_by'):
                # Calculate friendship based on quest difficulty
                base_friendship = 25
                if quest.get('reward_gold', 0) > 200:
                    base_friendship = 50
                
                await db_repo.update_friendship(
                    quest['assigned_by'],
                    player_id,
                    base_friendship
                )
                rewards['friendship'] = base_friendship
            
            logger.info(f"Quest completed: {quest_id} by {player_id}")
            
            return {
                "success": True,
                "quest_id": quest_id,
                "quest_title": quest['title'],
                "rewards": rewards,
                "completed_at": datetime.now().isoformat()
            }
            
        except Exception as e:
            logger.error(f"Failed to complete quest: {e}")
            return {"success": False, "error": str(e)}
    
    async def get_player_quests(self, player_id: str, status: str = "active") -> List[Dict[str, Any]]:
        """Get all quests for a player with given status"""
        if status == "active":
            return await db_repo.get_active_quests(player_id)
        else:
            # Get all quests and filter
            # (Would need additional DB method for efficiency)
            return []
    
    async def get_quest_progress(self, quest_id: str) -> Dict[str, Any]:
        """Get detailed progress for a specific quest"""
        quest = await db_repo.get_quest(quest_id)
        if not quest:
            return {"error": "Quest not found"}
        
        return {
            "quest_id": quest_id,
            "title": quest['title'],
            "status": quest['status'],
            "progress": json.loads(quest.get('progress', '{}')),
            "objectives": json.loads(quest.get('objectives', '[]')),
            "assigned_by": quest.get('assigned_by'),
            "reward_gold": quest.get('reward_gold', 0)
        }
    
    async def update_quest_progress(self, quest_id: str, objective_index: int,
                                   completed: bool = True) -> bool:
        """Update progress for a specific quest objective"""
        quest = await db_repo.get_quest(quest_id)
        if not quest:
            return False
        
        # Get current progress
        objectives = json.loads(quest.get('objectives', '[]'))
        progress = json.loads(quest.get('progress', '{}'))
        
        # Update progress
        progress[f"objective_{objective_index}"] = completed
        await db_repo.transactional_update([
            (
                "UPDATE quests SET progress = ? WHERE id = ?",
                (json.dumps(progress, ensure_ascii=False), quest_id),
            ),
        ])
        
        # Check if all objectives are complete
        all_complete = all(
            progress.get(f"objective_{i}", False)
            for i in range(len(objectives))
        )
        
        if all_complete and quest['status'] == 'active':
            # Auto-complete quest
            await self.complete_quest(quest_id, quest['assigned_to'])
        
        return True

    def _is_objective_completed(self, objective: Dict[str, Any], player_state: Dict[str, Any]) -> bool:
        """Validate a single objective against current player state."""
        objective_type = objective.get("type", "").lower()

        if objective_type == "collect_item":
            item_id = objective.get("item_id")
            required = int(objective.get("required", 1))
            inventory = player_state.get("inventory", {})
            return int(inventory.get(item_id, 0)) >= required

        if objective_type == "deliver_item":
            item_id = objective.get("item_id")
            required = int(objective.get("required", 1))
            delivered = player_state.get("delivered_items", {})
            return int(delivered.get(item_id, 0)) >= required

        if objective_type == "talk_to_npc":
            npc_id = objective.get("npc_id")
            talked_to = player_state.get("talked_to_npcs", [])
            return npc_id in talked_to

        if objective_type == "reach_location":
            required_location = objective.get("location")
            return player_state.get("location") == required_location

        if objective_type == "time_window":
            # objective sample: {"type":"time_window","start_hour":18,"end_hour":22}
            current_hour = int(player_state.get("current_hour", -1))
            start_hour = int(objective.get("start_hour", 0))
            end_hour = int(objective.get("end_hour", 24))
            return start_hour <= current_hour <= end_hour

        # Backward-compatible fallback for simple string objectives
        # e.g. "收集木材 x10" / "与Pierre交谈"
        objective_text = objective.get("text", "")
        if objective_text.startswith("收集") and "x" in objective_text:
            try:
                item_name, amount_text = objective_text.replace("收集", "", 1).split("x", 1)
                required = int(amount_text.strip())
                inventory_names = player_state.get("inventory_by_name", {})
                return int(inventory_names.get(item_name.strip(), 0)) >= required
            except (ValueError, TypeError):
                return False
        if objective_text.startswith("与") and objective_text.endswith("交谈"):
            npc_name = objective_text.replace("与", "", 1).replace("交谈", "").strip()
            talked_names = player_state.get("talked_to_npc_names", [])
            return npc_name in talked_names

        return False

    async def verify_quest_objectives(
        self, quest_id: str, player_id: str, player_state: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Verify quest objectives automatically and update quest progress/status.

        Supports objective types:
        - collect_item
        - deliver_item
        - talk_to_npc
        - reach_location
        - time_window
        """
        quest = await db_repo.get_quest(quest_id)
        if not quest:
            return {"success": False, "error": "Quest not found"}
        if quest.get("assigned_to") != player_id:
            return {"success": False, "error": "Quest is not assigned to this player"}
        if quest.get("status") != "active":
            return {"success": False, "error": "Quest is not active"}

        raw_objectives = quest.get("objectives", "[]")
        objectives_data = json.loads(raw_objectives) if raw_objectives else []
        if not objectives_data:
            return {"success": False, "error": "Quest has no objectives"}

        progress_map = {}
        for idx, obj in enumerate(objectives_data):
            normalized = obj if isinstance(obj, dict) else {"text": str(obj)}
            progress_map[f"objective_{idx}"] = self._is_objective_completed(normalized, player_state)

        all_complete = all(progress_map.values())
        await db_repo.transactional_update([
            (
                "UPDATE quests SET progress = ? WHERE id = ?",
                (json.dumps(progress_map, ensure_ascii=False), quest_id),
            ),
        ])

        result = {
            "success": True,
            "quest_id": quest_id,
            "progress": progress_map,
            "all_completed": all_complete,
        }

        if all_complete:
            completion = await self.complete_quest(quest_id, player_id)
            result["completion"] = completion

        return result


# Global quest manager instance
quest_manager = QuestManager()
