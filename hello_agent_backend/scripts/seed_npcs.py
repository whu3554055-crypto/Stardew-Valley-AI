#!/usr/bin/env python3
"""
NPC Data Seeder - Batch insert 10 NPCs into database

Uses the new batch_insert_npcs() function from repository.py
to efficiently populate the database with all NPC characters.
"""

import asyncio
import sys
from pathlib import Path

# Add app directory to path
sys.path.insert(0, str(Path(__file__).parent.parent / "app"))

from db.repository import db_repo


async def seed_npcs():
    """Insert all 10 NPCs into the database"""
    
    print("=" * 60)
    print("Seeding NPC Database")
    print("=" * 60)
    print()
    
    # Initialize database and apply migrations
    await db_repo.initialize()
    await db_repo.migrate_to_latest()
    
    # Define all 10 NPCs
    npcs = [
        {
            "id": "pierre",
            "name": "Pierre",
            "location": "general_store",
            "mood": "friendly",
            "energy": 100,
            "occupation": "shopkeeper",
            "personality": {
                "traits": ["friendly", "hardworking", "family_oriented"],
                "likes": ["farming", "family", "community"],
                "dislikes": ["waste", "laziness"]
            },
            "schedule": {
                "morning": {"location": "general_store", "activity": "open_shop"},
                "afternoon": {"location": "town_square", "activity": "chat"},
                "evening": {"location": "home", "activity": "rest"}
            }
        },
        {
            "id": "abigail",
            "name": "Abigail",
            "location": "cemetery",
            "mood": "adventurous",
            "energy": 100,
            "occupation": "adventurer",
            "personality": {
                "traits": ["adventurous", "rebellious", "curious", "brave"],
                "likes": ["adventure", "purple", "video_games"],
                "dislikes": ["boredom", "restrictions"]
            },
            "schedule": {
                "morning": {"location": "home", "activity": "practice_sword"},
                "afternoon": {"location": "cemetery", "activity": "explore"},
                "evening": {"location": "saloon", "activity": "socialize"}
            }
        },
        {
            "id": "lewis",
            "name": "Lewis",
            "location": "town_hall",
            "mood": "responsible",
            "energy": 100,
            "occupation": "mayor",
            "personality": {
                "traits": ["responsible", "diplomatic", "secretive", "caring"],
                "likes": ["order", "community_events", "authority"],
                "dislikes": ["chaos", "scandal"]
            },
            "schedule": {
                "morning": {"location": "town_hall", "activity": "work"},
                "afternoon": {"location": "town_square", "activity": "inspect"},
                "evening": {"location": "saloon", "activity": "relax"}
            }
        },
        {
            "id": "robin",
            "name": "Robin",
            "location": "carpenter_shop",
            "mood": "creative",
            "energy": 100,
            "occupation": "carpenter",
            "personality": {
                "traits": ["creative", "practical", "outgoing", "helpful"],
                "likes": ["building", "nature", "design"],
                "dislikes": ["waste", "ugly_architecture"]
            },
            "schedule": {
                "morning": {"location": "carpenter_shop", "activity": "work"},
                "afternoon": {"location": "mountain", "activity": "gather_wood"},
                "evening": {"location": "home", "activity": "family_time"}
            }
        },
        {
            "id": "penny",
            "name": "Penny",
            "location": "trailer",
            "mood": "gentle",
            "energy": 100,
            "occupation": "teacher",
            "personality": {
                "traits": ["gentle", "intelligent", "shy", "nurturing"],
                "likes": ["reading", "teaching", "children"],
                "dislikes": ["noise", "conflict"]
            },
            "schedule": {
                "morning": {"location": "trailer", "activity": "read"},
                "afternoon": {"location": "museum", "activity": "teach"},
                "evening": {"location": "river", "activity": "relax"}
            }
        },
        {
            "id": "sebastian",
            "name": "Sebastian",
            "location": "basement",
            "mood": "introverted",
            "energy": 100,
            "occupation": "programmer",
            "personality": {
                "traits": ["introverted", "analytical", "creative", "melancholic"],
                "likes": ["programming", "motorcycle", "fantasy"],
                "dislikes": ["small_talk", "crowds"]
            },
            "schedule": {
                "morning": {"location": "basement", "activity": "sleep"},
                "afternoon": {"location": "lake", "activity": "smoke"},
                "evening": {"location": "basement", "activity": "code"}
            }
        },
        {
            "id": "haley",
            "name": "Haley",
            "location": "home",
            "mood": "vain",
            "energy": 100,
            "occupation": "photographer",
            "personality": {
                "traits": ["vain", "artistic", "kind_hearted", "fashionable"],
                "likes": ["photography", "fashion", "beauty", "sunflowers"],
                "dislikes": ["dirt", "manual_labor"]
            },
            "schedule": {
                "morning": {"location": "home", "activity": "makeup"},
                "afternoon": {"location": "beach", "activity": "tan"},
                "evening": {"location": "home", "activity": "photos"}
            }
        },
        {
            "id": "alex",
            "name": "Alex",
            "location": "home",
            "mood": "confident",
            "energy": 100,
            "occupation": "athlete",
            "personality": {
                "traits": ["athletic", "confident", "loyal", "competitive"],
                "likes": ["sports", "football", "fitness"],
                "dislikes": ["losing", "weakness"]
            },
            "schedule": {
                "morning": {"location": "beach", "activity": "exercise"},
                "afternoon": {"location": "gym", "activity": "workout"},
                "evening": {"location": "home", "activity": "tv"}
            }
        },
        {
            "id": "maru",
            "name": "Maru",
            "location": "hospital",
            "mood": "curious",
            "energy": 100,
            "occupation": "scientist",
            "personality": {
                "traits": ["intelligent", "curious", "friendly", "inventive"],
                "likes": ["science", "technology", "astronomy"],
                "dislikes": ["ignorance", "superstition"]
            },
            "schedule": {
                "morning": {"location": "hospital", "activity": "work"},
                "afternoon": {"location": "garage", "activity": "tinker"},
                "evening": {"location": "mountain", "activity": "stargaze"}
            }
        },
        {
            "id": "sam",
            "name": "Sam",
            "location": "home",
            "mood": "energetic",
            "energy": 100,
            "occupation": "musician",
            "personality": {
                "traits": ["energetic", "optimistic", "loyal", "musical"],
                "likes": ["music", "skateboarding", "friends"],
                "dislikes": ["boredom", "seriousness"]
            },
            "schedule": {
                "morning": {"location": "home", "activity": "skateboard"},
                "afternoon": {"location": "town_square", "activity": "play_guitar"},
                "evening": {"location": "saloon", "activity": "jam_session"}
            }
        }
    ]
    
    print(f"Preparing to insert {len(npcs)} NPCs...")
    print()
    
    # Batch insert all NPCs
    inserted_count = await db_repo.batch_insert_npcs(npcs)
    
    print()
    print("=" * 60)
    if inserted_count == len(npcs):
        print(f"[SUCCESS] All {inserted_count} NPCs inserted successfully!")
    else:
        print(f"[WARNING] Only {inserted_count}/{len(npcs)} NPCs inserted")
    print("=" * 60)
    print()
    
    # Verify insertion
    all_npcs = await db_repo.get_all_npcs()
    print(f"Database now contains {len(all_npcs)} NPCs:")
    print()
    
    for npc in all_npcs:
        print(f"  - {npc['name']:15s} ({npc['id']:12s}) @ {npc['location']:20s} | {npc.get('occupation', 'N/A'):15s}")
    
    print()
    print("NPC seeding complete!")
    print()
    
    return inserted_count


if __name__ == "__main__":
    try:
        result = asyncio.run(seed_npcs())
        sys.exit(0 if result == 10 else 1)
    except Exception as e:
        print(f"\n[ERROR] Seeding failed: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
