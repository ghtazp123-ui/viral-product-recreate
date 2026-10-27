---
name: viral-product-recreate
version: "1.2.0"
description: >-
  Faithful product-swap recreation of ANY viral/selling reference video with ANY
  product category. Keep the reference video's scene, camera, and pacing, but
  replace the hero product with the user's own product image every frame. Use when
  the user wants to "recreate this viral video with my product", "换品复刻",
  "1:1 换品", "把这个视频换成我的[任意品类]商品", or adapt any TikTok/short/ad
  template to a specific SKU while preserving the original's look and motion.
  Category-agnostic: works for lamps, beauty/cosmetics, supplements, apparel,
  home decor, 3C/digital, food, and more. Differs from creatok-recreate-video
  (structure/expression rewrites, forbids 1:1): this is the high-fidelity
  product-swap flavor.
license: Internal
compatibility: "Claude Code >=1.0, OpenClaw skills, ClawHub-compatible installers. Requires the `creatok` CLI on PATH, network access to the CreatOK API, and `ffmpeg` on PATH for preprocessing/QC. No Node.js runtime required."
metadata:
  openclaw:
    requires:
      env:
        - CREATOK_API_KEY
      bins:
        - creatok
        - ffmpeg
    primaryEnv: CREATOK_API_KEY
    previewEnv: CREATOK_API_KEY_PREVIEW
  author: workbuddy-user
  version: "1.2.0"
  geo-relevance: "low"
  tags:
    - tiktok
    - recreate-video
    - product-swap
    - 换品复刻
    - faithful-recreation
    - viral-template
    - any-category
    - seller-workflow
    - creatok
  triggers:
    - "recreate this viral video with my product"
    - "换品复刻这个爆款"
    - "把我家产品换进去复刻这个视频"
    - "1:1 换品"
    - "把这个视频换成我的商品"
    - "adapt this template to my SKU"
    - "复刻这个视频保留运镜"
    - "use this as a template but with my product"
    - "any category product swap"
---

# viral-product-recreate

High-fidelity "swap the hero product, keep everything else" recreation of a viral
or selling reference video — **for any product category and any reference video**.
The scene, camera moves, pacing, and on-screen story stay identical to the
reference; only the product is replaced, and it must stay visually consistent in
every frame.

This is the method proven on the Perfect Lux candle-warmer 爆款 series and
generalized to all categories. The canonical prompt template (the "v5" template)
finally locked product identity; this skill makes it reusable for lamps, beauty,
supplements, apparel, decor, 3C, food, etc.

## When to use

- User supplies a reference video (TikTok/short/local MP4, any niche) + their own
  product image(s).
- They want their product **in** that video, not a rewritten remix.
- The product is the visual hero (device, bottle, jar, gadget, garment, decor,
  food pack, toy…).

Do NOT use this for pure structure rewrites — route those to `creatok-recreate-video`.

## Prerequisites

- `creatok` CLI installed and `CREATOK_API_KEY` set. Verify: `creatok account show`.
- `ffmpeg` on PATH for compression + QC frame extraction.
- Inputs:
  - **Reference video** (local MP4 — any niche). For `doubao-seedance-2-mini` the
    video must stay under the pixel budget (Step 2). If given a URL, download it
    locally first (e.g. `yt-dlp` / platform download / any fetch), then proceed.
  - **Reference image 1**: the full product (white-bg shot is fine, or a scene
    shot). This is what gets swapped in.
  - **Reference image 2 (recommended)**: a high-res close-up of the product's most
    distinctive feature (logo, cap, texture, silhouette) so detail survives.
  - Optional **reference image 3**: a second feature close-up.

## Team setup (per-account — recommended)

Each colleague uses **their own CreatOK account/key** (credits are billed per
account; a shared key also risks 429 rate limits under concurrency). The skill
ships with a one-click installer so a teammate can self-onboard:

