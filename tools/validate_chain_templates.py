import argparse
import json
import re
from difflib import SequenceMatcher
from pathlib import Path


ALLOWED_OBJECTIVES = {
    "harvest",
    "talk",
    "earn_gold",
    "mine_ore",
    "fish_caught",
    "cook_meal",
    "smelt_bar",
    "chop_wood",
    "craft_item",
}


def fail(msg: str) -> None:
    raise SystemExit(f"[chain-validate] ERROR: {msg}")


def normalize_text(v: str) -> str:
    return re.sub(r"[^a-z0-9]+", " ", v.lower()).strip()


def near_duplicate(a: str, b: str, threshold: float = 0.86) -> bool:
    na = normalize_text(a)
    nb = normalize_text(b)
    if not na or not nb:
        return False
    return SequenceMatcher(None, na, nb).ratio() >= threshold


def validate_reward_pool(pool: dict, chain_id: str, step_id: str) -> None:
    if not isinstance(pool, dict):
        fail(f"{chain_id}/{step_id}: reward.pool must be object")
    entries = pool.get("entries", [])
    if not isinstance(entries, list) or not entries:
        fail(f"{chain_id}/{step_id}: reward.pool.entries must be non-empty array")
    count = int(pool.get("count", 1))
    if count <= 0:
        fail(f"{chain_id}/{step_id}: reward.pool.count must be > 0")
    weight_sum = 0.0
    for i, e in enumerate(entries):
        if not isinstance(e, dict):
            fail(f"{chain_id}/{step_id}: reward.pool.entries[{i}] must be object")
        item = str(e.get("item", "")).strip()
        weight = float(e.get("weight", 0))
        if not item:
            fail(f"{chain_id}/{step_id}: reward.pool.entries[{i}].item missing")
        if weight <= 0:
            fail(f"{chain_id}/{step_id}: reward.pool.entries[{i}].weight must be > 0")
        weight_sum += weight
    if weight_sum <= 0:
        fail(f"{chain_id}/{step_id}: reward.pool total weight must be > 0")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Validate chain templates json")
    parser.add_argument("--file", type=str, default="", help="Target chain json file")
    parser.add_argument("--batch-prefix", type=str, default="", help="Required chain id prefix for this batch")
    parser.add_argument("--existing", type=str, default="", help="Existing chain json for near-duplicate checks")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    path = Path(args.file) if args.file else (Path(__file__).resolve().parents[1] / "data" / "quests" / "chain_templates.json")
    if not path.exists():
        fail(f"missing file: {path}")
    data = json.loads(path.read_text(encoding="utf-8"))
    chains = data.get("chains", [])
    if not isinstance(chains, list) or not chains:
        fail("chains must be a non-empty array")
    seen_chain_ids = set()
    seen_step_ids = set()
    seen_titles = []
    for c in chains:
        if not isinstance(c, dict):
            fail("chain entry must be object")
        chain_id = str(c.get("id", "")).strip()
        if not chain_id:
            fail("chain.id missing")
        if args.batch_prefix and not chain_id.startswith(args.batch_prefix):
            fail(f"{chain_id}: must start with batch prefix '{args.batch_prefix}'")
        if chain_id in seen_chain_ids:
            fail(f"duplicate chain id: {chain_id}")
        seen_chain_ids.add(chain_id)
        if int(c.get("cooldown_days", 0)) < 0:
            fail(f"{chain_id}: cooldown_days must be >= 0")
        steps = c.get("steps", [])
        if not isinstance(steps, list) or len(steps) < 1:
            fail(f"{chain_id}: steps must be non-empty array")
        for s in steps:
            if not isinstance(s, dict):
                fail(f"{chain_id}: step must be object")
            step_id = str(s.get("id", "")).strip()
            if not step_id:
                fail(f"{chain_id}: step.id missing")
            if step_id in seen_step_ids:
                fail(f"duplicate step id: {step_id}")
            seen_step_ids.add(step_id)
            objective = s.get("objective", {})
            if not isinstance(objective, dict):
                fail(f"{chain_id}/{step_id}: objective must be object")
            objective_type = str(objective.get("type", "")).strip()
            if objective_type not in ALLOWED_OBJECTIVES:
                fail(f"{chain_id}/{step_id}: objective.type invalid: {objective_type}")
            count = int(objective.get("count", 1))
            if count <= 0:
                fail(f"{chain_id}/{step_id}: objective.count must be > 0")
            reward = s.get("reward", {})
            if not isinstance(reward, dict):
                fail(f"{chain_id}/{step_id}: reward must be object")
            if int(reward.get("gold", 0)) < 0:
                fail(f"{chain_id}/{step_id}: reward.gold must be >= 0")
            items = reward.get("items", [])
            if not isinstance(items, list):
                fail(f"{chain_id}/{step_id}: reward.items must be array")
            title = str(s.get("title", "")).strip()
            for t in seen_titles:
                if near_duplicate(title, t):
                    fail(f"{chain_id}/{step_id}: near-duplicate step title detected: '{title}' ~ '{t}'")
            seen_titles.append(title)
            if reward.get("pool") is not None:
                validate_reward_pool(reward["pool"], chain_id, step_id)

    if args.existing:
        existing_path = Path(args.existing)
        if existing_path.exists():
            existing_data = json.loads(existing_path.read_text(encoding="utf-8"))
            existing_titles = []
            for ec in existing_data.get("chains", []):
                for es in ec.get("steps", []):
                    existing_titles.append(str(es.get("title", "")).strip())
            for t in seen_titles:
                for et in existing_titles:
                    if near_duplicate(t, et, threshold=0.9):
                        fail(f"near-duplicate with existing content: '{t}' ~ '{et}'")

    print(f"[chain-validate] OK: {len(chains)} chains, {len(seen_step_ids)} steps")


if __name__ == "__main__":
    main()
