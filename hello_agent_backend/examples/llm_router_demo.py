"""
LLM Router 使用示例和演示

展示如何使用多 LLM 提供商系统进行各种任务。
"""

import asyncio
import sys
from pathlib import Path

# 添加项目根目录到路径
sys.path.insert(0, str(Path(__file__).parent.parent))

from llm.providers.base import LLMMessage
from llm.router import LLMRouter


async def example_1_basic_usage():
    """示例 1: 基础使用 - NPC 对话"""
    print("\n" + "="*60)
    print("示例 1: 基础 NPC 对话（自动路由到 Ollama）")
    print("="*60)

    router = LLMRouter("config/llm_config.json")

    # 检查提供商状态
    print("\n检查可用提供商...")
    availability = await router.check_all_providers()
    for name, available in availability.items():
        status = "✓ 可用" if available else "✗ 不可用"
        print(f"  {name}: {status}")

    # NPC 对话
    messages = [
        LLMMessage(role="system", content="你是星露谷物语中的村民 Pierre，杂货店老板。你很友好但有点忙碌。"),
        LLMMessage(role="user", content="你好！我想买一些种子。")
    ]

    try:
        response = await router.chat_completion(
            messages=messages,
            task_type="npc_dialogue",
            temperature=0.7
        )

        print(f"\n💬 Pierre: {response.content}")
        print(f"\n--- 响应信息 ---")
        print(f"提供商: {response.provider}")
        print(f"模型: {response.model}")
        print(f"Token 使用: {response.usage}")
        print(f"成本: ${response.cost:.4f}")
        print(f"延迟: {response.latency_ms:.0f}ms")

    except Exception as e:
        print(f"\n❌ 请求失败: {e}")


async def example_2_provider_switching():
    """示例 2: 切换提供商"""
    print("\n" + "="*60)
    print("示例 2: 手动切换提供商")
    print("="*60)

    router = LLMRouter("config/llm_config.json")

    messages = [
        LLMMessage(role="user", content="用一句话描述春天的农场")
    ]

    # 尝试不同的提供商
    providers_to_try = ["ollama", "qwen", "gemini"]

    for provider_name in providers_to_try:
        print(f"\n--- 使用 {provider_name.upper()} ---")

        try:
            response = await router.chat_completion(
                messages=messages,
                task_type="creative_writing",
                force_provider=provider_name,  # 强制使用指定提供商
                temperature=0.8
            )

            print(f"回答: {response.content[:100]}...")
            print(f"成本: ${response.cost:.4f}, 延迟: {response.latency_ms:.0f}ms")

        except Exception as e:
            print(f"失败: {e}")


async def example_3_story_generation():
    """示例 3: 故事生成（使用云端模型）"""
    print("\n" + "="*60)
    print("示例 3: AI 故事生成")
    print("="*60)

    router = LLMRouter("config/llm_config.json")

    messages = [
        LLMMessage(role="system", content="你是一个富有想象力的故事讲述者。"),
        LLMMessage(role="user", content="""
        请为星露谷物语创建一个简短的背景故事：
        - 主角是一个厌倦了城市生活的年轻人
        - 继承了爷爷的旧农场
        - 在鹈鹕镇开始了新生活
        - 包含一些神秘元素

        字数：200-300字
        """)
    ]

    try:
        response = await router.chat_completion(
            messages=messages,
            task_type="story_generation",  # 自动选择 Qwen
            temperature=0.9,
            max_tokens=500
        )

        print(f"\n📖 生成的故事:\n{response.content}")
        print(f"\n--- 统计信息 ---")
        print(f"提供商: {response.provider}")
        print(f"Token: {response.usage.get('total_tokens', 0)}")
        print(f"成本: ${response.cost:.4f}")

    except Exception as e:
        print(f"\n❌ 故事生成失败: {e}")


