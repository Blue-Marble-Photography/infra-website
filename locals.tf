locals {
  # AI crawlers and AI search/assistant agents rejected at the edge (case-insensitive
  # substring match). Narrower than robots.txt: nothing that powers link previews
  # (facebookexternalhit) or ordinary search.
  ai_agents = [
    "GPTBot", "ChatGPT-User", "ChatGPT Agent", "OAI-SearchBot",
    "ClaudeBot", "Claude-User", "Claude-SearchBot", "Claude-Web", "anthropic-ai",
    "CCBot", "Bytespider", "PerplexityBot", "Perplexity-User",
    "meta-externalagent", "meta-externalfetcher", "FacebookBot", "Amazonbot",
    "cohere-ai", "cohere-training-data-crawler", "Diffbot", "ImagesiftBot", "img2dataset",
    "LAIONDownloader", "laion-huggingface-processor", "Timpibot", "omgili", "Webzio-Extended",
    "AI2Bot", "PanguBot", "DeepSeekBot", "MistralAI", "QwenBot", "TikTokSpider",
    "DuckAssistBot", "CloudVertexBot", "GrokBot", "Kangaroo Bot", "YouBot", "iaskspider",
    "Brightbot", "imageSpider", "FirecrawlAgent", "Crawl4AI", "ExaBot", "TavilyBot",
    "KimiBot", "DoubaoBot", "ERNIEBot", "YiyanBot", "Manus-User", "Gemini-Deep-Research",
    "GoogleAgent", "NovaAct", "bedrockbot", "AzureAI-SearchBot", "ChatGLM-Spider",
    "Andibot", "PhindBot", "LinerBot", "ShapBot",
  ]
  # Names are letters, digits, hyphens, and spaces only, so no regex escaping is needed.
  ai_agents_pattern = join("|", local.ai_agents)

  images_bucket = "bluemarble-images-${var.site_account_id}"
}
