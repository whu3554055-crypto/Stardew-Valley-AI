import argparse
import json
from datetime import datetime
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Merge validated chain batch into main templates")
    parser.add_argument("--batch", required=True, help="Path to batch json")
    parser.add_argument("--target", default="data/quests/chain_templates.json", help="Main chain templates path")
    parser.add_argument("--replace-policy", action="store_true", help="Replace daily_pick_policy by batch value")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    root = Path(__file__).resolve().parents[1]
    batch_path = (root / args.batch).resolve() if not Path(args.batch).is_absolute() else Path(args.batch)
    target_path = (root / args.target).resolve() if not Path(args.target).is_absolute() else Path(args.target)

    if not batch_path.exists():
        raise SystemExit(f"[merge-batch] ERROR: missing batch file: {batch_path}")
    if not target_path.exists():
        raise SystemExit(f"[merge-batch] ERROR: missing target file: {target_path}")

    batch = json.loads(batch_path.read_text(encoding="utf-8"))
    target = json.loads(target_path.read_text(encoding="utf-8"))
    batch_chains = batch.get("chains", [])
    if not isinstance(batch_chains, list) or not batch_chains:
        raise SystemExit("[merge-batch] ERROR: batch must contain non-empty 'chains' array")

    # backup
    backup_dir = root / "data" / "quests" / "backups"
    backup_dir.mkdir(parents=True, exist_ok=True)
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_path = backup_dir / f"chain_templates.{ts}.bak.json"
    backup_path.write_text(json.dumps(target, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    target_chains = target.get("chains", [])
    by_id = {str(c.get("id", "")): c for c in target_chains if isinstance(c, dict)}
    replaced = 0
    added = 0
    for c in batch_chains:
        if not isinstance(c, dict):
            continue
        cid = str(c.get("id", "")).strip()
        if not cid:
            continue
        if cid in by_id:
            replaced += 1
        else:
            added += 1
        by_id[cid] = c

    merged = list(by_id.values())
    merged.sort(key=lambda c: str(c.get("id", "")))
    target["chains"] = merged
    if args.replace_policy and "daily_pick_policy" in batch:
        target["daily_pick_policy"] = batch["daily_pick_policy"]

    target_path.write_text(json.dumps(target, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"[merge-batch] OK: added={added}, replaced={replaced}, total={len(merged)}")
    print(f"[merge-batch] backup: {backup_path}")


if __name__ == "__main__":
    main()
