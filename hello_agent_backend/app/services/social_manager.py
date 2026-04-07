import json
import logging
from typing import Any, Dict, Optional

from ..db.repository import db_repo

logger = logging.getLogger(__name__)


class SocialManager:
    """Manage relationship events and stage transitions."""

    EVENT_DELTAS = {
        "dialogue_positive": 15,
        "dialogue_negative": -10,
        "gift": 300,
        "cooperation": 260,
        "conflict": -40,
        "reconciliation": 280,
    }

    async def record_event(
        self,
        npc_id: str,
        player_id: str,
        event_type: str,
        delta: Optional[int] = None,
        metadata: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        effective_delta = delta if delta is not None else self.EVENT_DELTAS.get(event_type, 0)
        success = await db_repo.record_relationship_event(
            npc_id=npc_id,
            player_id=player_id,
            event_type=event_type,
            delta=effective_delta,
            metadata=metadata,
        )
        if not success:
            return {"success": False, "error": "failed to record relationship event"}

        stage = await db_repo.get_relationship_stage(npc_id, player_id)
        relationship = await db_repo.get_relationship(npc_id, player_id)
        return {
            "success": True,
            "npc_id": npc_id,
            "player_id": player_id,
            "event_type": event_type,
            "delta": effective_delta,
            "friendship_points": relationship.get("friendship_points", 0) if relationship else 0,
            "relationship_stage": stage,
            "metadata": metadata or {},
        }


social_manager = SocialManager()