async def example_4_embedding():
    """示例 4: 文本嵌入（用于向量搜索）"""
    print("\n" + "="*60)
    print("示例 4: 文本嵌入生成")
    print("="*60)

    router = LLMRouter("config/llm_config.json")

    texts = [
        "春天是播种的季节",
        "夏天作物生长迅速",
        "秋天是收获的时刻",
        "冬天适合休息和规划"
    ]

    try:
        print("\n生成文本嵌入...")
        response = await router.get_embedding(texts=texts)

        print(f"\n✓ 成功生成 {len(response.embeddings)} 个嵌入向量")
        print(f"提供商: {response.provider}")
        print(f"模型: {response.model}")
        print(f"第一个向量维度: {len(response.embeddings[0])}")
        print(f"Token 使用: {response.usage}")

        # 计算相似度示例（余弦相似度）
        import math

        def cosine_similarity(v1, v2):
            dot_product = sum(a * b for a, b in zip(v1, v2))
            norm1 = math.sqrt(sum(a * a for a in v1))
            norm2 = math.sqrt(sum(a * a for a in v2))
            return dot_product / (norm1 * norm2) if norm1 and norm2 else 0

        sim = cosine_similarity(response.embeddings[0], response.embeddings[1])
        print(f"\n'春天' 和 '夏天' 的相似度: {sim:.3f}")

    except Exception as e:
        print(f"\n❌ 嵌入生成失败: {e}")


async def example_5_monitoring():
    """示例 5: 监控和统计"""
    print("\n" + "="*60)
    print("示例 5: 性能监控和统计")
    print("="*60)

    router = LLMRouter("config/llm_config.json")

    # 执行几个请求
    test_messages = [
        LLMMessage(role="user", content="你好")
    ]

    print("\n执行测试请求...")

    for i in range(3):
        try:
            response = await router.chat_completion(
                messages=test_messages,
                task_type="npc_dialogue"
            )
            print(f"  请求 {i+1}: ✓ {response.provider} ({response.latency_ms:.0f}ms)")
        except Exception as e:
            print(f"  请求 {i+1}: ✗ {e}")

    # 显示统计信息
    print("\n--- 提供商统计 ---")
    stats = router.get_provider_stats()
    for provider, data in stats.items():
        print(f"\n{provider.upper()}:")
        for key, value in data.items():
            print(f"  {key}: {value}")

    # 显示预算信息
    print("\n--- 预算使用情况 ---")
    budget = router.get_budget_info()
    for key, value in budget.items():
        print(f"  {key}: {value}")


async def example_6_error_handling():
    """示例 6: 错误处理和降级"""
    print("\n" + "="*60)
    print("示例 6: 错误处理和自动降级")
    print("="*60)

    router = LLMRouter("config/llm_config.json")

    messages = [
        LLMMessage(role="user", content="测试消息")
    ]

    print("\n尝试请求（如果主提供商失败，会自动降级）...")

    try:
        response = await router.chat_completion(
            messages=messages,
            task_type="general"
        )
        print(f"\n✓ 成功！使用提供商: {response.provider}")
        print(f"内容: {response.content}")

    except Exception as e:
        print(f"\n❌ 所有提供商都失败了: {e}")
        print("\n建议:")
        print("  1. 检查 Ollama 是否运行: ollama serve")
        print("  2. 检查 API Key 是否正确设置")
        print("  3. 检查网络连接")


async def main():
    """运行所有示例"""
    print("\n" + "="*60)
    print("  LLM Router 使用示例")
    print("  多提供商智能路由系统演示")
    print("="*60)

    examples = [
        ("基础 NPC 对话", example_1_basic_usage),
        ("切换提供商", example_2_provider_switching),
        ("故事生成", example_3_story_generation),
        ("文本嵌入", example_4_embedding),
        ("监控统计", example_5_monitoring),
        ("错误处理", example_6_error_handling),
    ]

    for name, func in examples:
        try:
            await func()
        except KeyboardInterrupt:
            print("\n\n用户中断")
            break
        except Exception as e:
            print(f"\n示例 '{name}' 出错: {e}")

    print("\n" + "="*60)
    print("  演示结束")
    print("="*60 + "\n")


if __name__ == "__main__":
    # 运行示例
    asyncio.run(main())