1. Hand the colleague the `viral-product-recreate` folder (copy it, or clone the
   repo that contains it).
2. They run the installer **from inside that folder**:
   - **Windows**: right-click `install.ps1` → "Run with PowerShell".
   - **macOS / Linux**: `chmod +x install.sh && ./install.sh`.
3. The installer auto-does:
   - installs the `creatok` CLI via `npm -g @creatok/cli` (needs Node.js LTS),
   - installs `ffmpeg` (winget / brew / apt),
   - copies this skill into `~/.workbuddy/skills/viral-product-recreate`
     (Windows: `%USERPROFILE%\.workbuddy\skills\`),
   - prompts for **their own** `CREATOK_API_KEY` and persists it as a **user-level
     environment variable** (never written into the skill or the repo),
   - runs `creatok account show` to verify.
4. They open WorkBuddy and say e.g. "换品复刻这个爆款 + 产品图" to trigger the skill.

> Install needs Node.js (for `npm`); once installed, running the skill does **not**
> require Node — `creatok` is a standalone binary.
> The API key is **never** embedded in the skill. Each person sets their own.

## Workflow

### Step 1 — Verify tooling & credits
```bash
creatok account show        # confirm API key + credits
creatok capabilities        # list models (doubao-seedance-2-mini etc.)
```

### Step 2 — Preprocess the reference video (required for mini)
Mini caps reference video resolution. Compress to **720×1280** (9:16, ~921k px,
under the mini limit) at 30fps:
```bash
ffmpeg -y -i "<ref_video>.mp4" -vf "scale=720:1280" -r 30 -c:v libx264 -crf 18 -preset medium "<ref>_720.mp4"
```
If the source is not exactly 9:16, pad instead:
`scale=720:1280:force_original_aspect_ratio=decrease,pad=720:1280:(ow-iw)/2:(oh-ih)/2`.
Other aspect ratios (1:1, 4:5, 16:9) are supported by `orientation` in Step 5 —
compress to the matching height budget instead.

### Step 3 — (Recommended) Build a scene-anchored image
If the product image is white-background, the static image alone often loses to
the reference video's geometry during V2V. Upgrade it into a **scene anchor** with
nano-banana: take one frame from the reference video that shows the desired
composition/lighting, and redraw it with the product swapped in.
```bash
creatok image generate \
  --prompt "Using reference image 1 as the EXACT scene composition, camera angle and lighting, redraw this image but REPLACE the [object in the scene] entirely with the [your product] shown in reference image 2 (detail in reference image 3). [Product constraints: <copy your product feature block from Step 4>]. Photorealistic, soft natural light, shallow depth of field, no AI artifacts. [Conditional safety constraint — only if relevant, e.g. no open flame / no spill / no melting]." \
  --ref "<ref_video_frame>.png,<product_full>.png,<product_detail>.jpg" \
  --options '{"model":"nano-banana-2","resolution":"1K","n":1,"aspect_ratio":"9:16"}' \
  --out "<run_dir>"
```
Download the result JPG from `result.images[0].url` with curl (the CLI saves only
`result.json` locally). **Use this anchor as reference image 1** in Step 5.

### Step 4 — Write the prompt (generic v5 template)
Fill every `{{...}}` placeholder. Keep the structure: swap-whole-object (including
its most distinctive shape) → keep scene/camera/pace → per-frame strict consistency
→ explicit "never revert to the wrong form" → lighting/texture → conditional safety
→ storyboard → subtitle (optional) → realism. See "Category guide" below for how to
fill the feature block per product type.

```
把参考视频中的{{产品类别/主体}}完整替换为参考图1中的{{产品}}，包括{{最显眼的外观特征，如顶部造型/整体轮廓/包装外形}}，场景、镜头结构、节奏保留。
{{产品}}特征全片每一帧严格一致（细节以参考图2高清特写为准）：{{逐条列举关键外观特征：材质、颜色、形状、纹理、结构、品牌元素、尺寸比例}}。
特别注意：结尾推近特写时{{产品}}同样保持{{正确形状+关键细节}}，绝不退回{{错误形态，如错误轮廓/错误配色/错误材质/原视频里的旧产品}}。
{{光线/质感要求，如：保持原视频的暖光质感，光从产品内部或表面透出}}。
{{条件式安全约束（仅当相关才加）：如蜡/香薰/火相关→全程未被点燃，没有明火火苗燃烧，只有被热量作用后的状态；液体→无泼洒；易碎→完整无裂}}。
分镜：{{0-2秒…; 2-4秒…; …按原视频节奏拆解}}。
{{画面叠加白色无衬线小字 "your text" spelled exactly。}}
{{真实感/画质要求，如：手机实拍质感、真实光衰减、自然噪点、轻微手持呼吸感}}。
negatives: {{错误特征, wrong product, 错误配色, 错误材质, AI感, CG渲染, oversaturated, camera shake, text misspelled}}
```

> **Tuning note (proven):** In later runs, dropping the `negatives` line and
> stating everything only *positively* also worked and sometimes improved shape
> lock (the diffusion "negation = activation" effect can re-inject the wrong
> shape when you name it in negatives). Keep the v5 negatives by default; if the
> product shape still drifts back to the reference video's original, switch to the
> pure-positive variant: never name the wrong form, only describe the right one at
> every storyboard beat.

### Step 5 — Generate (V2V)
```bash
creatok video generate \
  --prompt "<filled prompt from Step 4>" \
  --ref-video "<ref>_720.mp4" \
  --ref "<anchor_or_product_full>.jpg,<product_detail>.jpg" \
  --options '{"model":"doubao-seedance-2-mini","orientation":"9:16","seconds":14,"definition":"480p"}' \
  --out "<run_dir>"
```
- `seconds` ≤ reference video length. 12–14s is the sweet spot for mini.
- `orientation` must match the reference (9:16 / 1:1 / 4:5 / 16:9).
- Multiple `--ref` images are allowed (comma-separated); put the anchor/full
  product first. The reference video carries motion/composition; reference images
  carry identity.

### Step 6 — QC (mandatory)
Download the mp4 from `result.data.result.video_url`, then extract 1 fps frames:
```bash
curl -s -o out.mp4 "<video_url>"
mkdir -p frames && ffmpeg -y -loglevel error -i out.mp4 -vf fps=1 frames/f%02d.jpg
```
Eyeball every frame for three failure modes (see Pitfalls):
1. **Product identity** — is it YOUR product, not the reference video's?
2. **Safety constraint** — e.g. no flame for wax/candle; no spill for liquids.
3. **Mid-video drift** — does the shape/identity revert at a camera cut?

## Category guide (how to fill the feature block)

Replace `{{产品特征}}` with the traits that make the product recognizable. Examples:

- **小家电 / 灯 / 香薰机**：材质（金属/塑料/玻璃）、轮廓、控制件、光源位置、按钮/旋钮、品牌刻印。e.g. 金色细弯管灯臂；琥珀色宽钟形玻璃罩，罩身叶脉压花，下缘扇贝花边，上半段竖向棱纹收口到金色顶盖；浅原木椭圆底座带装饰圈。
- **美妆 / 洗护（瓶/罐/管）**：瓶形、盖型、标签/印花、液体颜色与质地（哑光/珠光/透明）、泵头/滴管。e.g. 磨砂玻璃方瓶，白色极简标签居中印 logo，琥珀色精华液，金色按压泵。
- **补剂 / 软糖 / 粉剂**：包装外形、颜色、质地、颗粒感。e.g. 透明罐装粉色软糖，罐身白色拱形标签，软糖呈小熊状浅粉。
- **服饰 / 配饰**：面料、颜色、版型、logo 位置、五金。e.g. oversize 米白针织衫，左胸小字母刺绣，罗纹下摆。
- **家居 / 装饰**：材质、形状、表面处理、纹样。e.g. 陶瓷哑光 vase，奶油色，手作不规则口沿。
- **3C / 数码**：机身材质、屏幕、接口、品牌标识、指示灯。e.g. 深空灰铝合金机身，正面居中挖孔屏，侧边单按键，背部激光 logo。
- **食品 / 饮品**：包装、颜色、质地、配料可见度。e.g. 牛皮纸袋装曲奇，透窗可见深棕曲奇，烫金品牌字。

The more **concrete and visual** the feature list (shape → color → texture →
structure → brand mark), the tighter the identity lock.

## Conditional safety constraints

Add ONLY the ones relevant to the product. Do not hardcode fire rules for
non-combustible goods.

- **蜡 / 香薰 / 烛 /  incense**：全程未被点燃——没有明火、火苗、燃烧灯芯，只有被热量烤融的湿润光泽与蜡池。（用正向描述，而非只写 negative。）
- **液体 / 饮品**：无泼洒、无溢出、液面平稳。
- **易碎 / 玻璃**：完整无裂、无碎渣。
- **食品**：新鲜完好、无变质、无异物。
- **婴儿 / 贴身**：材质安全观感、无锐利边。

## Pitfalls & tuning (hard-won, category-independent)

- **Reference video geometry is sticky.** In V2V the video's subject geometry
  (silhouette, bottle shape, garment cut) dominates static images. Static refs
  change *material/color/accessories*; they barely move *outline*. To change
  outline: use the **scene-anchor image** (Step 3) as ref 1, and repeat the shape
  description at every storyboard beat.
- **Negatives can backfire.** Naming the wrong shape in `negatives` sometimes
  *reinjects* it. If identity drifts, switch to pure-positive (see Step 4 note).
- **Mid-video drift window.** Identity is usually solid for the first ~8s, then
  regresses at the first hard camera cut (the ref geometry reasserts). Mitigations:
  (a) re-roll — the drift window is somewhat random; (b) **segment** the reference
  video at the cut, generate 0–7s and 7–14s as two tasks, concatenate with ffmpeg.
- **Subtitle text garbles.** Seedance text rendering is unreliable ("roorl",
  "Haticed"). Keep the `spelled exactly` note for layout reference, but plan to add
  final text in CapCut/剪映 in post. Don't burn deliverable copy into the generation.
- **Resolution budget.** Mini reference video must be ≤ ~927k px. Always compress
  (Step 2). 480p output is default; 720p/fast costs more credits.
- **Credits.** mini 480p ≈ 11–13 credits/run; fast 480p ≈ 25; image gen ≈ 1–2.
  Check `creatok account show` before a batch.

## Quick command reference
```bash
creatok account show                                   # credits + key check
creatok capabilities                                   # models & limits
creatok image generate --prompt "..." --ref a.png,b.jpg \
  --options '{"model":"nano-banana-2","resolution":"1K","n":1,"aspect_ratio":"9:16"}' --out dir
creatok video generate --prompt "..." --ref-video v.mp4 --ref a.png,b.jpg \
  --options '{"model":"doubao-seedance-2-mini","orientation":"9:16","seconds":14,"definition":"480p"}' --out dir
```

## Reference run (origin of the method)
The template was proven on a candle-warmer lamp (reference video `bd0f05da…mp4`):
full lamp swap including shade top shape, per-frame strict consistency, close-up
"never revert to conical shade", unlit-candle constraint, storyboard, subtitle
`spelled exactly`, `negatives` list; model `doubao-seedance-2-fast` 480p 12s, later
`doubao-seedance-2-mini`. Evolution: `run_anchor/anchor.jpg` (nano-banana scene
anchor) → `out_v14`/`out_v15` mini runs (anchor + pure-positive prompt locked
bell-shade identity for the first ~8s). The technique is category-independent;
only the feature block and safety constraint change per product.
