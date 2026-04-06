"""
Inventory Management System - Complete item and inventory logic

Provides:
- Item definitions and metadata
- Inventory CRUD operations
- Item stacking and splitting
- Equipment system
- Item usage effects
- Shop buying/selling
"""

import logging
from typing import Optional, List, Dict, Any
from datetime import datetime

from ..db.repository import db_repo

logger = logging.getLogger(__name__)


class ItemManager:
    """
    Manages all item-related operations
    
    Features:
    - Item database with full metadata
    - Inventory management (add, remove, stack)
    - Equipment system (tools, weapons)
    - Consumable effects (food, potions)
    - Shop transactions
    """
    
    def __init__(self):
        self.items_db = self._load_items_database()
    
    def _load_items_database(self) -> Dict[str, Dict[str, Any]]:
        """Load item definitions from config"""
        return {
            # Crops
            "parsnip": {
                "id": "parsnip",
                "name": "防风草",
                "type": "crop",
                "category": "food",
                "stack_size": 999,
                "sell_price": 35,
                "buy_price": 20,
                "energy": 13,
                "health": 5,
                "description": "一种常见的根茎蔬菜",
                "season": "spring",
                "grow_days": 4
            },
            "potato": {
                "id": "potato",
                "name": "土豆",
                "type": "crop",
                "category": "food",
                "stack_size": 999,
                "sell_price": 80,
                "buy_price": 50,
                "energy": 26,
                "health": 10,
                "description": "营养丰富的块茎作物",
                "season": "spring",
                "grow_days": 6
            },
            "carrot": {
                "id": "carrot",
                "name": "胡萝卜",
                "type": "crop",
                "category": "food",
                "stack_size": 999,
                "sell_price": 35,
                "buy_price": 15,
                "energy": 15,
                "health": 8,
                "description": "橙色的脆甜蔬菜",
                "season": "fall",
                "grow_days": 3
            },
            "tomato": {
                "id": "tomato",
                "name": "番茄",
                "type": "crop",
                "category": "food",
                "stack_size": 999,
                "sell_price": 60,
                "buy_price": 40,
                "energy": 18,
                "health": 7,
                "description": "多汁的红色果实",
                "season": "summer",
                "grow_days": 11,
                "regrows": True
            },
            "corn": {
                "id": "corn",
                "name": "玉米",
                "type": "crop",
                "category": "food",
                "stack_size": 999,
                "sell_price": 50,
                "buy_price": 30,
                "energy": 20,
                "health": 9,
                "description": "金黄色的谷物",
                "season": "summer,fall",
                "grow_days": 14,
                "regrows": True
            },
            "pumpkin": {
                "id": "pumpkin",
                "name": "南瓜",
                "type": "crop",
                "category": "food",
                "stack_size": 999,
                "sell_price": 320,
                "buy_price": 200,
                "energy": 36,
                "health": 15,
                "description": "巨大的橙色南瓜",
                "season": "fall",
                "grow_days": 13
            },
            
            # Tools
            "hoe": {
                "id": "hoe",
                "name": "锄头",
                "type": "tool",
                "category": "farming",
                "stack_size": 1,
                "sell_price": 50,
                "buy_price": 100,
                "durability": 100,
                "energy_cost": 5,
                "description": "用于耕地的农具"
            },
            "watering_can": {
                "id": "watering_can",
                "name": "洒水壶",
                "type": "tool",
                "category": "farming",
                "stack_size": 1,
                "sell_price": 75,
                "buy_price": 150,
                "capacity": 40,
                "energy_cost": 2,
                "description": "为作物浇水"
            },
            "scythe": {
                "id": "scythe",
                "name": "镰刀",
                "type": "tool",
                "category": "farming",
                "stack_size": 1,
                "sell_price": 60,
                "buy_price": 120,
                "durability": 150,
                "energy_cost": 3,
                "description": "收割作物和杂草"
            },
            "axe": {
                "id": "axe",
                "name": "斧头",
                "type": "tool",
                "category": "resource",
                "stack_size": 1,
                "sell_price": 80,
                "buy_price": 160,
                "durability": 100,
                "energy_cost": 7,
                "description": "砍伐树木"
            },
            
            # Resources
            "wood": {
                "id": "wood",
                "name": "木材",
                "type": "resource",
                "category": "material",
                "stack_size": 999,
                "sell_price": 2,
                "buy_price": 5,
                "description": "基础建筑材料"
            },
            "stone": {
                "id": "stone",
                "name": "石头",
                "type": "resource",
                "category": "material",
                "stack_size": 999,
                "sell_price": 3,
                "buy_price": 8,
                "description": "坚硬的建筑材料"
            },
            "iron_ore": {
                "id": "iron_ore",
                "name": "铁矿石",
                "type": "resource",
                "category": "material",
                "stack_size": 999,
                "sell_price": 15,
                "buy_price": 30,
                "description": "可冶炼成铁锭"
            },
            "gold_ore": {
                "id": "gold_ore",
                "name": "金矿石",
                "type": "resource",
                "category": "material",
                "stack_size": 999,
                "sell_price": 25,
                "buy_price": 50,
                "description": "珍贵的金属矿石"
            },
            
            # Consumables
            "health_potion": {
                "id": "health_potion",
                "name": "生命药水",
                "type": "consumable",
                "category": "potion",
                "stack_size": 50,
                "sell_price": 50,
                "buy_price": 100,
                "effect": {"health": 50},
                "description": "恢复50点生命值"
            },
            "energy_drink": {
                "id": "energy_drink",
                "name": "能量饮料",
                "type": "consumable",
                "category": "drink",
                "stack_size": 50,
                "sell_price": 40,
                "buy_price": 80,
                "effect": {"energy": 30},
                "description": "恢复30点能量"
            },
            "bread": {
                "id": "bread",
                "name": "面包",
                "type": "food",
                "category": "cooked",
                "stack_size": 50,
                "sell_price": 60,
                "buy_price": 120,
                "effect": {"energy": 25, "health": 10},
                "description": "新鲜出炉的面包"
            },
            "salad": {
                "id": "salad",
                "name": "沙拉",
                "type": "food",
                "category": "cooked",
                "stack_size": 50,
                "sell_price": 110,
                "buy_price": 220,
                "effect": {"energy": 35, "health": 20},
                "description": "健康的蔬菜沙拉"
            }
        }
    
    def get_item(self, item_id: str) -> Optional[Dict[str, Any]]:
        """Get item definition by ID"""
        return self.items_db.get(item_id)
    
    def get_all_items(self) -> List[Dict[str, Any]]:
        """Get all item definitions"""
        return list(self.items_db.values())
    
    def get_items_by_type(self, item_type: str) -> List[Dict[str, Any]]:
        """Filter items by type"""
        return [item for item in self.items_db.values() if item['type'] == item_type]
    
    def get_items_by_category(self, category: str) -> List[Dict[str, Any]]:
        """Filter items by category"""
        return [item for item in self.items_db.values() if item.get('category') == category]
    
    async def add_to_inventory(self, player_id: str, item_id: str, quantity: int = 1) -> bool:
        """
        Add item to player's inventory with stacking
        
        Args:
            player_id: Player identifier
            item_id: Item definition ID
            quantity: Amount to add
            
        Returns:
            True if successful
        """
        item_def = self.get_item(item_id)
        if not item_def:
            logger.error(f"Item not found: {item_id}")
            return False
        
        if quantity <= 0:
            logger.warning(f"Invalid quantity: {quantity}")
            return False
        
        try:
            success = await db_repo.add_item(player_id, item_id, item_def['name'], quantity)
            
            if success:
                logger.info(f"Added {quantity}x {item_def['name']} to {player_id}'s inventory")
            else:
                logger.error(f"Failed to add item to inventory")
            
            return success
            
        except Exception as e:
            logger.error(f"Error adding to inventory: {e}")
            return False
    
    async def remove_from_inventory(self, player_id: str, item_id: str, quantity: int = 1) -> bool:
        """
        Remove item from player's inventory
        
        Args:
            player_id: Player identifier
            item_id: Item definition ID
            quantity: Amount to remove
            
        Returns:
            True if successful
        """
        try:
            success = await db_repo.remove_item(player_id, item_id, quantity)
            
            if success:
                item_def = self.get_item(item_id)
                item_name = item_def['name'] if item_def else item_id
                logger.info(f"Removed {quantity}x {item_name} from {player_id}'s inventory")
            else:
                logger.error(f"Failed to remove item from inventory")
            
            return success
            
        except Exception as e:
            logger.error(f"Error removing from inventory: {e}")
            return False
    
    async def get_player_inventory(self, player_id: str) -> List[Dict[str, Any]]:
        """
        Get player's complete inventory with item details
        
        Returns:
            List of inventory items with full metadata
        """
        try:
            raw_inventory = await db_repo.get_inventory(player_id)
            
            # Enrich with item definitions
            enriched_inventory = []
            for item in raw_inventory:
                item_def = self.get_item(item['item_id'])
                if item_def:
                    enriched_item = {**item, **item_def}
                    enriched_inventory.append(enriched_item)
                else:
                    enriched_inventory.append(item)
            
            return enriched_inventory
            
        except Exception as e:
            logger.error(f"Error getting inventory: {e}")
            return []
    
    async def use_item(self, player_id: str, item_id: str) -> Dict[str, Any]:
        """
        Use a consumable item or equipment
        
        Args:
            player_id: Player identifier
            item_id: Item to use
            
        Returns:
            Result dict with success status and effects
        """
        item_def = self.get_item(item_id)
        if not item_def:
            return {"success": False, "error": "Item not found"}
        
        # Check if player has the item
        inventory = await self.get_player_inventory(player_id)
        item_in_inventory = next((i for i in inventory if i['item_id'] == item_id), None)
        
        if not item_in_inventory:
            return {"success": False, "error": "Item not in inventory"}
        
        result = {"success": True, "item_id": item_id, "effects": {}}
        
        # Handle different item types
        if item_def['type'] in ['consumable', 'food']:
            # Apply effects
            if 'effect' in item_def:
                result['effects'] = item_def['effect']
                
                # Update player stats (would integrate with player system)
                if 'health' in item_def['effect']:
                    logger.info(f"{player_id} gained {item_def['effect']['health']} health")
                
                if 'energy' in item_def['effect']:
                    logger.info(f"{player_id} gained {item_def['effect']['energy']} energy")
            
            # Consume one item
            await self.remove_from_inventory(player_id, item_id, 1)
            result['consumed'] = True
            
        elif item_def['type'] == 'tool':
            # Equip tool (would integrate with equipment system)
            result['equipped'] = True
            result['energy_cost'] = item_def.get('energy_cost', 0)
            
        elif item_def['type'] == 'resource':
            # Resources can't be "used" directly
            result['success'] = False
            result['error'] = "Resources cannot be used directly"
        
        return result
    
    async def buy_item(self, player_id: str, item_id: str, quantity: int = 1, 
                      shopkeeper_id: str = "pierre") -> Dict[str, Any]:
        """
        Buy item from shop
        
        Args:
            player_id: Buyer
            item_id: Item to buy
            quantity: Amount
            shopkeeper_id: NPC selling the item
            
        Returns:
            Transaction result
        """
        item_def = self.get_item(item_id)
        if not item_def:
            return {"success": False, "error": "Item not found"}
        
        if 'buy_price' not in item_def:
            return {"success": False, "error": "Item not for sale"}
        
        total_cost = item_def['buy_price'] * quantity
        
        # Check player gold (would integrate with player system)
        player = await db_repo.get_player(player_id)
        if not player:
            return {"success": False, "error": "Player not found"}
        
        if player['gold'] < total_cost:
            return {
                "success": False, 
                "error": "Not enough gold",
                "required": total_cost,
                "have": player['gold']
            }
        
        # Process transaction
        try:
            async with db_repo.transaction() as db:
                # Deduct gold
                new_gold = player['gold'] - total_cost
                await db.execute(
                    "UPDATE players SET gold = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?",
                    (new_gold, player_id)
                )
                
                # Add item to inventory
                await db.execute(
                    """INSERT OR REPLACE INTO inventory (player_id, item_id, item_name, quantity)
                       VALUES (?, ?, ?, ?)""",
                    (player_id, item_id, item_def['name'], quantity)
                )
            
            logger.info(f"{player_id} bought {quantity}x {item_def['name']} for {total_cost}g from {shopkeeper_id}")
            
            return {
                "success": True,
                "item_id": item_id,
                "quantity": quantity,
                "total_cost": total_cost,
                "remaining_gold": new_gold
            }
            
        except Exception as e:
            logger.error(f"Buy transaction failed: {e}")
            return {"success": False, "error": f"Transaction failed: {str(e)}"}
    
    async def sell_item(self, player_id: str, item_id: str, quantity: int = 1,
                       shopkeeper_id: str = "pierre") -> Dict[str, Any]:
        """
        Sell item to shop
        
        Args:
            player_id: Seller
            item_id: Item to sell
            quantity: Amount
            shopkeeper_id: NPC buying the item
            
        Returns:
            Transaction result
        """
        item_def = self.get_item(item_id)
        if not item_def:
            return {"success": False, "error": "Item not found"}
        
        if 'sell_price' not in item_def:
            return {"success": False, "error": "Item cannot be sold"}
        
        # Check if player has enough items
        inventory = await self.get_player_inventory(player_id)
        item_in_inventory = next((i for i in inventory if i['item_id'] == item_id), None)
        
        if not item_in_inventory:
            return {"success": False, "error": "Item not in inventory"}
        
        if item_in_inventory['quantity'] < quantity:
            return {
                "success": False,
                "error": "Not enough items",
                "required": quantity,
                "have": item_in_inventory['quantity']
            }
        
        total_value = item_def['sell_price'] * quantity
        
        # Process transaction
        try:
            async with db_repo.transaction() as db:
                # Remove items
                new_quantity = item_in_inventory['quantity'] - quantity
                if new_quantity <= 0:
                    await db.execute(
                        "DELETE FROM inventory WHERE player_id = ? AND item_id = ?",
                        (player_id, item_id)
                    )
                else:
                    await db.execute(
                        "UPDATE inventory SET quantity = ? WHERE player_id = ? AND item_id = ?",
                        (new_quantity, player_id, item_id)
                    )
                
                # Add gold
                player = await db_repo.get_player(player_id)
                new_gold = player['gold'] + total_value
                await db.execute(
                    "UPDATE players SET gold = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?",
                    (new_gold, player_id)
                )
            
            logger.info(f"{player_id} sold {quantity}x {item_def['name']} for {total_value}g to {shopkeeper_id}")
            
            return {
                "success": True,
                "item_id": item_id,
                "quantity": quantity,
                "total_value": total_value,
                "new_gold": new_gold
            }
            
        except Exception as e:
            logger.error(f"Sell transaction failed: {e}")
            return {"success": False, "error": f"Transaction failed: {str(e)}"}
    
    async def get_inventory_value(self, player_id: str) -> int:
        """Calculate total value of player's inventory"""
        inventory = await self.get_player_inventory(player_id)
        total_value = 0
        
        for item in inventory:
            item_def = self.get_item(item['item_id'])
            if item_def and 'sell_price' in item_def:
                total_value += item_def['sell_price'] * item['quantity']
        
        return total_value


# Global item manager instance
item_manager = ItemManager()
