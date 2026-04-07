import json
import logging
from typing import Any, Dict, List

from ..db.repository import db_repo
from llm.router import LLMRouter

logger = logging.getLogger(__name__)


class DailyNarrativeManager:
    """Generate and cache one narrative summary per game day."""

    def __init__(self):
        self.llm_router = LLMRouter()

    async def get_or_generate(
        self, season: str, day: int, year: int, context: Dict[str, Any]
    ) -> Dict[str, Any]:
        existing = await db_repo.get_daily_narrative(season, day, year)
        if existing:
            return {
                "success": True,
                "season": season,
                "day": day,
                "year": year,
                "summary": existing["summary"],
                "events": json.loads(existing.get("events_json", "[]")),
                "source": existing.get("source", "cache"),
                "cached": True,
            }

        generated = await self._generate_summary(season, day, year, context)
        await db_repo.save_daily_narrative(
            season=season,
            day=day,
            year=year,
            summary=generated["summary"],
            events=generated["events"],
            source=generated.get("source", "fallback"),
        )
        generated["cached"] = False
        return generated

    async def _generate_summary(
        self, season: str, day: int, year: int, context: Dict[str, Any]
    ) -> Dict[str, Any]:
        prompt = (
            "你是农场模拟游戏的叙事导演。请生成当日叙事摘要与3个可触发事件。\n"
            f"季节: {season}, 日期: {day}, 年份: {year}\n"
            f"上下文: {json.dumps(context, ensure_ascii=False)}\n"
            "返回JSON: {\"summary\": str, \"events\": [{\"id\": str, \"title\": str, "
            "\"npc_id\": str, \"location\": str, \"impact\": {\"relationship_delta\": int, "
            "\"quest_hook\": str}}]}"
        )

        try:
            response = await self.llm_router.chat_completion(
                messages=[{"role": "user", "content": prompt}],
                task_type="story_generation",
                temperature=0.8,
                max_tokens=500,
            )
            payload = json.loads(response.content)
            events = payload.get("events", [])[:3]
            return {
                "success": True,
                "season": season,
                "day": day,
                "year": year,
                "summary": payload.get("summary", "今天是平静而充满可能的一天。"),
                "events": events,
                "source": "llm",
            }
        except Exception as e:
            logger.warning(f"Daily narrative fallback used: {e}")
            fallback_events: List[Dict[str, Any]] = [
                {
                    "id": f"evt_{season}_{day}_1",
                    "title": "集市上的新传闻",
                    "npc_id": "pierre",
                    "location": "shop",
                    "impact": {"relationship_delta": 10, "quest_hook": "gathering"},
                },
                {
                    "id": f"evt_{season}_{day}_2",
                    "title": "广场上的小争执",
                    "npc_id": "abigail",
                    "location": "town_center",
                    "impact": {"relationship_delta": -5, "quest_hook": "social"},
                },
                {
                    "id": f"evt_{season}_{day}_3",
                    "title": "夜晚前的协作邀请",
                    "npc_id": "lewis",
                    "location": "town_center",
                    "impact": {"relationship_delta": 15, "quest_hook": "delivery"},
                },
            ]
            return {
                "success": True,
                "season": season,
                "day": day,
                "year": year,
                "summary": "村民们今天发生了几件小事，明天可能演变成新的机会。",
                "events": fallback_events,
                "source": "fallback",
            }


daily_narrative_manager = DailyNarrativeManager()
